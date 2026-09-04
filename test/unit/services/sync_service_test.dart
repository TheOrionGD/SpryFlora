import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/models/daily_checkin_model.dart';
import 'package:spryflora_app/models/user_model.dart';
import 'package:spryflora_app/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncService Unit Tests', () {
    test('SyncService handles unauthenticated / offline sync gracefully', () async {
      final syncService = SyncService();
      expect(syncService.status, SyncStatus.idle);
      expect(syncService.isSyncing, isFalse);

      final testPlant = PlantModel(
        id: 'sync_p1',
        plantName: 'Sync Rose',
        speciesName: 'Rose',
        plantingDate: DateTime.now(),
        lifespanDays: 100,
        wateringIntervalDays: 3,
      );

      final result = await syncService.syncPlants([testPlant]);
      expect(result, isNull);
      expect(syncService.status, SyncStatus.offline);

      final checkinResult = await syncService.syncCheckins([
        DailyCheckinModel(
          id: 'c1',
          plantId: 'sync_p1',
          checkinDate: DateTime.now(),
          watered: true,
          sunlightHours: 4,
          environmentCondition: 'Bright Direct Light',
        ),
      ]);
      expect(checkinResult, isFalse);

      final profileResult = await syncService.syncUserProfile(
        UserProfile(childName: 'Aarav', age: 10, school: 'Spry Academy', favoritePlant: 'Rose'),
      );
      expect(profileResult, isFalse);
    });
  });
}
