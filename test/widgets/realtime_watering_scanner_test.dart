import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/screens/realtime_watering_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPlant = PlantModel(
    id: 'plant_tulsi_test',
    plantName: 'Holy Basil',
    speciesName: 'Tulsi',
    plantingDate: DateTime.now().subtract(const Duration(days: 10)),
    lifespanDays: 90,
    wateringIntervalDays: 2,
    targetSunlightHours: 5,
  );

  testWidgets('RealtimeWateringScannerScreen renders HUD, plant badge, and water mug badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RealtimeWateringScannerScreen(plant: testPlant),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Must show plant name badge and water container badge
    expect(find.textContaining('WATERING SCANNER: HOLY BASIL'), findsOneWidget);
    expect(find.text('Holy Basil'), findsOneWidget);
    expect(find.text('Water Mug / Can'), findsOneWidget);

    // Instant capture button
    expect(find.text('Instant Capture & Water 💧'), findsOneWidget);
  });
}
