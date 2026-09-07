import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/weather_service.dart';
import 'package:spryflora_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WeatherService & Botanical Climate Evaluation Tests', () {
    final weatherService = WeatherService();

    final testPlant = PlantModel(
      id: 'test_plant_1',
      plantName: 'Living Room ZZ Plant',
      speciesName: 'ZZ Plant',
      plantingDate: DateTime.now().subtract(const Duration(days: 5)),
      lifespanDays: 1000,
      wateringIntervalDays: 14,
      location: 'Living Room',
    );

    test('Identifies extreme heat and recommends indoor sheltering', () {
      final hotWeather = WeatherData(
        temperature: 38.5,
        relativeHumidity: 45.0,
        weatherCode: 0,
        locationName: 'Chennai, India',
        latitude: 13.0827,
        longitude: 80.2707,
      );

      final eval = weatherService.evaluateClimateForPlant(testPlant, hotWeather);

      expect(eval.alertTriggered, isTrue);
      expect(eval.suggestedEnvironment, 'Indoor');
      expect(eval.alertTitle, contains('High Heat Warning'));
      expect(eval.recommendation, contains('Extreme heat detected'));
    });

    test('Identifies low humidity and suggests misting', () {
      final dryWeather = WeatherData(
        temperature: 28.0,
        relativeHumidity: 22.0,
        weatherCode: 1,
        locationName: 'Desert Valley',
        latitude: 25.0,
        longitude: 55.0,
      );

      final eval = weatherService.evaluateClimateForPlant(testPlant, dryWeather);

      expect(eval.alertTriggered, isTrue);
      expect(eval.alertTitle, contains('Low Humidity'));
      expect(eval.recommendation, contains('Mist leaves'));
    });

    test('Optimal climate triggers no alarming alerts', () {
      final optimalWeather = WeatherData(
        temperature: 26.0,
        relativeHumidity: 60.0,
        weatherCode: 1,
        locationName: 'Bangalore, India',
        latitude: 12.9716,
        longitude: 77.5946,
      );

      final eval = weatherService.evaluateClimateForPlant(testPlant, optimalWeather);

      expect(eval.alertTriggered, isFalse);
      expect(eval.alertTitle, 'Optimal Weather');
    });
  });

  group('PlantModel Environment & Location Classification', () {
    test('Derived environment correctly classifies indoor vs outdoor', () {
      final indoorPlant = PlantModel(
        id: 'p1',
        plantName: 'Desk Friend',
        speciesName: 'Pothos',
        plantingDate: DateTime.now(),
        lifespanDays: 365,
        wateringIntervalDays: 7,
        location: 'Living Room Table',
      );

      final outdoorPlant = PlantModel(
        id: 'p2',
        plantName: 'Sun Seeker',
        speciesName: 'Rose',
        plantingDate: DateTime.now(),
        lifespanDays: 365,
        wateringIntervalDays: 2,
        location: 'Backyard Garden Patio',
      );

      expect(indoorPlant.environment, 'Indoor');
      expect(outdoorPlant.environment, 'Outdoor');
    });
  });

  group('NotificationService Deduplication Tests', () {
    test('Watering reminder records daily dispatch and avoids repeated cycling', () async {
      final service = NotificationService();
      final duePlant = PlantModel(
        id: 'due_plant_101',
        plantName: 'Thirsty Fern',
        speciesName: 'Boston Fern',
        plantingDate: DateTime.now().subtract(const Duration(days: 10)),
        lifespanDays: 365,
        wateringIntervalDays: 3,
        lastWateredDate: DateTime.now().subtract(const Duration(days: 4)),
      );

      expect(duePlant.isWateringDue, isTrue);

      // First run: dispatches reminder and writes timestamp
      await service.checkAndNotifyDuePlants([duePlant]);

      final prefs = await SharedPreferences.getInstance();
      final reminderKey = 'notified_water_reminder_${duePlant.id}';
      expect(prefs.containsKey(reminderKey), isTrue);

      final firstDispatchDate = prefs.getString(reminderKey);
      expect(firstDispatchDate, isNotNull);

      // Second run on same day: should safely skip without throwing or altering timestamp
      await service.checkAndNotifyDuePlants([duePlant]);
      expect(prefs.getString(reminderKey), equals(firstDispatchDate));
    });
  });
}
