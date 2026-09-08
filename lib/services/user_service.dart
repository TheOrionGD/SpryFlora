import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'plant_repository.dart';
import 'sync_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  String? _currentUserId;
  UserProfile? _currentUser;
  bool _isInitialized = false;

  static const String _legacyStorageKey = 'spryflora_user';
  static const String _legacyOnboardingKey = 'spryflora_onboarding_completed';

  UserService._internal();

  factory UserService() {
    return _instance;
  }

  String get activeUserId => AuthService().currentUser?.id ?? _currentUserId ?? 'usr_default';
  String get _storageKey => 'spryflora_user_$activeUserId';
  String get _onboardingKey => 'spryflora_onboarding_completed_$activeUserId';

  // In-memory cache getters
  UserProfile? get currentUser => _currentUser;
  
  // Virtual plant derived dynamically from authoritative PlantRepository
  VirtualPlant? get virtualPlant {
    final repositoryPlants = PlantRepository().plants;
    if (repositoryPlants.isNotEmpty) {
      final p = repositoryPlants.first;
      return VirtualPlant(
        name: p.plantName,
        health: p.health,
        level: (p.growthProgress * 5).toInt() + 1,
        wateringsCount: repositoryPlants.length,
        lastWatered: p.lastWateredDate,
      );
    }
    if (_currentUser != null && _currentUser!.favoritePlant.isNotEmpty) {
      return VirtualPlant(name: _currentUser!.favoritePlant);
    }
    return null;
  }
  bool get isInitialized => _isInitialized;

  /// Sets active user context and reloads user profile
  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = userId;
    await loadUserData();
  }

  /// Clears in-memory cache upon user logout
  void clearInMemoryData() {
    _currentUser = null;
    _isInitialized = false;
  }

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userScoped = prefs.getBool(_onboardingKey);
      if (userScoped != null) return userScoped;
      return prefs.getBool(_legacyOnboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, value);
    } catch (_) {}
  }

  // Platform-agnostic storage load using SharedPreferences
  Future<String?> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? stored = prefs.getString(_storageKey);
      if ((stored == null || stored.isEmpty) && activeUserId == 'usr_default') {
        stored = prefs.getString(_legacyStorageKey);
      }
      if (stored != null && stored.isNotEmpty) {
        debugPrint('✓ Loaded user profile from shared preferences ($activeUserId)');
        return stored;
      }
    } catch (e) {
      debugPrint('Error in _loadFromStorage: $e');
    }
    return null;
  }

  // Platform-agnostic storage save using SharedPreferences
  Future<void> _saveToStorage(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonData);
      debugPrint('✓ Saved user profile to shared preferences ($activeUserId)');
    } catch (e) {
      debugPrint('Error in _saveToStorage: $e');
    }
  }

  // Initialize/Load user data from persistent storage
  Future<void> loadUserData() async {
    try {
      final stored = await _loadFromStorage();

      if (stored != null && stored.isNotEmpty) {
        final json = jsonDecode(stored) as Map<String, dynamic>;

        if (json['user'] != null) {
          _currentUser =
              UserProfile.fromJson(json['user'] as Map<String, dynamic>);
          debugPrint('✓ Loaded user: ${_currentUser?.childName}');
        }

        _isInitialized = true;
        debugPrint('✓ User data successfully loaded and initialized');
      } else {
        debugPrint('ℹ No existing user data found for $activeUserId');
        _currentUser = null;
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('✗ Error loading user data: $e');
      _currentUser = null;
      _isInitialized = false;
    }
  }

  // Save user profile to persistent storage
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      _currentUser = profile;
      await _saveToFile();
      _isInitialized = true;
      debugPrint('✓ User profile saved: ${profile.childName}');
    } catch (e) {
      debugPrint('✗ Error saving user profile: $e');
      rethrow;
    }
  }

  /// Adds XP points to the current user's profile and updates progression level
  Future<void> addXp(int points) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(xp: _currentUser!.xp + points);
      await _saveToFile();
    }
  }

  /// Increments completed plants count
  Future<void> incrementCompletedPlants() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        completedPlantsCount: _currentUser!.completedPlantsCount + 1,
        xp: _currentUser!.xp + 200,
      );
      await _saveToFile();
    }
  }

  /// Updates favorite plant in user profile
  Future<void> updateFavoritePlant(String plantName) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(favoritePlant: plantName);
      await _saveToFile();
    }
  }

  // Update virtual plant health by updating authoritative plant in repository
  Future<void> updateVirtualPlantHealth(int health) async {
    final plants = PlantRepository().plants;
    if (plants.isNotEmpty) {
      final updated = plants.first.copyWith(health: health.clamp(0, 100));
      await PlantRepository().updatePlant(updated);
    }
  }

  // Update virtual plant level
  Future<void> updateVirtualPlantLevel(int level) async {
    // Level is derived dynamically from growth progress in PlantModel
  }

  // Water the virtual plant with daily idempotency protection
  Future<void> waterVirtualPlant() async {
    final plants = PlantRepository().plants;
    if (plants.isNotEmpty) {
      final p = plants.first;
      final now = DateTime.now();
      final last = p.lastWateredDate;
      final isSameDay = last.year == now.year && last.month == now.month && last.day == now.day;

      final updated = p.copyWith(
        health: (p.health + 10).clamp(0, 100),
        lastWateredDate: now,
        nextWateringDate: now.add(Duration(days: p.wateringIntervalDays)),
      );
      await PlantRepository().updatePlant(updated);

      if (_currentUser != null && !isSameDay) {
        final newStreak = _currentUser!.careStreakDays + 1;
        _currentUser = _currentUser!.copyWith(
          xp: _currentUser!.xp + 25,
          careStreakDays: newStreak,
        );
        await _saveToFile();
      }
    }
  }

  // Check if user has completed setup
  Future<bool> hasUserData() async {
    // Check in-memory first
    if (_currentUser != null && _isInitialized) {
      debugPrint('✓ User data exists in memory: ${_currentUser!.childName}');
      return true;
    }

    // Check persistent storage
    try {
      final stored = await _loadFromStorage();
      if (stored != null && stored.isNotEmpty) {
        try {
          final json = jsonDecode(stored) as Map<String, dynamic>;
          final hasUser = json.containsKey('user') && json['user'] != null;
          debugPrint('Storage check - Has user data: $hasUser');
          return hasUser;
        } catch (e) {
          debugPrint('Error decoding stored data: $e');
          return false;
        }
      }
      debugPrint('✗ No user data found in storage');
      return false;
    } catch (e) {
      debugPrint('✗ Error checking user data: $e');
      return false;
    }
  }

  // Private method to save data to appropriate storage
  Future<void> _saveToFile() async {
    try {
      final data = {
        'user': _currentUser?.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _saveToStorage(jsonEncode(data));
      SyncService().syncUserProfile(_currentUser);
    } catch (e) {
      debugPrint('✗ Error saving data: $e');
    }
  }

  // Clear current active user data
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_onboardingKey);
      await PlantRepository().clearCurrentUserData();
      debugPrint('✓ Cleared user preferences for $activeUserId');

      _currentUser = null;
      _isInitialized = false;
      debugPrint('User data cleared');
    } catch (e) {
      debugPrint('✗ Error clearing user data: $e');
      _currentUser = null;
      _isInitialized = false;
    }
  }
}
