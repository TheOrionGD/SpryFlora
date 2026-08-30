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

    test('getSpeciesByName finds species case-insensitively', () async {
      final service = ExcelService();
      await service.loadSpeciesDatabase();

      final rose = service.getSpeciesByName('rOsE');
      expect(rose, isNotNull);
      expect(rose!.name, 'Rose');

      final notFound = service.getSpeciesByName('Cryptic Alien Plant');
      expect(notFound, isNull);
    });
  });
}
