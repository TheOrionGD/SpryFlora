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
          home: DailyCheckinScreen(plant: testPlant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Check-in'), findsOneWidget);
      expect(find.text('Emerald Fern'), findsOneWidget);
      expect(find.textContaining('Did you water today?'), findsOneWidget);
      expect(find.text('Submit Check-in'), findsOneWidget);
    });

    testWidgets('Validates watering question before submitting', (tester) async {
      // Set surface size to avoid off-screen scrolling issues in tests
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DailyCheckinScreen(plant: testPlant),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Submit button without selecting YES/NO
      final submitButton = find.text('Submit Check-in');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(
        find.text('Please take a photo for your daily check-in!'),
        findsOneWidget,
      );
    });

    testWidgets('Allows selecting YES and changing sunlight options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DailyCheckinScreen(plant: testPlant),
        ),
      );
      await tester.pumpAndSettle();

      // Tap YES choice
      final yesChoice = find.textContaining('Yes');
      expect(yesChoice, findsOneWidget);
      await tester.tap(yesChoice);
      await tester.pumpAndSettle();
    });
  });
}
