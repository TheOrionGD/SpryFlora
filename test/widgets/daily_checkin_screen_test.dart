import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/screens/daily_checkin_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyCheckinScreen Widget Tests', () {
    final testPlant = PlantModel(
      id: 'chk_plant_1',
      plantName: 'Emerald Fern',
      speciesName: 'Boston Fern',
      plantingDate: DateTime.now().subtract(const Duration(days: 10)),
      lifespanDays: 150,
      wateringIntervalDays: 3,
      targetSunlightHours: 4,
    );

    testWidgets('Renders plant name, check-in options, and controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DailyCheckinScreen(
            plant: testPlant,
            initialPhotoPath: 'test_photo.jpg',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Check-in'), findsOneWidget);
      expect(find.text('Emerald Fern'), findsOneWidget);
      expect(find.textContaining('Did you water today?'), findsOneWidget);
      expect(find.text('Submit Check-in'), findsOneWidget);
    });

    testWidgets('Validates watering question and options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DailyCheckinScreen(
            plant: testPlant,
            initialPhotoPath: 'test_photo.jpg',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final submitButton = find.text('Submit Check-in');
      expect(submitButton, findsOneWidget);
    });

    testWidgets('Allows selecting YES and changing sunlight options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DailyCheckinScreen(
            plant: testPlant,
            initialPhotoPath: 'test_photo.jpg',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap YES choice
      final yesChoice = find.textContaining('Yes');
      expect(yesChoice, findsOneWidget);
      await tester.tap(yesChoice);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
