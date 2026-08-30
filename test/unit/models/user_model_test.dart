import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/user_model.dart';

void main() {
  group('UserProfile & VirtualPlant Unit Tests', () {
    test('UserProfile creation, serialization, and deserialization', () {
      final user = UserProfile(
        childName: 'Aarav',
        age: 9,
        school: 'Greenwood High',
        favoritePlant: 'Rose',
        profilePhotoPath: '/path/to/photo.jpg',
      );

      final json = user.toJson();
      expect(json['childName'], 'Aarav');
      expect(json['age'], 9);
      expect(json['school'], 'Greenwood High');
      expect(json['favoritePlant'], 'Rose');
      expect(json['profilePhotoPath'], '/path/to/photo.jpg');

      final reconstructed = UserProfile.fromJson(json);
      expect(reconstructed.childName, 'Aarav');
      expect(reconstructed.age, 9);
      expect(reconstructed.school, 'Greenwood High');
      expect(reconstructed.favoritePlant, 'Rose');
      expect(reconstructed.profilePhotoPath, '/path/to/photo.jpg');
    });

    test('UserProfile copyWith updates attributes correctly', () {
      final user = UserProfile(
        childName: 'Ananya',
        age: 10,
        school: 'Oakridge School',
        favoritePlant: 'Tulsi',
      );

      final updated = user.copyWith(
        favoritePlant: 'Aloe Vera',
        age: 11,
      );

      expect(updated.childName, 'Ananya');
      expect(updated.age, 11);
      expect(updated.favoritePlant, 'Aloe Vera');
      expect(updated.school, 'Oakridge School');
    });

    test('VirtualPlant default properties and health manipulation', () {
      final virtualPlant = VirtualPlant(name: 'Buddy Sprout');
      expect(virtualPlant.name, 'Buddy Sprout');
      expect(virtualPlant.health, 50);
      expect(virtualPlant.level, 1);
      expect(virtualPlant.wateringsCount, 0);

      final leveledUp = virtualPlant.copyWith(
        health: 80,
        level: 2,
        wateringsCount: 5,
      );
      expect(leveledUp.health, 80);
      expect(leveledUp.level, 2);
      expect(leveledUp.wateringsCount, 5);

      final json = leveledUp.toJson();
      final fromJsonPlant = VirtualPlant.fromJson(json);
      expect(fromJsonPlant.name, 'Buddy Sprout');
      expect(fromJsonPlant.health, 80);
      expect(fromJsonPlant.level, 2);
      expect(fromJsonPlant.wateringsCount, 5);
    });
  });
}
