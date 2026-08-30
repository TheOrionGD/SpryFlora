import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/user_service.dart';
import 'package:spryflora_app/services/plant_repository.dart';
import 'package:spryflora_app/services/watering_service.dart';
import 'package:spryflora_app/services/plant_health_engine.dart';
import 'package:spryflora_app/services/ai_service.dart';
import 'package:spryflora_app/services/excel_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SPR Flora Complete App End-to-End & Lifecycle Integration Tests', () {
    test('End-to-End Flow 1: User Onboarding, Profile Setup, and Virtual Companion initialization', () async {
      final userService = UserService();
      await userService.clearUserData();

      // Step 1: Onboarding
      expect(await userService.isOnboardingCompleted(), isFalse);
      await userService.setOnboardingCompleted(true);
      expect(await userService.isOnboardingCompleted(), isTrue);

      // Step 2: Create User Profile
      final profile = UserProfile(
        childName: 'Devansh',
        age: 10,
        school: 'St. Xavier High School',
        favoritePlant: 'Tulsi',
      );
      await userService.saveUserProfile(profile);

      expect(await userService.hasUserData(), isTrue);
      expect(userService.currentUser?.childName, 'Devansh');
      expect(userService.virtualPlant?.name, 'Tulsi');
      expect(userService.virtualPlant?.health, 50);

      // Step 3: Nurture Virtual Plant
      await userService.waterVirtualPlant();
      expect(userService.virtualPlant?.wateringsCount, 1);
      expect(userService.virtualPlant?.health, 60);
    });

    test('End-to-End Flow 2: Plant Species Database, Adding Plant, and Botanical Growth Progression', () async {
      final excelService = ExcelService();
      final speciesList = await excelService.loadSpeciesDatabase();
      expect(speciesList.isNotEmpty, isTrue);

      final selectedSpecies = excelService.getSpeciesByName('Rose');
      expect(selectedSpecies, isNotNull);
      expect(selectedSpecies!.lifespanDays, 150);
      expect(selectedSpecies.wateringIntervalDays, 3);

      final now = DateTime.now();
      final plantingDate = now.subtract(const Duration(days: 30)); // 30 days old

      final newPlant = PlantModel(
        id: 'integration_rose_1',
        plantName: 'Red Queen Rose',
        speciesName: selectedSpecies.name,
        plantingDate: plantingDate,
        lifespanDays: selectedSpecies.lifespanDays,
        wateringIntervalDays: selectedSpecies.wateringIntervalDays,
        targetSunlightHours: selectedSpecies.targetSunlightHours,
      );

      final repo = PlantRepository();
      await repo.loadLocalData();
      await repo.addPlant(newPlant);

      // Verify Plant in Repository
      final storedPlant = repo.getPlantById('integration_rose_1');
      expect(storedPlant, isNotNull);
      expect(storedPlant!.ageInDays, 30);
      expect((storedPlant.growthProgress * 100).toStringAsFixed(1), '20.0');
      expect(storedPlant.growthStageName, 'Sprout');
      expect(storedPlant.calculateFrameIndex(150), 29);
    });

    test('End-to-End Flow 3: Daily Care Check-in, Multi-factor Health Analysis, and AI Advice Generation', () async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      final now = DateTime.now();
      final plant = PlantModel(
        id: 'integration_checkin_flow',
        plantName: 'Holy Basil',
        speciesName: 'Tulsi',
        plantingDate: now.subtract(const Duration(days: 15)),
        lifespanDays: 120,
        wateringIntervalDays: 2,
        targetSunlightHours: 6,
        sunlightHoursToday: 0,
        lastWateredDate: now.subtract(const Duration(days: 2)),
        nextWateringDate: now,
      );
      await repo.addPlant(plant);

      // Verify Watering is Due
      expect(plant.isWateringDue, isTrue);

      // Execute Check-in with Watering Service
      final wateringService = WateringService();
      final updatedPlant = await wateringService.processCheckin(
        plant: plant,
        watered: true,
        sunlightHours: 6,
        environmentCondition: 'Direct Sun',
        notes: 'Gave morning sunlight and fresh water.',
      );

      // Check plant state after check-in
      expect(updatedPlant.isWateringDue, isFalse);
      expect(updatedPlant.sunlightHoursToday, 6);
      expect(updatedPlant.health >= 85, isTrue);
      expect(updatedPlant.healthStatus, 'Thriving');

      // Check Checkin Log Stored in Repository
      final checkins = repo.getCheckinsForPlant(plant.id);
      expect(checkins.length, 1);
      expect(checkins.first.watered, isTrue);
      expect(checkins.first.aiDiagnosis, isNotNull);

      // Query AI Guidance for Plant Stage
      final aiService = AIService();
      final guidance = await aiService.getStageCareGuidance(updatedPlant);
      expect(guidance.isNotEmpty, isTrue);
    });

    test('End-to-End Flow 4: Overdue Watering Penalty and Health Engine Diagnostics', () async {
      final now = DateTime.now();
      final neglectedPlant = PlantModel(
        id: 'neglected_plant_1',
        plantName: 'Thirsty Jade',
        speciesName: 'Jade Plant',
        plantingDate: now.subtract(const Duration(days: 40)),
        lifespanDays: 300,
        wateringIntervalDays: 5,
        lastWateredDate: now.subtract(const Duration(days: 12)),
        nextWateringDate: now.subtract(const Duration(days: 7)), // 7 days overdue
        hydrationScore: 30,
        sunlightScore: 40,
        consistencyScore: 30,
      );

      final report = PlantHealthEngine.evaluate(plant: neglectedPlant);

      expect(report.overallHealth, lessThanOrEqualTo(60));
      expect(report.status == 'Stressed' || report.status == 'Under-watered', isTrue);
      expect(report.warnings.isNotEmpty, isTrue);
      expect(report.recommendations.any((r) => r.toLowerCase().contains('water')), isTrue);
    });
  });
}
