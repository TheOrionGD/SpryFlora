import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  UserProfile? _currentUser;
  VirtualPlant? _virtualPlant;
  bool _isInitialized = false;
  static const String _storageKey = 'spryflora_user';
  static const String _onboardingKey = 'spryflora_onboarding_completed';

  UserService._internal();

  factory UserService() {
    return _instance;
  }

  // In-memory cache getters
  UserProfile? get currentUser => _currentUser;
  VirtualPlant? get virtualPlant => _virtualPlant;
  bool get isInitialized => _isInitialized;

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
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
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        debugPrint('✓ Loaded from shared preferences');
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
      debugPrint('✓ Saved to shared preferences');
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

        if (json['virtualPlant'] != null) {
          _virtualPlant = VirtualPlant.fromJson(
              json['virtualPlant'] as Map<String, dynamic>);
        } else if (_currentUser != null) {
          _virtualPlant = VirtualPlant(name: _currentUser!.favoritePlant);
        }

        _isInitialized = true;
        debugPrint('✓ User data successfully loaded and initialized');
      } else {
        debugPrint('ℹ No existing user data found - first time user');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('✗ Error loading user data: $e');
      _isInitialized = false;
    }
  }

  // Save user profile to persistent storage
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      _currentUser = profile;
      _virtualPlant ??= VirtualPlant(name: profile.favoritePlant);
      await _saveToFile();
      _isInitialized = true;
      debugPrint('✓ User profile saved: ${profile.childName}');
    } catch (e) {
      debugPrint('✗ Error saving user profile: $e');
      rethrow;
    }
  }

  // Update virtual plant health
  Future<void> updateVirtualPlantHealth(int health) async {
    if (_virtualPlant != null) {
      _virtualPlant = _virtualPlant!.copyWith(health: health.clamp(0, 100));
      await _saveToFile();
      debugPrint('Plant health updated: ${_virtualPlant!.health}%');
    }
  }

  // Update virtual plant level
  Future<void> updateVirtualPlantLevel(int level) async {
    if (_virtualPlant != null) {
      _virtualPlant = _virtualPlant!.copyWith(level: level);
      await _saveToFile();
      debugPrint('Plant level updated: ${_virtualPlant!.level}');
    }
  }

  // Water the virtual plant
  Future<void> waterVirtualPlant() async {
    if (_virtualPlant != null) {
      int newHealth = (_virtualPlant!.health + 10).clamp(0, 100);
      _virtualPlant = _virtualPlant!.copyWith(
        health: newHealth,
        wateringsCount: _virtualPlant!.wateringsCount + 1,
        lastWatered: DateTime.now(),
      );
      await _saveToFile();
      debugPrint('Plant watered! New health: ${_virtualPlant!.health}%');
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
        'virtualPlant': _virtualPlant?.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _saveToStorage(jsonEncode(data));
    } catch (e) {
      debugPrint('✗ Error saving data: $e');
    }
  }

  // Clear all user data
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_onboardingKey);
      debugPrint('✓ Cleared shared preferences');

      _currentUser = null;
      _virtualPlant = null;
      _isInitialized = false;
      debugPrint('User data cleared');
    } catch (e) {
      debugPrint('✗ Error clearing user data: $e');
      _currentUser = null;
      _virtualPlant = null;
      _isInitialized = false;
    }
  }
}
