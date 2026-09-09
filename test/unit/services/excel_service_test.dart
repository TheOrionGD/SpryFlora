import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/services/excel_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExcelService Unit Tests', () {
    test('loadSpeciesDatabase returns non-empty plant species catalogue', () async {
      final service = ExcelService();
      final speciesList = await service.loadSpeciesDatabase();

      expect(speciesList.isNotEmpty, isTrue);
      expect(speciesList.any((s) => s.name.toLowerCase() == 'rose'), isTrue);
      expect(speciesList.any((s) => s.name.toLowerCase() == 'tulsi'), isTrue);
    });

    test('getSpeciesByName finds Hibiscus and popular flowers', () async {
      final service = ExcelService();
      await service.loadSpeciesDatabase();

      final hibiscus = service.getSpeciesByName('Hibiscus');
      expect(hibiscus, isNotNull);
      expect(hibiscus!.name, 'Hibiscus');
      expect(hibiscus.wateringIntervalDays, 2);
      expect(hibiscus.sunlight.toLowerCase(), contains('sun'));
    });

    test('matchSpeciesFromAIPrediction matches Hibiscus and avoids Money Plant fallback', () async {
      final service = ExcelService();
      await service.loadSpeciesDatabase();

      final match = service.matchSpeciesFromAIPrediction('Hibiscus flower');
      expect(match.name, 'Hibiscus');
      expect(match.name, isNot(equals('Money Plant')));
    });

    test('matchSpeciesFromAIPrediction creates dynamic species for new discoveries', () async {
      final service = ExcelService();
      await service.loadSpeciesDatabase();

      final dynamicPlant = service.matchSpeciesFromAIPrediction(
        'Calathea Orbifolia',
        wateringIntervalDays: 5,
        sunlightRequirements: 'Filtered Medium Light',
        description: 'Striking round silver-striped leaves.',
      );

      expect(dynamicPlant.name, 'Calathea Orbifolia');
      expect(dynamicPlant.wateringIntervalDays, 5);
      expect(dynamicPlant.sunlightRequirements, 'Filtered Medium Light');
      expect(dynamicPlant.name, isNot(equals('Money Plant')));
    });
  });
}
