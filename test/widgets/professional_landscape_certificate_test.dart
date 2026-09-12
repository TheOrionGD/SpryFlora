import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/widgets/professional_landscape_certificate.dart';

void main() {
  testWidgets('ProfessionalLandscapeCertificate renders text fields properly', (WidgetTester tester) async {
    final plant = PlantModel(
      id: 'test_plant_123',
      plantName: 'My Silver Lady Fern',
      speciesName: 'Blechnum gibbum',
      plantingDate: DateTime.now().subtract(const Duration(days: 30)),
      lifespanDays: 30,
      wateringIntervalDays: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfessionalLandscapeCertificate(
            plant: plant,
            recipientName: 'Priya',
            certificateId: 'SF-178893',
            issueDate: DateTime(2026, 9, 9),
          ),
        ),
      ),
    );

    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('My Silver Lady Fern Care & Growth Program'), findsOneWidget);
    expect(find.text('SF-178893'), findsOneWidget);
    expect(find.text('09/09/2026'), findsOneWidget);
  });
}
