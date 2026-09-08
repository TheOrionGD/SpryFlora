import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/services/plant_repository.dart';
import 'package:spryflora_app/services/user_service.dart';
import 'package:spryflora_app/screens/home_screen.dart';
import 'package:spryflora_app/screens/garden_screen.dart';
import 'package:spryflora_app/screens/ai_eco_buddy_screen.dart';
import 'package:spryflora_app/screens/add_plant_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PlantRepository().clearInMemoryData();
    UserService().clearInMemoryData();
  });

  group('New Account & No Sample Data Verification Tests', () {
    test('New UserProfile defaults to 0 XP and 0 Care Streak days', () {
      final user = UserProfile(
        childName: 'NewHero',
        age: 8,
        school: 'Spry School',
        favoritePlant: 'Sunflower',
      );

      expect(user.xp, 0);
      expect(user.careStreakDays, 0);
      expect(user.completedPlantsCount, 0);

      final reconstructed = UserProfile.fromJson(user.toJson());
      expect(reconstructed.xp, 0);
      expect(reconstructed.careStreakDays, 0);
    });

    test('UserService virtualPlant is null when no plants are adopted in repository', () {
      expect(PlantRepository().plants.isEmpty, isTrue);
      expect(UserService().virtualPlant, isNull);
    });

    testWidgets('HomeScreen renders clean empty state without fake 86% health or level 2', (tester) async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Should display empty state prompt
      expect(find.text('No Plant Buddy Yet 🌱'), findsOneWidget);
      expect(find.text('Adopt a Plant Buddy 🌱'), findsOneWidget);

      // Must NOT find hardcoded 86% or Level 2 fake data
      expect(find.text('86%'), findsNothing);
      expect(find.text('Level 2'), findsNothing);
    });

    testWidgets('GardenScreen displays 0% Garden Health and 0 Streak on new account with 0 plants', (tester) async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      await tester.pumpWidget(
        const MaterialApp(
          home: GardenScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('0%'), findsWidgets);
      // Must NOT find fake 100% Garden Health when total plants is 0
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('AIEcoBuddyScreen contains no hardcoded fake user question or static reply', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIEcoBuddyScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Must NOT find fake static messages
      expect(find.text('Why are my leaves yellow?'), findsNothing);
      expect(
        find.text('Yellow leaves can be caused by overwatering, underwatering, or lack of sunlight.'),
        findsNothing,
      );

      // Friendly welcome greeting must be present
      expect(find.textContaining('Hello! I\'m your Eco Buddy'), findsOneWidget);
    });

    testWidgets('AddPlantScreen does not display Neem Tree when opened without an identified species', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddPlantScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Should show the interactive species selector prompt
      expect(find.text('Select Botanical Species 🌿'), findsOneWidget);

      // Must NOT display hardcoded Neem Tree
      expect(find.text('Neem Tree'), findsNothing);
    });
  });
}
