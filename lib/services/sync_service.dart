import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}

/// Production Cloud Synchronization & Persistence Service
/// Manages background remote synchronization between local SharedPreferences cache and Authenticated Backend Database
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncedAt;

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Synchronizes local user plants with authenticated backend database
  Future<List<PlantModel>?> syncPlants(List<PlantModel> localPlants) async {
    if (!ApiConfig.usesBackendAuth || !AuthService().isAuthenticated) {
      _status = SyncStatus.offline;
      notifyListeners();
      return null;
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.syncPlantsEndpoint}');
      final response = await http.post(
        uri,
        headers: AuthService().getAuthorizationHeaders(),
        body: jsonEncode({
          'plants': localPlants.map((p) => p.toJson()).toList(),
          'clientTimestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _status = SyncStatus.success;
        _lastSyncedAt = DateTime.now();
        notifyListeners();

        if (data['plants'] is List) {
          final remoteList = (data['plants'] as List)
              .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return remoteList;
        }
      } else {
        _status = SyncStatus.failed;
        _lastError = 'Server returned status code ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _status = SyncStatus.failed;
      _lastError = e.toString();
      debugPrint('Plant synchronization error: $e');
      notifyListeners();
    }
    return null;
  }

  /// Synchronizes daily checkin records with authenticated backend database
  Future<bool> syncCheckins(List<DailyCheckinModel> localCheckins) async {
    if (!ApiConfig.usesBackendAuth || !AuthService().isAuthenticated) {
      return false;
    }

    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.syncCheckinsEndpoint}');
      final response = await http.post(
        uri,
        headers: AuthService().getAuthorizationHeaders(),
        body: jsonEncode({
          'checkins': localCheckins.map((c) => c.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Checkin synchronization error: $e');
      return false;
    }
  }

  /// Synchronizes user profile and progression metadata with authenticated backend
  Future<bool> syncUserProfile(UserProfile? profile) async {
    if (profile == null || !ApiConfig.usesBackendAuth || !AuthService().isAuthenticated) {
      return false;
    }

    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.syncUserProfileEndpoint}');
      final response = await http.post(
        uri,
        headers: AuthService().getAuthorizationHeaders(),
        body: jsonEncode({
          'user': profile.toJson(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('User profile synchronization error: $e');
      return false;
    }
  }
}
