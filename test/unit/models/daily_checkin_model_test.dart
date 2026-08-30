import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/daily_checkin_model.dart';

void main() {
  group('DailyCheckinModel Unit Tests', () {
    test('DailyCheckinModel handles serialization and deserialization seamlessly', () {
      final checkin = DailyCheckinModel(
        id: 'chk_101',
        plantId: 'plant_abc',
        checkinDate: DateTime(2026, 8, 30),
        watered: true,
        sunlightHours: 5,
        environmentCondition: 'Direct Sun',
        photoPath: '/storage/photo_chk.jpg',
        notes: 'Leaves look very vibrant today!',
        aiDiagnosis: 'Optimal photosynthetic activity detected.',
      );

      final json = checkin.toJson();
      expect(json['id'], 'chk_101');
      expect(json['plantId'], 'plant_abc');
      expect(json['watered'], isTrue);
      expect(json['sunlightHours'], 5);
      expect(json['environmentCondition'], 'Direct Sun');
      expect(json['photoPath'], '/storage/photo_chk.jpg');
      expect(json['notes'], 'Leaves look very vibrant today!');
      expect(json['aiDiagnosis'], 'Optimal photosynthetic activity detected.');

      final reconstructed = DailyCheckinModel.fromJson(json);
      expect(reconstructed.id, 'chk_101');
      expect(reconstructed.plantId, 'plant_abc');
      expect(reconstructed.watered, isTrue);
      expect(reconstructed.sunlightHours, 5);
      expect(reconstructed.environmentCondition, 'Direct Sun');
      expect(reconstructed.photoPath, '/storage/photo_chk.jpg');
      expect(reconstructed.notes, 'Leaves look very vibrant today!');
      expect(reconstructed.aiDiagnosis, 'Optimal photosynthetic activity detected.');
    });

    test('DailyCheckinModel handles default and nullable values properly', () {
      final checkin = DailyCheckinModel(
        id: 'chk_defaults',
        plantId: 'plant_xyz',
        checkinDate: DateTime(2026, 8, 30),
        watered: false,
      );

      expect(checkin.sunlightHours, 4);
      expect(checkin.environmentCondition, 'Bright Indirect');
      expect(checkin.photoPath, isNull);
      expect(checkin.notes, isNull);
      expect(checkin.aiDiagnosis, isNull);

      final json = checkin.toJson();
      final fromJson = DailyCheckinModel.fromJson(json);
      expect(fromJson.watered, isFalse);
      expect(fromJson.sunlightHours, 4);
      expect(fromJson.environmentCondition, 'Bright Indirect');
    });
  });
}
