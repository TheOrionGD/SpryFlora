import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

/// Local & Remote Plant Repository
/// Manages persistent offline caching and remote synchronization for User Plants & Daily Check-ins with Resilient Data Persistence
class PlantRepository extends ChangeNotifier {
  static final PlantRepository _instance = PlantRepository._internal();
  factory PlantRepository() => _instance;
  PlantRepository._internal();

  static const String _legacyPlantsStorageKey = 'spryflora_user_plants';
  static const String _legacyCheckinsStorageKey = 'spryflora_plant_checkins';
  static const String _defaultUserPlantsKey = 'spryflora_user_plants_usr_default';
  static const String _defaultUserCheckinsKey = 'spryflora_plant_checkins_usr_default';

  String? _currentUserId;
  List<PlantModel> _plants = [];
  List<DailyCheckinModel> _checkins = [];
  bool _isLoaded = false;

  String get activeUserId => AuthService().currentUser?.id ?? _currentUserId ?? 'usr_default';
  String get _plantsStorageKey => 'spryflora_user_plants_$activeUserId';
  String get _checkinsStorageKey => 'spryflora_plant_checkins_$activeUserId';

  List<PlantModel> get plants => List.unmodifiable(_plants);
  List<DailyCheckinModel> get checkins => List.unmodifiable(_checkins);
  bool get isLoaded => _isLoaded;

