import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_species.dart';

void main() {
  group('PlantSpecies Unit Tests', () {
    test('PlantSpecies parses json and derives default sunlight hours based on sun type', () {
      final directSunSpecies = PlantSpecies.fromJson({
        'name': 'Sunflower',
        'lifespanDays': 90,
        'wateringIntervalDays': 2,
        'sunlight': 'Direct Sun',
      });
      expect(directSunSpecies.targetSunlightHours, 6);

      final shadeSpecies = PlantSpecies.fromJson({
        'name': 'Fern',
        'lifespanDays': 200,
        'wateringIntervalDays': 4,
        'sunlight': 'Low Shade',
      });
      expect(shadeSpecies.targetSunlightHours, 2);

      final indirectSpecies = PlantSpecies.fromJson({
        'name': 'Money Plant',
        'lifespanDays': 300,
        'wateringIntervalDays': 3,
        'sunlight': 'Indirect Light',
      });
      expect(indirectSpecies.targetSunlightHours, 4);
    });

    test('PlantSpecies toJson converts correctly and preserves metadata', () {
      final species = PlantSpecies(
        commonName: 'Tulsi',
        lifespanDays: 120,
        wateringIntervalDays: 2,
        sunlight: 'Direct Sun',
        targetSunlightHours: 6,
        description: 'Sacred medicinal plant.',
        idealTemp: '20°C - 35°C',
        careTip: 'Needs daily sunlight and moist soil.',
      );

      final json = species.toJson();
      expect(json['name'], 'Tulsi');
      expect(json['lifespanDays'], 120);
      expect(json['wateringIntervalDays'], 2);
      expect(json['sunlight'], 'Direct Sun');
      expect(json['targetSunlightHours'], 6);
      expect(json['description'], 'Sacred medicinal plant.');
      expect(json['idealTemp'], '20°C - 35°C');
    });
  });
}
