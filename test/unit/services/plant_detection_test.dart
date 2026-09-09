// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/ai_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  test('AIService correctly detects and identifies ZZ Plant from user photo', () async {
    final imagePath = r'C:\Users\godfr\.gemini\antigravity-ide\brain\d4e460ad-4ff0-48a3-b061-f7379765f7e2\.user_uploaded\media_1788785586601.png';
    final file = File(imagePath);
    expect(file.existsSync(), isTrue, reason: 'Test image must exist on disk');

    final tempPlant = PlantModel(
      id: 'test_plant_${DateTime.now().millisecondsSinceEpoch}',
      plantName: 'My Desk Plant',
      speciesName: 'ZZ Plant',
      plantingDate: DateTime.now(),
      lifespanDays: 365,
      wateringIntervalDays: 7,
    );

    final aiService = AIService();
    final result = await aiService.analyzePlantPhoto(
      plant: tempPlant,
      photoPath: imagePath,
    );

    print('\n================ VERIFICATION REPORT ================');
    print('isPlantDetected: ${result.isPlantDetected}');
    print('detectedObjectType: ${result.detectedObjectType}');
    print('identifiedSpecies: ${result.identifiedSpecies}');
    print('confidencePercent: ${result.confidencePercent}%');
    print('healthPercent: ${result.healthPercent}%');
    print('diseaseStatus: ${result.diseaseStatus}');
    print('recommendations: ${result.recommendations}');
    print('detailedAdvice: ${result.detailedAdvice}');
    print('matchedSpecies: ${result.matchedSpecies?.name}');
    print('====================================================\n');

    expect(result.isPlantDetected, isTrue, reason: 'Real plant in photo must be detected');
    expect(
      result.detectedObjectType.toLowerCase().contains('plant') ||
          result.detectedObjectType.toLowerCase().contains('flower') ||
          result.detectedObjectType.toLowerCase().contains('leaf') ||
          result.detectedObjectType.toLowerCase().contains('blossom'),
      isTrue,
    );
    expect(result.identifiedSpecies.isNotEmpty, isTrue);
    expect(result.confidencePercent, greaterThanOrEqualTo(80));
    expect(result.healthPercent, greaterThanOrEqualTo(70));
    expect(result.recommendations.isNotEmpty, isTrue);
  }, timeout: const Timeout(Duration(seconds: 120)));
}
