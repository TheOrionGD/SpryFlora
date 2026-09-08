import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/widgets/petal_completion_dialog.dart';
import 'package:spryflora_app/widgets/fun_bouncy_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testPlant = PlantModel(
    id: 'test_plant_123',
    plantName: 'Rosie',
    speciesName: 'Rose',
    plantingDate: DateTime.now().subtract(const Duration(days: 30)),
    lifespanDays: 45,
    wateringIntervalDays: 3,
    location: 'Sunny Window',
    health: 95,
  );

  testWidgets('PetalCompletionDialog renders, tracks taps, and finishes challenge',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetalCompletionDialog(
            plant: testPlant,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title and Plant Nickname render
    expect(find.text('🌸 Petal Harvest Challenge! 🌸'), findsOneWidget);
    expect(find.text('Rosie'), findsOneWidget);
    expect(find.text('Seeds: 0 / 6'), findsOneWidget);

    // Tap the first petal
    final firstPetal = find.byKey(const ValueKey('petal_button_0'));
    expect(firstPetal, findsOneWidget);
    await tester.tap(firstPetal);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Seeds: 1 / 6'), findsOneWidget);

    // Tap remaining 5 petals
    for (int i = 1; i < 6; i++) {
      final petal = find.byKey(ValueKey('petal_button_$i'));
      expect(petal, findsOneWidget);
      await tester.tap(petal);
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Now all 6 petals are plucked
    expect(find.text('Seeds: 6 / 6'), findsOneWidget);
    expect(find.text('Claim Certificate & Rewards! 🏅'), findsOneWidget);

    // Tap Claim button
    final claimButton = find.widgetWithText(FunBouncyButton, 'Claim Certificate & Rewards! 🏅');
    expect(claimButton, findsOneWidget);
    await tester.tap(claimButton);
    await tester.pump(const Duration(milliseconds: 300));

    expect(completed, isTrue);
  });

  testWidgets('PetalCompletionDialog Harvest All Petals button works instantly',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetalCompletionDialog(
            plant: testPlant,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Tap Harvest All Petals shortcut
    final harvestAllButton = find.byKey(const ValueKey('harvest_all_button'));
    expect(harvestAllButton, findsOneWidget);
    await tester.tap(harvestAllButton);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Seeds: 6 / 6'), findsOneWidget);
    expect(find.text('Claim Certificate & Rewards! 🏅'), findsOneWidget);

    // Claim
    final claimButton = find.widgetWithText(FunBouncyButton, 'Claim Certificate & Rewards! 🏅');
    await tester.tap(claimButton);
    await tester.pump(const Duration(milliseconds: 300));

    expect(completed, isTrue);
  });

  testWidgets('Tapping center flower core plucks the next unharvested petal',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetalCompletionDialog(
            plant: testPlant,
            onComplete: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Seeds: 0 / 6'), findsOneWidget);

    // Tap center bud text/icon
    await tester.tap(find.text('🌱'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Seeds: 1 / 6'), findsOneWidget);
  });
}
