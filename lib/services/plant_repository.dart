import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

/// Local & Remote Plant Repository
/// Manages persistent offline caching and remote synchronization for User Plants & Daily Check-ins with User Data Isolation
class PlantRepository extends ChangeNotifier {
  static final PlantRepository _instance = PlantRepository._internal();
  factory PlantRepository() => _instance;
  PlantRepository._internal();

  static const String _legacyPlantsStorageKey = 'spryflora_user_plants';
  static const String _legacyCheckinsStorageKey = 'spryflora_plant_checkins';

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

  /// Loads all plants and checkins for the active userId from persistent local storage
  Future<void> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Plants
      String? plantsJsonStr = prefs.getString(_plantsStorageKey);
      // Fallback for default/guest account migration from legacy global key
      if ((plantsJsonStr == null || plantsJsonStr.isEmpty) && activeUserId == 'usr_default') {
        plantsJsonStr = prefs.getString(_legacyPlantsStorageKey);
      }

      if (plantsJsonStr != null && plantsJsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(plantsJsonStr) as List<dynamic>;
        _plants = decoded
            .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
            .where((p) => p.userId == activeUserId || activeUserId == 'usr_default' || p.userId.isEmpty)
            .toList();
      } else {
        _plants = [];
      }

      // Load Check-ins
      String? checkinsJsonStr = prefs.getString(_checkinsStorageKey);
      if ((checkinsJsonStr == null || checkinsJsonStr.isEmpty) && activeUserId == 'usr_default') {
        checkinsJsonStr = prefs.getString(_legacyCheckinsStorageKey);
      }

      if (checkinsJsonStr != null && checkinsJsonStr.isNotEmpty) {
        final List<dynamic> decodedCheckins = jsonDecode(checkinsJsonStr) as List<dynamic>;
        _checkins = decodedCheckins
            .map((item) => DailyCheckinModel.fromJson(item as Map<String, dynamic>))
            .where((c) => c.userId == activeUserId || activeUserId == 'usr_default' || c.userId.isEmpty)
            .toList();
      } else {
        _checkins = [];
      }

      _isLoaded = true;
      notifyListeners();

      // Trigger background sync if remote backend is configured
      final remotePlants = await SyncService().syncPlants(_plants);
      if (remotePlants != null && remotePlants.isNotEmpty) {
        _plants = remotePlants.where((p) => p.userId == activeUserId || activeUserId == 'usr_default').toList();
        await _savePlantsToStorage();
        notifyListeners();
      }
      await SyncService().syncCheckins(_checkins);
    } catch (_) {
      _plants = [];
      _checkins = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Adds a newly created plant for the current user
  Future<PlantModel> addPlant(PlantModel plant) async {
    final taggedPlant = plant.userId == activeUserId || plant.userId != 'usr_default'
        ? plant
        : plant.copyWith(userId: activeUserId);

    _plants.insert(0, taggedPlant);
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
      await _savePlantsToStorage();
      notifyListeners();
      SyncService().syncPlants(_plants);
    }
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

  /// Deletes a plant by ID
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

    _checkins.insert(0, taggedCheckin);
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
      await prefs.setString(_plantsStorageKey, jsonEncode(plantsListJson));
    } catch (_) {}
  }

  Future<void> _saveCheckinsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkinsListJson = _checkins.map((c) => c.toJson()).toList();
      await prefs.setString(_checkinsStorageKey, jsonEncode(checkinsListJson));
    } catch (_) {}
  }
}
