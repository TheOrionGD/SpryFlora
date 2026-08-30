import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/plant_repository.dart';
import 'package:spryflora_app/screens/garden_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GardenScreen Widget Tests', () {
    testWidgets('Renders Garden title, stats cards and Add Plant button', (tester) async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      await tester.pumpWidget(
        const MaterialApp(
          home: GardenScreen(),
        ),
      );
      // Garden screen contains continuous repeating ambient and wind animations
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('My Garden'), findsOneWidget);
      expect(find.text('My Plants'), findsOneWidget);
      expect(find.text('Garden Health'), findsOneWidget);
      expect(find.text('Add New Plant'), findsOneWidget);
    });

    testWidgets('Displays plant count accurately when repository contains plants', (tester) async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'garden_p_1',
        plantName: 'Orchid Flower',
        speciesName: 'Orchid',
        plantingDate: now,
        lifespanDays: 120,
        wateringIntervalDays: 4,
      );

      final repo = PlantRepository();
      await repo.loadLocalData();
      await repo.addPlant(plant);

      await tester.pumpWidget(
        const MaterialApp(
          home: GardenScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Stats row should show "1"
      expect(find.text('1'), findsWidgets);
    });
  });
}