  /// Sets the active user context and reloads user-isolated plants & checkins
  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = userId;
    await loadLocalData();
  }

  /// Clears in-memory cache upon user logout
  void clearInMemoryData() {
    _plants = [];
    _checkins = [];
    _isLoaded = false;
    notifyListeners();
  }

  /// Loads all plants and checkins with multi-tier storage fallback to guarantee zero accidental deletions
  Future<void> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load Plants with multi-key fallback & merger
      String? plantsJsonStr = prefs.getString(_plantsStorageKey);
      if (plantsJsonStr == null || plantsJsonStr.isEmpty) {
        plantsJsonStr = prefs.getString(_legacyPlantsStorageKey);
      }
      if (plantsJsonStr == null || plantsJsonStr.isEmpty) {
        plantsJsonStr = prefs.getString(_defaultUserPlantsKey);
      }

      final Map<String, PlantModel> plantMap = {};

      // Keep existing in-memory plants first
      for (final p in _plants) {
        plantMap[p.id] = p;
      }

      if (plantsJsonStr != null && plantsJsonStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(plantsJsonStr) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final plant = PlantModel.fromJson(item);
              plantMap[plant.id] = plant;
            }
          }
        } catch (e) {
          debugPrint('Error parsing stored plants JSON: $e');
        }
      }

      // Also check legacy storage key to rescue any orphaned plants
      final legacyStr = prefs.getString(_legacyPlantsStorageKey);
      if (legacyStr != null && legacyStr.isNotEmpty && legacyStr != plantsJsonStr) {
        try {
          final List<dynamic> decoded = jsonDecode(legacyStr) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final plant = PlantModel.fromJson(item);
              if (!plantMap.containsKey(plant.id)) {
                plantMap[plant.id] = plant;
              }
            }
          }
        } catch (_) {}
      }

      _plants = plantMap.values.toList();

      // 2. Load Check-ins with multi-key fallback
      String? checkinsJsonStr = prefs.getString(_checkinsStorageKey);
      if (checkinsJsonStr == null || checkinsJsonStr.isEmpty) {
        checkinsJsonStr = prefs.getString(_legacyCheckinsStorageKey);
      }
      if (checkinsJsonStr == null || checkinsJsonStr.isEmpty) {
        checkinsJsonStr = prefs.getString(_defaultUserCheckinsKey);
      }

      final Map<String, DailyCheckinModel> checkinMap = {};
      for (final c in _checkins) {
        checkinMap[c.id] = c;
      }

      if (checkinsJsonStr != null && checkinsJsonStr.isNotEmpty) {
        try {
          final List<dynamic> decodedCheckins = jsonDecode(checkinsJsonStr) as List<dynamic>;
          for (final item in decodedCheckins) {
            if (item is Map<String, dynamic>) {
              final checkin = DailyCheckinModel.fromJson(item);
              checkinMap[checkin.id] = checkin;
            }
          }
        } catch (e) {
          debugPrint('Error parsing stored checkins JSON: $e');
        }
      }

      _checkins = checkinMap.values.toList();
      _isLoaded = true;
      notifyListeners();

      // Ensure local state is saved back redundantly
      await _savePlantsToStorage();
      await _saveCheckinsToStorage();

      // Trigger background sync if remote backend is configured
      final remotePlants = await SyncService().syncPlants(_plants);
      if (remotePlants != null && remotePlants.isNotEmpty) {
        for (final rp in remotePlants) {
          plantMap[rp.id] = rp;
        }
        _plants = plantMap.values.toList();
        await _savePlantsToStorage();
        notifyListeners();
      }
      await SyncService().syncCheckins(_checkins);
    } catch (e) {
      debugPrint('Exception in loadLocalData (preserving existing in-memory plants): $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Adds a newly created plant for the current user
  Future<PlantModel> addPlant(PlantModel plant) async {
    final taggedPlant = plant.userId == activeUserId || plant.userId != 'usr_default'
        ? plant
        : plant.copyWith(userId: activeUserId);

    final existingIdx = _plants.indexWhere((p) => p.id == taggedPlant.id);
    if (existingIdx != -1) {
      _plants[existingIdx] = taggedPlant;
    } else {
      _plants.insert(0, taggedPlant);
    }

    await _savePlantsToStorage();
    notifyListeners();
    NotificationService().notifyPlantAdded(taggedPlant);
    SyncService().syncPlants(_plants);
    return taggedPlant;
  }

  /// Updates an existing plant belonging to active user
  Future<void> updatePlant(PlantModel updatedPlant) async {
    final index = _plants.indexWhere((p) => p.id == updatedPlant.id);
    if (index != -1) {
      _plants[index] = updatedPlant;
    } else {
      _plants.add(updatedPlant);
    }
    await _savePlantsToStorage();
    notifyListeners();
    SyncService().syncPlants(_plants);
  }

  /// Marks a plant as fully completed
  Future<void> markPlantCompleted(String id) async {
    final index = _plants.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plants[index] = _plants[index].copyWith(
        isCompletedManually: true,
        updatedAt: DateTime.now(),
      );
      await _savePlantsToStorage();
      notifyListeners();
      SyncService().syncPlants(_plants);
    }
  }

  /// Deletes a plant by ID (only when explicitly requested by user in plant details delete dialog)
  Future<void> deletePlant(String id) async {
    _plants.removeWhere((p) => p.id == id);
    _checkins.removeWhere((c) => c.plantId == id);
    await _savePlantsToStorage();
    await _saveCheckinsToStorage();
    notifyListeners();
    SyncService().syncPlants(_plants);
  }

  /// Finds plant by ID
  PlantModel? getPlantById(String id) {
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a daily check-in record for active user
  Future<void> addCheckin(DailyCheckinModel checkin) async {
    final taggedCheckin = checkin.userId == activeUserId || checkin.userId != 'usr_default'
        ? checkin
        : DailyCheckinModel(
            id: checkin.id,
            plantId: checkin.plantId,
            userId: activeUserId,
            checkinDate: checkin.checkinDate,
            watered: checkin.watered,
            sunlightHours: checkin.sunlightHours,
            environmentCondition: checkin.environmentCondition,
            photoPath: checkin.photoPath,
            notes: checkin.notes,
            aiDiagnosis: checkin.aiDiagnosis,
            createdAt: checkin.createdAt,
          );

    final existingIdx = _checkins.indexWhere((c) => c.id == taggedCheckin.id);
    if (existingIdx != -1) {
      _checkins[existingIdx] = taggedCheckin;
    } else {
      _checkins.insert(0, taggedCheckin);
    }

    await _saveCheckinsToStorage();
    notifyListeners();
    SyncService().syncCheckins(_checkins);
  }

  /// Gets all check-in records for a given plant
  List<DailyCheckinModel> getCheckinsForPlant(String plantId) {
    return _checkins.where((c) => c.plantId == plantId).toList();
  }

  /// Clears user data for current active user
  Future<void> clearCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_plantsStorageKey);
      await prefs.remove(_checkinsStorageKey);
      _plants = [];
      _checkins = [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePlantsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plantsListJson = _plants.map((p) => p.toJson()).toList();
      final encoded = jsonEncode(plantsListJson);
      await prefs.setString(_plantsStorageKey, encoded);
      await prefs.setString(_legacyPlantsStorageKey, encoded);
      await prefs.setString(_defaultUserPlantsKey, encoded);
    } catch (_) {}
  }

  Future<void> _saveCheckinsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkinsListJson = _checkins.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(checkinsListJson);
      await prefs.setString(_checkinsStorageKey, encoded);
      await prefs.setString(_legacyCheckinsStorageKey, encoded);
      await prefs.setString(_defaultUserCheckinsKey, encoded);
    } catch (_) {}
  }
}
