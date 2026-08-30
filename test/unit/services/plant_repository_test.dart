import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/models/daily_checkin_model.dart';
import 'package:spryflora_app/services/plant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlantRepository Unit Tests', () {
    test('addPlant, getPlantById, updatePlant, and deletePlant full CRUD flow', () async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      // 1. Initially empty
      expect(repo.isLoaded, isTrue);

      final now = DateTime.now();
      final plant1 = PlantModel(
        id: 'plant_repo_1',
        plantName: 'Monstera',
        speciesName: 'Monstera Deliciosa',
        plantingDate: now,
        lifespanDays: 300,
        wateringIntervalDays: 7,
      );

      // 2. Add plant
      await repo.addPlant(plant1);
      expect(repo.plants.length, 1);
      expect(repo.getPlantById('plant_repo_1')?.plantName, 'Monstera');

      // 3. Update plant
      final updatedPlant = plant1.copyWith(plantName: 'Monstera Giant', health: 99);
      await repo.updatePlant(updatedPlant);
      expect(repo.getPlantById('plant_repo_1')?.plantName, 'Monstera Giant');
      expect(repo.getPlantById('plant_repo_1')?.health, 99);

      // 4. Add checkin
      final checkin = DailyCheckinModel(
        id: 'chk_repo_1',
        plantId: 'plant_repo_1',
        checkinDate: now,
        watered: true,
      );
      await repo.addCheckin(checkin);
      expect(repo.getCheckinsForPlant('plant_repo_1').length, 1);

      // 5. Delete plant
      await repo.deletePlant('plant_repo_1');
      expect(repo.getPlantById('plant_repo_1'), isNull);
      expect(repo.getCheckinsForPlant('plant_repo_1').isEmpty, isTrue);
    });

    test('getPlantById returns null when plant id is nonexistent', () async {
      final repo = PlantRepository();
      await repo.loadLocalData();
      expect(repo.getPlantById('non_existent_id'), isNull);
    });
  });
}
