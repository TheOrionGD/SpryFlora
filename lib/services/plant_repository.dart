import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import 'widget_sync_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

/// Local & Remote Plant Repository
/// Manages persistent offline caching and remote synchronization for User Plants & Daily Check-ins
class PlantRepository extends ChangeNotifier {
  static final PlantRepository _instance = PlantRepository._internal();
  factory PlantRepository() => _instance;
  PlantRepository._internal();

  static const String _plantsStorageKey = 'spryflora_user_plants';
  static const String _checkinsStorageKey = 'spryflora_plant_checkins';

  List<PlantModel> _plants = [];
  List<DailyCheckinModel> _checkins = [];
  bool _isLoaded = false;

  List<PlantModel> get plants => List.unmodifiable(_plants);
  List<DailyCheckinModel> get checkins => List.unmodifiable(_checkins);
  bool get isLoaded => _isLoaded;

  /// Loads all plants and checkins from persistent local storage, then syncs with backend if online
  Future<void> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Plants
      final plantsJsonStr = prefs.getString(_plantsStorageKey);
      if (plantsJsonStr != null && plantsJsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(plantsJsonStr) as List<dynamic>;
        _plants = decoded
            .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _plants = [];
      }

      // Load Check-ins
      final checkinsJsonStr = prefs.getString(_checkinsStorageKey);
      if (checkinsJsonStr != null && checkinsJsonStr.isNotEmpty) {
        final List<dynamic> decodedCheckins = jsonDecode(checkinsJsonStr) as List<dynamic>;
        _checkins = decodedCheckins
            .map((item) => DailyCheckinModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _checkins = [];
      }

      _isLoaded = true;
      notifyListeners();

      // Trigger background sync if remote backend is configured
      final remotePlants = await SyncService().syncPlants(_plants);
      if (remotePlants != null && remotePlants.isNotEmpty) {
        _plants = remotePlants;
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

  /// Adds a newly created plant to database
  Future<PlantModel> addPlant(PlantModel plant) async {
    _plants.insert(0, plant);
    await _savePlantsToStorage();
    notifyListeners();
    WidgetSyncService().updateWidgetData(plantsList: _plants);
    NotificationService().reconcileNotifications(_plants);
    SyncService().syncPlants(_plants);
    return plant;
  }

  /// Updates an existing plant
  Future<void> updatePlant(PlantModel updatedPlant) async {
    final index = _plants.indexWhere((p) => p.id == updatedPlant.id);
    if (index != -1) {
      _plants[index] = updatedPlant;
      await _savePlantsToStorage();
      notifyListeners();
      WidgetSyncService().updateWidgetData(plantsList: _plants);
      NotificationService().reconcileNotifications(_plants);
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
      WidgetSyncService().updateWidgetData(plantsList: _plants);
      NotificationService().reconcileNotifications(_plants);
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
    WidgetSyncService().updateWidgetData(plantsList: _plants);
    NotificationService().reconcileNotifications(_plants);
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

  /// Adds a daily check-in record
  Future<void> addCheckin(DailyCheckinModel checkin) async {
    _checkins.insert(0, checkin);
    await _saveCheckinsToStorage();
    notifyListeners();
    SyncService().syncCheckins(_checkins);
  }

  /// Gets all check-in records for a given plant
  List<DailyCheckinModel> getCheckinsForPlant(String plantId) {
    return _checkins.where((c) => c.plantId == plantId).toList();
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
