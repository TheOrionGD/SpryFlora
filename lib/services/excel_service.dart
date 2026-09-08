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
              commonName: nameVal,
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

    // 3. Throw exception or record error if base species database could not be loaded
    if (baseSpecies.isEmpty) {
      _isLoaded = false;
      _cachedSpecies = [];
      throw Exception('Species database unavailable. Unable to load plant species catalog.');
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

  /// Smart botanical cross-matching algorithm against local dataset
  PlantSpecies matchSpeciesFromAIPrediction(String rawAiLabel, {String? detectedObjectType}) {
    final query = ('$rawAiLabel ${detectedObjectType ?? ''}').toLowerCase().trim();

    // 1. Direct exact match check
    final exact = getSpeciesByName(rawAiLabel);
    if (exact != null) return exact;

    // 2. Tree & Forest keyword heuristic cross-checks
    if (query.contains('tree') ||
        query.contains('forest') ||
        query.contains('wood') ||
        query.contains('conifer') ||
        query.contains('evergreen') ||
        query.contains('branch') ||
        query.contains('canopy') ||
        query.contains('pine') ||
        query.contains('neem') ||
        query.contains('banyan') ||
        query.contains('ficus') ||
        query.contains('oak') ||
        query.contains('woodland')) {
      if (query.contains('banyan')) return getSpeciesByName('Banyan Tree') ?? _cachedSpecies.first;
      if (query.contains('pine')) return getSpeciesByName('Pine Tree') ?? _cachedSpecies.first;
      if (query.contains('ficus')) return getSpeciesByName('Ficus Tree') ?? _cachedSpecies.first;
      if (query.contains('mango')) return getSpeciesByName('Mango Tree') ?? _cachedSpecies.first;
      if (query.contains('gulmohar')) return getSpeciesByName('Gulmohar Tree') ?? _cachedSpecies.first;
      return getSpeciesByName('Neem Tree') ?? (_cachedSpecies.isNotEmpty ? _cachedSpecies.first : PlantSpecies(commonName: 'Neem Tree', lifespanDays: 3650, wateringIntervalDays: 4));
    }

    // 3. Specific species keyword matching
    if (query.contains('tulsi') || query.contains('basil') || query.contains('ocimum')) {
      return getSpeciesByName('Tulsi') ?? _cachedSpecies.first;
    }
    if (query.contains('money') || query.contains('pothos') || query.contains('epipremnum') || query.contains('vine')) {
      return getSpeciesByName('Money Plant') ?? _cachedSpecies.first;
    }
    if (query.contains('aloe') || query.contains('succulent')) {
      return getSpeciesByName('Aloe Vera') ?? _cachedSpecies.first;
    }
    if (query.contains('snake') || query.contains('sansevieria')) {
      return getSpeciesByName('Snake Plant') ?? _cachedSpecies.first;
    }
    if (query.contains('peace') || query.contains('lily') || query.contains('spathiphyllum')) {
      return getSpeciesByName('Peace Lily') ?? _cachedSpecies.first;
    }
    if (query.contains('spider') || query.contains('chlorophytum')) {
      return getSpeciesByName('Spider Plant') ?? _cachedSpecies.first;
    }
    if (query.contains('jade') || query.contains('crassula')) {
      return getSpeciesByName('Jade Plant') ?? _cachedSpecies.first;
    }
    if (query.contains('rose') || query.contains('rosa')) {
      return getSpeciesByName('Rose') ?? _cachedSpecies.first;
    }
    if (query.contains('zz') || query.contains('zamioculcas')) {
      return getSpeciesByName('ZZ Plant') ?? PlantSpecies(
        commonName: 'ZZ Plant',
        lifespanDays: 1000,
        wateringIntervalDays: 14,
        sunlight: 'Low to Bright Indirect',
        description: 'Hardy drought-tolerant foliage with shiny waxy leaflets and underground water-storing rhizomes.',
        idealTemp: '18°C - 26°C',
      );
    }
    if (query.contains('monstera') || query.contains('deliciosa') || query.contains('swiss cheese')) {
      return getSpeciesByName('Monstera') ?? PlantSpecies(
        commonName: 'Monstera Deliciosa',
        lifespanDays: 1000,
        wateringIntervalDays: 7,
        sunlight: 'Bright Indirect Light',
        description: 'Iconic split-leaf tropical climbing plant.',
        idealTemp: '18°C - 30°C',
      );
    }
    if (query.contains('hibiscus') || query.contains('shoe flower')) {
      return getSpeciesByName('Hibiscus') ?? _cachedSpecies.first;
    }
    if (query.contains('orchid')) {
      return getSpeciesByName('Orchid') ?? _cachedSpecies.first;
    }
    if (query.contains('fern')) {
      return getSpeciesByName('Fern') ?? _cachedSpecies.first;
    }
    if (query.contains('bamboo')) {
      return getSpeciesByName('Bamboo Palm') ?? _cachedSpecies.first;
    }

    // 4. Substring matching against cached species
    for (final s in _cachedSpecies) {
      if (query.contains(s.name.toLowerCase()) || s.name.toLowerCase().contains(query)) {
        return s;
      }
    }

    // 5. Clean AI labels — avoid generic placeholders like "Botanical Plant" or "Plant"
    final cleanLabel = rawAiLabel.trim();
    final lower = cleanLabel.toLowerCase();
    if (lower == 'botanical plant' ||
        lower == 'plant' ||
        lower == 'unknown' ||
        lower == 'green plant' ||
        lower == 'indoor plant' ||
        lower == 'unknown species' ||
        cleanLabel.isEmpty) {
      // Pick common favorite indoor species
      return getSpeciesByName('Money Plant') ??
          (getSpeciesByName('Tulsi') ??
              (_cachedSpecies.isNotEmpty
                  ? _cachedSpecies.first
                  : PlantSpecies(commonName: 'Money Plant', lifespanDays: 365, wateringIntervalDays: 4)));
    }

    return PlantSpecies(
      commonName: cleanLabel,
      lifespanDays: 365,
      wateringIntervalDays: 4,
      sunlight: 'Bright Indirect Light',
      description: 'Identified by SpryFlora Botanical AI Vision.',
      idealTemp: '18°C - 28°C',
    );
  }
}
