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

  /// Smart botanical cross-matching algorithm against local dataset or dynamic creation
  PlantSpecies matchSpeciesFromAIPrediction(
    String rawAiLabel, {
    String? detectedObjectType,
    String? botanicalName,
    int? wateringIntervalDays,
    int? lifespanDays,
    String? sunlightRequirements,
    int? targetSunlightHours,
    String? careInstructions,
    String? description,
    String? idealTemp,
  }) {
    final cleanLabel = rawAiLabel.trim();
    final lowerLabel = cleanLabel.toLowerCase();
    final query = ('$cleanLabel ${detectedObjectType ?? ''}').toLowerCase().trim();

    // 1. Direct exact or case-insensitive match check
    if (cleanLabel.isNotEmpty) {
      final exact = getSpeciesByName(cleanLabel);
      if (exact != null) return exact;
    }

    // 2. Specific species keyword matching in database
    if (query.contains('hibiscus') || query.contains('shoe flower')) {
      final match = getSpeciesByName('Hibiscus');
      if (match != null) return match;
    }
    if (query.contains('rose') || query.contains('rosa')) {
      final match = getSpeciesByName('Rose');
      if (match != null) return match;
    }
    if (query.contains('sunflower') || query.contains('helianthus')) {
      final match = getSpeciesByName('Sunflower');
      if (match != null) return match;
    }
    if (query.contains('marigold') || query.contains('tagetes')) {
      final match = getSpeciesByName('Marigold');
      if (match != null) return match;
    }
    if (query.contains('jasmine') || query.contains('jasminum')) {
      final match = getSpeciesByName('Jasmine');
      if (match != null) return match;
    }
    if (query.contains('bougainvillea')) {
      final match = getSpeciesByName('Bougainvillea');
      if (match != null) return match;
    }
    if (query.contains('tulsi') || query.contains('basil') || query.contains('ocimum')) {
      final match = getSpeciesByName('Tulsi');
      if (match != null) return match;
    }
    if (query.contains('money plant') || query.contains('pothos') || query.contains('epipremnum') || query.contains('devil\'s ivy')) {
      final match = getSpeciesByName('Money Plant');
      if (match != null) return match;
    }
    if (query.contains('aloe') || query.contains('succulent')) {
      final match = getSpeciesByName('Aloe Vera');
      if (match != null) return match;
    }
    if (query.contains('snake plant') || query.contains('sansevieria')) {
      final match = getSpeciesByName('Snake Plant');
      if (match != null) return match;
    }
    if (query.contains('peace lily') || query.contains('spathiphyllum')) {
      final match = getSpeciesByName('Peace Lily');
      if (match != null) return match;
    }
    if (query.contains('spider plant') || query.contains('chlorophytum')) {
      final match = getSpeciesByName('Spider Plant');
      if (match != null) return match;
    }
    if (query.contains('jade plant') || query.contains('crassula')) {
      final match = getSpeciesByName('Jade Plant');
      if (match != null) return match;
    }
    if (query.contains('zz plant') || query.contains('zamioculcas')) {
      final match = getSpeciesByName('ZZ Plant');
      if (match != null) return match;
    }
    if (query.contains('monstera') || query.contains('deliciosa') || query.contains('swiss cheese')) {
      final match = getSpeciesByName('Monstera');
      if (match != null) return match;
    }
    if (query.contains('orchid') || query.contains('phalaenopsis')) {
      final match = getSpeciesByName('Orchid');
      if (match != null) return match;
    }
    if (query.contains('fern') || query.contains('nephrolepis')) {
      final match = getSpeciesByName('Fern');
      if (match != null) return match;
    }
    if (query.contains('bamboo palm') || query.contains('chamaedorea')) {
      final match = getSpeciesByName('Bamboo Palm');
      if (match != null) return match;
    }
    if (query.contains('tomato')) {
      final match = getSpeciesByName('Tomato');
      if (match != null) return match;
    }
    if (query.contains('mint') || query.contains('mentha')) {
      final match = getSpeciesByName('Mint');
      if (match != null) return match;
    }
    if (query.contains('lavender')) {
      final match = getSpeciesByName('Lavender');
      if (match != null) return match;
    }

    // 3. Tree & Forest keyword heuristic cross-checks
    if (query.contains('banyan')) return getSpeciesByName('Banyan Tree') ?? _fallbackTree('Banyan Tree');
    if (query.contains('pine')) return getSpeciesByName('Pine Tree') ?? _fallbackTree('Pine Tree');
    if (query.contains('ficus')) return getSpeciesByName('Ficus Tree') ?? _fallbackTree('Ficus Tree');
    if (query.contains('mango')) return getSpeciesByName('Mango Tree') ?? _fallbackTree('Mango Tree');
    if (query.contains('gulmohar')) return getSpeciesByName('Gulmohar Tree') ?? _fallbackTree('Gulmohar Tree');
    if (query.contains('neem')) return getSpeciesByName('Neem Tree') ?? _fallbackTree('Neem Tree');

    // 4. Substring matching against cached species
    for (final s in _cachedSpecies) {
      if (s.name.toLowerCase().contains(lowerLabel) || (lowerLabel.isNotEmpty && lowerLabel.contains(s.name.toLowerCase()))) {
        return s;
      }
    }

    // 5. If the AI identified a non-generic botanical plant
    final bool isGeneric = cleanLabel.isEmpty ||
        lowerLabel == 'botanical plant' ||
        lowerLabel == 'plant' ||
        lowerLabel == 'unknown' ||
        lowerLabel == 'green plant' ||
        lowerLabel == 'indoor plant' ||
        lowerLabel == 'flowering plant' ||
        lowerLabel == 'unknown species' ||
        lowerLabel == 'not a plant' ||
        lowerLabel == 'no plant found' ||
        lowerLabel == 'no plant detected' ||
        lowerLabel == 'non-botanical object';

    if (!isGeneric) {
      final newSpecies = PlantSpecies(
        commonName: cleanLabel,
        botanicalName: botanicalName ?? cleanLabel,
        lifespanDays: lifespanDays ?? 365,
        wateringIntervalDays: wateringIntervalDays ?? 3,
        sunlightRequirements: sunlightRequirements ?? 'Bright Indirect Light',
        targetSunlightHours: targetSunlightHours ?? 4,
        careInstructions: careInstructions ?? 'Water when topsoil feels dry and provide appropriate natural sunlight.',
        description: description ?? 'Discovered and identified by SpryFlora AI Vision.',
        idealTemp: idealTemp ?? '18°C - 30°C',
      );
      // Auto-register discovered species into database cache
      addNewSpecies(newSpecies);
      return newSpecies;
    }

    // 6. Generic fallback (neutral botanical plant, never hardcode to Hibiscus)
    return PlantSpecies(
      commonName: 'Botanical Plant',
      lifespanDays: 365,
      wateringIntervalDays: 3,
      sunlightRequirements: 'Bright Indirect Light',
      description: 'Botanical plant analyzed by SpryFlora AI.',
      idealTemp: '18°C - 28°C',
    );
  }

  PlantSpecies _fallbackTree(String treeName) {
    return getSpeciesByName(treeName) ??
        PlantSpecies(
          commonName: treeName,
          lifespanDays: 36500,
          wateringIntervalDays: 4,
          sunlightRequirements: 'Full Direct Sun',
          description: 'Majestic perennial shade tree.',
          idealTemp: '20°C - 38°C',
        );
  }
}
