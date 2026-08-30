import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/watering_service.dart';
import 'package:spryflora_app/services/plant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WateringService Unit Tests', () {
    test('calculateInitialNextWatering calculates date according to interval days', () {
      final plantingDate = DateTime(2026, 8, 30);
      final nextWatering = WateringService.calculateInitialNextWatering(plantingDate, 4);

      expect(nextWatering, plantingDate.add(const Duration(days: 4)));
    });

    test('processCheckin with watered=true resets next watering date and adds check-in', () async {
      final now = DateTime.now();
      final initialPlant = PlantModel(
        id: 'plant_w_test',
        plantName: 'Orchid',
        speciesName: 'Orchid',
        plantingDate: now.subtract(const Duration(days: 5)),
        lifespanDays: 180,
        wateringIntervalDays: 7,
        lastWateredDate: now.subtract(const Duration(days: 7)),
        nextWateringDate: now,
      );

      final repo = PlantRepository();
      await repo.loadLocalData();
      await repo.addPlant(initialPlant);

      final wateringService = WateringService();
      final updated = await wateringService.processCheckin(
        plant: initialPlant,
        watered: true,
        sunlightHours: 4,
        environmentCondition: 'Bright Indirect',
        notes: 'Watered thoroughly in the morning',
      );

      expect(updated.isWateringDue, isFalse);
      expect(updated.sunlightHoursToday, 4);
      expect(updated.hydrationScore, greaterThanOrEqualTo(90));

      final checkins = repo.getCheckinsForPlant(initialPlant.id);
      expect(checkins.isNotEmpty, isTrue);
      expect(checkins.first.watered, isTrue);
      expect(checkins.first.notes, 'Watered thoroughly in the morning');
    });

    test('logSunlight updates plant sunlight metrics and health scores', () async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'plant_sun_test',
        plantName: 'Sun Catcher',
        speciesName: 'Sunflower',
        plantingDate: now.subtract(const Duration(days: 2)),
        lifespanDays: 90,
        wateringIntervalDays: 2,
        targetSunlightHours: 6,
        sunlightHoursToday: 0,
      );

      final repo = PlantRepository();
      await repo.loadLocalData();
      await repo.addPlant(plant);

      final wateringService = WateringService();
      final updated = await wateringService.logSunlight(
        plant: plant,
        hours: 6,
      );

      expect(updated.sunlightHoursToday, 6);
      expect(updated.sunlightScore, 100);
    });
  });
}
