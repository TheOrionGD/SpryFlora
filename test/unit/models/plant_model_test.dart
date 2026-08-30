import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_model.dart';

void main() {
  group('PlantModel Unit Tests', () {
    test('Calculates plant age correctly in days', () {
      final now = DateTime.now();
      final plantingDate = now.subtract(const Duration(days: 15));

      final plant = PlantModel(
        id: 'p_1',
        plantName: 'Ferny',
        speciesName: 'Boston Fern',
        plantingDate: plantingDate,
        lifespanDays: 100,
        wateringIntervalDays: 4,
      );

      expect(plant.ageInDays, 15);
      expect(plant.isCompleted, isFalse);
    });

    test('Calculates growth progress clamped between 0.0 and 1.0', () {
      final now = DateTime.now();
      
      // Case 1: Young plant (10 days / 100 days = 0.10)
      final plantYoung = PlantModel(
        id: 'p_young',
        plantName: 'Seedling',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );
      expect(plantYoung.growthProgress, closeTo(0.10, 0.01));
      expect(plantYoung.growthStageName, 'Seed');

      // Case 2: Sprout (30 days / 100 days = 0.30)
      final plantSprout = PlantModel(
        id: 'p_sprout',
        plantName: 'Sprout',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 30)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );
      expect(plantSprout.growthProgress, closeTo(0.30, 0.01));
      expect(plantSprout.growthStageName, 'Sprout');

      // Case 3: Growing Plant (70 days / 100 days = 0.70)
      final plantGrowing = PlantModel(
        id: 'p_growing',
        plantName: 'Growing',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 70)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );
      expect(plantGrowing.growthProgress, closeTo(0.70, 0.01));
      expect(plantGrowing.growthStageName, 'Growing Plant');

      // Case 4: Fully Grown Plant (100 days / 100 days = 1.0)
      final plantMature = PlantModel(
        id: 'p_mature',
        plantName: 'Mature',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 105)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );
      expect(plantMature.growthProgress, 1.0);
      expect(plantMature.growthStageName, 'Fully Grown Plant');
      expect(plantMature.isCompleted, isTrue);
    });

    test('Animation frame index calculation accurately maps to frame range', () {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'p_frame',
        plantName: 'Lily',
        speciesName: 'Peace Lily',
        plantingDate: now.subtract(const Duration(days: 50)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );

      // 50% progress on 150 total frames -> floor(0.5 * 149) = 74
      expect(plant.calculateFrameIndex(150), 74);
      expect(plant.calculateFrameIndex(1), 0);
      expect(plant.calculateFrameIndex(0), 0);
    });

    test('Watering due and overdue status verification', () {
      final now = DateTime.now();

      final overduePlant = PlantModel(
        id: 'p_due',
        plantName: 'Dry Plant',
        speciesName: 'Tulsi',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 100,
        wateringIntervalDays: 2,
        nextWateringDate: now.subtract(const Duration(days: 1)),
      );
      expect(overduePlant.isWateringDue, isTrue);
      expect(overduePlant.daysUntilWatering, lessThanOrEqualTo(0));

      final futureWateringPlant = PlantModel(
        id: 'p_future',
        plantName: 'Hydrated Plant',
        speciesName: 'Tulsi',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 100,
        wateringIntervalDays: 2,
        nextWateringDate: now.add(const Duration(days: 2)),
      );
      expect(futureWateringPlant.isWateringDue, isFalse);
      expect(futureWateringPlant.daysUntilWatering, 2);
    });

    test('Serialization and deserialization to/from JSON preserves all fields', () {
      final now = DateTime.now();
      final originalPlant = PlantModel(
        id: 'p_json_test',
        plantName: 'Bonsai Ficus',
        speciesName: 'Ficus',
        plantingDate: now.subtract(const Duration(days: 25)),
        lifespanDays: 200,
        wateringIntervalDays: 5,
        targetSunlightHours: 6,
        sunlightHoursToday: 4,
        location: 'Balcony Garden',
        health: 88,
        hydrationScore: 90,
        sunlightScore: 85,
        consistencyScore: 92,
        healthStatus: 'Thriving',
      );

      final json = originalPlant.toJson();
      final reconstructedPlant = PlantModel.fromJson(json);

      expect(reconstructedPlant.id, originalPlant.id);
      expect(reconstructedPlant.plantName, originalPlant.plantName);
      expect(reconstructedPlant.speciesName, originalPlant.speciesName);
      expect(reconstructedPlant.lifespanDays, originalPlant.lifespanDays);
      expect(reconstructedPlant.wateringIntervalDays, originalPlant.wateringIntervalDays);
      expect(reconstructedPlant.targetSunlightHours, originalPlant.targetSunlightHours);
      expect(reconstructedPlant.sunlightHoursToday, originalPlant.sunlightHoursToday);
      expect(reconstructedPlant.location, originalPlant.location);
      expect(reconstructedPlant.health, originalPlant.health);
      expect(reconstructedPlant.hydrationScore, originalPlant.hydrationScore);
      expect(reconstructedPlant.sunlightScore, originalPlant.sunlightScore);
      expect(reconstructedPlant.consistencyScore, originalPlant.consistencyScore);
      expect(reconstructedPlant.healthStatus, originalPlant.healthStatus);
    });

    test('copyWith properly modifies target attributes and preserves rest', () {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'p_orig',
        plantName: 'Original Name',
        speciesName: 'Rose',
        plantingDate: now,
        lifespanDays: 150,
        wateringIntervalDays: 3,
        health: 70,
      );

      final modified = plant.copyWith(
        plantName: 'Updated Rose Name',
        health: 95,
        healthStatus: 'Optimal',
      );

      expect(modified.id, plant.id);
      expect(modified.plantName, 'Updated Rose Name');
      expect(modified.health, 95);
      expect(modified.healthStatus, 'Optimal');
      expect(modified.lifespanDays, plant.lifespanDays);
      expect(modified.wateringIntervalDays, plant.wateringIntervalDays);
    });
  });
}
