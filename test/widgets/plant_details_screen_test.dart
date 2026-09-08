import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/plant_repository.dart';
import 'package:spryflora_app/screens/plant_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlantDetailsScreen Widget Tests', () {
    testWidgets('Renders plant information, health scores and action buttons', (tester) async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'detail_plant_1',
        plantName: 'Royal Jasmine',
        speciesName: 'Jasmine',
        plantingDate: now.subtract(const Duration(days: 10)),
        lifespanDays: 120,
        wateringIntervalDays: 3,
        targetSunlightHours: 5,
        sunlightHoursToday: 3,
        health: 92,
      );

      final repo = PlantRepository();
      await repo.loadLocalData();
      await repo.addPlant(plant);

      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(plantId: plant.id),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Royal Jasmine'), findsWidgets);
      expect(find.text('Jasmine'), findsWidgets);
      expect(find.text('💧 Water Plant'), findsOneWidget);
      expect(find.text('AI Analysis'), findsOneWidget);
    });

    testWidgets('Shows not found error when invalid plantId is provided', (tester) async {
      final repo = PlantRepository();
      await repo.loadLocalData();

      await tester.pumpWidget(
        const MaterialApp(
          home: PlantDetailsScreen(plantId: 'non_existent_plant_id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plant not found (non_existent_plant_id)'), findsOneWidget);
    });
  });
}
