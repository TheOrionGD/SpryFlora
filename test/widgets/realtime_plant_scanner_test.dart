import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/screens/realtime_plant_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RealtimePlantScannerScreen renders viewfinder HUD and initial scanner UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RealtimePlantScannerScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('AI REAL-TIME SCANNER'), findsOneWidget);
    expect(find.text('Point camera at any plant or leaf...'), findsOneWidget);
    expect(find.text('Instant Capture & Identify ⚡'), findsOneWidget);
  });
}
