import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/config/api_config.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIService Unit Tests', () {
    test('AIService accesses configured ApiConfig credentials seamlessly', () {
      final aiService = AIService();
      expect(aiService.apiKey.isNotEmpty, isTrue);
      expect(aiService.apiKey, ApiConfig.geminiApiKey);
    });

    test('Stage care guidance works with botanical rule engine', () async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'ai_plant_seed',
        plantName: 'Little Sprout',
        speciesName: 'Rose',
        plantingDate: now.subtract(const Duration(days: 5)),
        lifespanDays: 150,
        wateringIntervalDays: 3,
      );

      final aiService = AIService();
      final guidance = await aiService.getStageCareGuidance(plant);

      expect(guidance.isNotEmpty, isTrue);
      expect(guidance.length, greaterThan(10));
    });

    test('analyzeCheckinAndPhoto produces diagnostic feedback', () async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'ai_plant_chk',
        plantName: 'Sunny',
        speciesName: 'Sunflower',
        plantingDate: now.subtract(const Duration(days: 12)),
        lifespanDays: 90,
        wateringIntervalDays: 2,
        targetSunlightHours: 6,
      );

      final aiService = AIService();
      final diagnosis = await aiService.analyzeCheckinAndPhoto(
        plant: plant,
        watered: true,
        sunlightHours: 6,
        environmentCondition: 'Direct Sun',
      );

      expect(diagnosis.isNotEmpty, isTrue);
    });

    test('askFloraAI handles plant care consultation questions', () async {
      final now = DateTime.now();
      final plant = PlantModel(
        id: 'ai_plant_qna',
        plantName: 'Ruby',
        speciesName: 'Tulsi',
        plantingDate: now.subtract(const Duration(days: 20)),
        lifespanDays: 120,
        wateringIntervalDays: 2,
      );

      final aiService = AIService();
      final answer = await aiService.askFloraAI(
        plant: plant,
        userQuestion: 'How many hours of sunlight does my Tulsi need?',
      );

      expect(answer.isNotEmpty, isTrue);
      expect(answer.length, greaterThan(10));
    });
  });
}
