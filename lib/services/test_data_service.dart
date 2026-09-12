import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import 'auth_service.dart';
import 'plant_repository.dart';
import 'user_service.dart';

/// Test Data Utility for testing Money Plant completion workflows
class TestDataService {
  static const String testUserId = 'usr_moneyplant_master_001';
  static const String testEmail = 'moneyplant_user@spryflora.com';
  static const String testUsername = 'moneyplant_master';
  static const String testPassword = 'Password123!';

  /// Seeds local storage with a fully completed Money Plant test user and care history
  static Future<void> seedCompletedMoneyPlantLocalUser() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Create Auth session
    final authUser = AuthUser(
      id: testUserId,
      email: testEmail,
      name: 'Leo Green',
      sessionExpiresAt: DateTime.now().add(const Duration(days: 3650)),
    );

    await prefs.setString(
      'spryflora_auth_session',
      jsonEncode({
        'user': authUser.toJson(),
        'token': 'token_$testUserId',
      }),
    );
    await prefs.setBool('spryflora_explicit_logout', false);

    // 2. Set active user profile
    final profile = UserProfile(
      childName: 'Leo Green',
      age: 10,
      school: 'Emerald Botanical Academy',
      favoritePlant: 'Money Plant',
      xp: 1850,
      careStreakDays: 45,
      completedPlantsCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 160)),
    );

    await prefs.setString(
      'spryflora_user_$testUserId',
      jsonEncode({
        'user': profile.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setBool('spryflora_onboarding_completed_$testUserId', true);

    // 3. Create fully completed Money Plant model
    final now = DateTime.now();
    final plantingDate = now.subtract(const Duration(days: 160));
    final plantId = 'plant_money_plant_$testUserId';

    final moneyPlant = PlantModel(
      id: plantId,
      userId: testUserId,
      plantName: 'Prosperity Money Plant',
      speciesName: 'Money Plant',
      plantingDate: plantingDate,
      lifespanDays: 150,
      wateringIntervalDays: 3,
      targetSunlightHours: 4,
      sunlightHoursToday: 4,
      lastSunlightDate: now,
      location: 'Living Room Window',
      lastWateredDate: now,
      nextWateringDate: now.add(const Duration(days: 3)),
      health: 100,
      hydrationScore: 100,
      sunlightScore: 100,
      consistencyScore: 100,
      healthStatus: 'Optimal',
      initialHeightCm: 2.0,
      matureHeightCm: 50.0,
      isCompletedManually: true,
      createdAt: plantingDate,
      updatedAt: now,
    );

    final plantsList = [moneyPlant.toJson()];
    await prefs.setString(
      'spryflora_user_plants_$testUserId',
      jsonEncode(plantsList),
    );

    // 4. Create verified daily checkins across 150-day lifecycle
    final checkins = <Map<String, dynamic>>[];
    final milestoneOffsets = [160, 145, 130, 110, 80, 50, 20, 1, 0];

    for (int i = 0; i < milestoneOffsets.length; i++) {
      final daysAgo = milestoneOffsets[i];
      final checkinDate = now.subtract(Duration(days: daysAgo));
      final checkin = DailyCheckinModel(
        id: 'chk_${testUserId}_$i',
        plantId: plantId,
        userId: testUserId,
        checkinDate: checkinDate,
        watered: true,
        sunlightHours: 4,
        environmentCondition: 'Bright Indirect',
        notes: i == milestoneOffsets.length - 1
            ? "Today's daily check-in and watering completed. All daily tasks up-to-date!"
            : 'Milestone stage check-in #$i completed with healthy growth.',
        aiDiagnosis: 'Optimal condition verified. Master Botanist criteria fulfilled.',
        createdAt: checkinDate,
      );
      checkins.add(checkin.toJson());
    }

    await prefs.setString(
      'spryflora_plant_checkins_$testUserId',
      jsonEncode(checkins),
    );

    // 5. Reload in-memory state
    await AuthService().restoreSession();
    await UserService().setCurrentUser(testUserId);
    await PlantRepository().setCurrentUser(testUserId);
  }
}
