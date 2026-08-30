import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/models/daily_checkin_model.dart';
import 'package:spryflora_app/services/plant_health_engine.dart';

void main() {
  group('PlantHealthEngine Unit Tests', () {
    test('Calculates high health score and Thriving status for well-cared plant', () {
      final now = DateTime.now();
      final healthyPlant = PlantModel(
        id: 'p_healthy',
        plantName: 'Bella',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 150,
        wateringIntervalDays: 3,
        targetSunlightHours: 6,
        sunlightHoursToday: 6,
        lastWateredDate: now,
        nextWateringDate: now.add(const Duration(days: 3)),
        hydrationScore: 95,
        sunlightScore: 98,
        consistencyScore: 95,
      );

      final report = PlantHealthEngine.evaluate(
        plant: healthyPlant,
        currentCheckinWatered: true,
        currentCheckinSunlight: 6,
      );

      expect(report.overallHealth, greaterThanOrEqualTo(85));
      expect(report.status, 'Thriving');
      expect(report.hydrationScore, greaterThanOrEqualTo(90));
      expect(report.sunlightScore, equals(100));
      expect(report.warnings.isEmpty, isTrue);
      expect(report.recommendations.isNotEmpty, isTrue);
    });

    test('Penalizes severely overdue plant and updates health warnings', () {
      final now = DateTime.now();
      final overduePlant = PlantModel(
        id: 'p_overdue',
        plantName: 'Thirsty Cactus',
        speciesName: 'Cactus',
        plantingDate: now.subtract(const Duration(days: 30)),
        lifespanDays: 200,
        wateringIntervalDays: 5,
        nextWateringDate: now.subtract(const Duration(days: 6)), // 6 days overdue
        hydrationScore: 40,
        sunlightScore: 50,
        consistencyScore: 40,
      );

      final report = PlantHealthEngine.evaluate(plant: overduePlant);

      expect(report.overallHealth, lessThan(70));
      expect(report.hydrationScore, lessThanOrEqualTo(60));
      expect(report.warnings.any((w) => w.toLowerCase().contains('watering') || w.toLowerCase().contains('overdue')), isTrue);
      expect(report.recommendations.any((r) => r.toLowerCase().contains('water')), isTrue);
    });

    test('Calculates consistency score based on recent check-in history', () {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'p_streak',
        plantName: 'Consistent Basil',
        speciesName: 'Basil',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 90,
        wateringIntervalDays: 2,
      );

      final checkins = List.generate(
        7,
        (index) => DailyCheckinModel(
          id: 'chk_$index',
          plantId: plant.id,
          checkinDate: now.subtract(Duration(days: index)),
          watered: true,
          sunlightHours: 4,
        ),
      );

      final report = PlantHealthEngine.evaluate(
        plant: plant,
        checkins: checkins,
      );

      expect(report.consistencyScore, 100);
    });
  });
}
