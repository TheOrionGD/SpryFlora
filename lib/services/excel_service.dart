import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_species.dart';

/// Excel & Offline Species Loader Service
/// Loads plant species database from local asset, Excel, or custom user discoveries.
class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  static const String _customSpeciesKey = 'spryflora_discovered_species';

  List<PlantSpecies> _cachedSpecies = [];
  bool _isLoaded = false;

  List<PlantSpecies> get speciesList => List.unmodifiable(_cachedSpecies);
  bool get isLoaded => _isLoaded;

  /// Loads species from offline bundled JSON / Excel, and merges user discovered species
  Future<List<PlantSpecies>> loadSpeciesDatabase() async {
    if (_isLoaded && _cachedSpecies.isNotEmpty) {
      return _cachedSpecies;
    }

    List<PlantSpecies> baseSpecies = [];

    // 1. Load from offline bundled species_data.json
    try {
      final jsonStr =
          await rootBundle.loadString('assets/database/species_data.json');
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      baseSpecies = decoded
          .map((item) => PlantSpecies.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Continue to fallback
    }

    // 2. Try loading from Excel XLSX file if base was empty
    if (baseSpecies.isEmpty) {
      try {
        final ByteData data =
            await rootBundle.load('assets/database/plant_species.xlsx');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        final excel = Excel.decodeBytes(bytes);

        final List<PlantSpecies> parsedList = [];
        for (final table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet == null) continue;

          bool isFirstRow = true;
          for (final row in sheet.rows) {
            if (isFirstRow) {
              isFirstRow = false;
              final firstCellVal =
                  row.isNotEmpty ? row[0]?.value.toString() : '';
              if (firstCellVal?.toLowerCase().contains('name') ?? false) {
                continue;
              }
            }

            if (row.isEmpty) continue;

            final nameVal = row.isNotEmpty && row[0] != null
                ? row[0]!.value.toString().trim()
                : '';
            if (nameVal.isEmpty) continue;

            int lifespan = 150;
            if (row.length > 1 && row[1] != null) {
              final val =
                  row[1]!.value.toString().replaceAll(RegExp(r'[^0-9]'), '');
              lifespan = int.tryParse(val) ?? 150;
            }

            int interval = 3;
            if (row.length > 2 && row[2] != null) {
              final val =
                  row[2]!.value.toString().replaceAll(RegExp(r'[^0-9]'), '');
              interval = int.tryParse(val) ?? 3;
            }

            parsedList.add(PlantSpecies(
              name: nameVal,
              lifespanDays: lifespan > 0 ? lifespan : 150,
              wateringIntervalDays: interval > 0 ? interval : 3,
            ));
          }
        }
        if (parsedList.isNotEmpty) {
          baseSpecies = parsedList;
        }
      } catch (_) {}
    }

    // 3. Fallback standard list
    if (baseSpecies.isEmpty) {
      baseSpecies = const [
        PlantSpecies(
            name: 'Rose',
            lifespanDays: 150,
            wateringIntervalDays: 3,
            sunlight: 'Full Sun'),
        PlantSpecies(
            name: 'Money Plant',
            lifespanDays: 300,
            wateringIntervalDays: 3,
            sunlight: 'Indirect Light'),
        PlantSpecies(
            name: 'Tulsi',
            lifespanDays: 120,
            wateringIntervalDays: 2,
            sunlight: 'Direct Sun'),
        PlantSpecies(
            name: 'Aloe Vera',
            lifespanDays: 365,
            wateringIntervalDays: 7,
            sunlight: 'Bright Sunlight'),
        PlantSpecies(
            name: 'Snake Plant',
            lifespanDays: 400,
            wateringIntervalDays: 10,
            sunlight: 'Low to Bright'),
        PlantSpecies(
            name: 'Peace Lily',
            lifespanDays: 250,
            wateringIntervalDays: 4,
            sunlight: 'Medium Shade'),
        PlantSpecies(
            name: 'Spider Plant',
            lifespanDays: 200,
            wateringIntervalDays: 4,
            sunlight: 'Bright Indirect'),
        PlantSpecies(
            name: 'Jade Plant',
            lifespanDays: 350,
            wateringIntervalDays: 7,
            sunlight: 'Direct Sun'),
      ];
    }

    // 4. Merge discovered custom species from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJsonList = prefs.getStringList(_customSpeciesKey) ?? [];
      for (final jsonStr in customJsonList) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final customSpecies = PlantSpecies.fromJson(decoded);
        if (!baseSpecies.any(
            (s) => s.name.toLowerCase() == customSpecies.name.toLowerCase())) {
          baseSpecies.add(customSpecies);
        }
      }
    } catch (_) {}

    _cachedSpecies = baseSpecies;
    _isLoaded = true;
    return _cachedSpecies;
  }

  /// Adds a newly discovered species dynamically to the database catalogue & SharedPreferences
  Future<bool> addNewSpecies(PlantSpecies newSpecies) async {
    await loadSpeciesDatabase();
    final exists = getSpeciesByName(newSpecies.name);
    if (exists == null) {
      _cachedSpecies = [..._cachedSpecies, newSpecies];
      try {
        final prefs = await SharedPreferences.getInstance();
        final customJsonList = prefs.getStringList(_customSpeciesKey) ?? [];
        customJsonList.add(jsonEncode(newSpecies.toJson()));
        await prefs.setStringList(_customSpeciesKey, customJsonList);
      } catch (_) {}
      return true; // Successfully added as new discovery
    }
    return false; // Already existed
  }

  /// Find species by exact or case-insensitive name
  PlantSpecies? getSpeciesByName(String name) {
    try {
      return _cachedSpecies.firstWhere(
        (s) => s.name.toLowerCase().trim() == name.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }
}
