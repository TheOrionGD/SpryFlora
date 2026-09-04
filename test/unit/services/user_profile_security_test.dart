import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/models/plant_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Profile & Security Verification Tests', () {
    test('UserProfile experience level is correctly calculated from earned XP', () {
      final beginnerUser = UserProfile(
        childName: 'Aarav',
        age: 10,
        school: 'Greenwood Elementary',
        favoritePlant: 'Rose',
        xp: 150,
      );
      expect(beginnerUser.experienceLevelName, 'Beginner');

      final intermediateUser = beginnerUser.copyWith(xp: 450);
      expect(intermediateUser.experienceLevelName, 'Intermediate');

      final advancedUser = beginnerUser.copyWith(xp: 900);
      expect(advancedUser.experienceLevelName, 'Advanced');
    });

    test('Plant completion and certificate eligibility strict validation', () {
      final incompletePlant = PlantModel(
        id: 'plant_001',
        plantName: 'My Rose',
        speciesName: 'Rose',
        plantingDate: DateTime.now(),
        lifespanDays: 100,
        wateringIntervalDays: 3,
        isCompletedManually: false,
      );

      expect(incompletePlant.isCompleted, isFalse);

      final maturePlant = PlantModel(
        id: 'plant_002',
        plantName: 'My Rose',
        speciesName: 'Rose',
        plantingDate: DateTime.now().subtract(const Duration(days: 105)),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );

      expect(maturePlant.isCompleted, isTrue);

      final manuallyCompleted = incompletePlant.copyWith(isCompletedManually: true);
      expect(manuallyCompleted.isCompleted, isTrue);
    });
  });
}
