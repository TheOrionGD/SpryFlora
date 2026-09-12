import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/services/test_data_service.dart';
import 'package:spryflora_app/services/plant_repository.dart';
import 'package:spryflora_app/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Money Plant Completed Test User Suite', () {
    test('Should seed completed test user with 100% grown Money Plant and all tasks complete', () async {
      await TestDataService.seedCompletedMoneyPlantLocalUser();

      final user = UserService().currentUser;
      expect(user, isNotNull);
      expect(user!.childName, 'Leo Green');
      expect(user.favoritePlant, 'Money Plant');
      expect(user.xp, greaterThanOrEqualTo(1000));
      expect(user.careStreakDays, greaterThanOrEqualTo(30));
      expect(user.experienceLevelName, 'Advanced');

      final plants = PlantRepository().plants;
      expect(plants.isNotEmpty, isTrue);

      final moneyPlant = plants.first;
      expect(moneyPlant.speciesName, 'Money Plant');
      expect(moneyPlant.growthProgress, 1.0);
      expect(moneyPlant.isCompleted, isTrue);
      expect(moneyPlant.currentHeightCm, 50.0);
      expect(moneyPlant.growthStageName, 'Fully Grown Plant');
      expect(moneyPlant.health, 100);
      expect(moneyPlant.isWateringDue, isFalse);

      final checkins = PlantRepository().checkins;
      expect(checkins.isNotEmpty, isTrue);
      expect(checkins.length, greaterThanOrEqualTo(5));
      expect(checkins.first.watered, isTrue);
    });
  });
}
