import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserService Unit Tests', () {
    test('Onboarding status persistence', () async {
      final userService = UserService();
      expect(await userService.isOnboardingCompleted(), isFalse);

      await userService.setOnboardingCompleted(true);
      expect(await userService.isOnboardingCompleted(), isTrue);
    });

    test('Saving user profile creates virtual plant and caches user data', () async {
      final userService = UserService();
      await userService.clearUserData();

      final profile = UserProfile(
        childName: 'Reyansh',
        age: 8,
        school: 'DPS',
        favoritePlant: 'Aloe Vera',
      );

      await userService.saveUserProfile(profile);

      expect(userService.currentUser?.childName, 'Reyansh');
      expect(userService.virtualPlant?.name, 'Aloe Vera');
      expect(await userService.hasUserData(), isTrue);
    });

    test('Watering virtual plant increases health and waterings count', () async {
      final userService = UserService();
      await userService.clearUserData();

      final profile = UserProfile(
        childName: 'Meera',
        age: 9,
        school: 'Kendriya Vidyalaya',
        favoritePlant: 'Rose',
      );
      await userService.saveUserProfile(profile);

      final initialHealth = userService.virtualPlant!.health;
      final initialCount = userService.virtualPlant!.wateringsCount;

      await userService.waterVirtualPlant();

      expect(userService.virtualPlant!.health, (initialHealth + 10).clamp(0, 100));
      expect(userService.virtualPlant!.wateringsCount, initialCount + 1);
    });

    test('Updating virtual plant level and health clamps values appropriately', () async {
      final userService = UserService();
      await userService.updateVirtualPlantLevel(3);
      expect(userService.virtualPlant?.level, 3);

      await userService.updateVirtualPlantHealth(150); // should clamp to 100
      expect(userService.virtualPlant?.health, 100);

      await userService.updateVirtualPlantHealth(-10); // should clamp to 0
      expect(userService.virtualPlant?.health, 0);
    });
  });
}
