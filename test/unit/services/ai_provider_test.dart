import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/services/ai_provider.dart';

void main() {
  group('AIProvider Unit Tests & Failure Safety Verification', () {
    test('GeminiProvider returns authenticationError when API key is unconfigured', () async {
      final provider = GeminiProvider(apiKey: '');
      final result = await provider.identifyPlant(base64Image: 'fake_image_data');

      expect(result.status, AIResultStatus.authenticationError);
      expect(result.isPlantDetected, isFalse);
    });

    test('GeminiProvider verifyWatering returns failure when unconfigured', () async {
      final provider = GeminiProvider(apiKey: '');
      final result = await provider.verifyWatering(
        plantName: 'Rose',
        speciesName: 'Rose',
        base64Image: 'fake_image',
      );

      expect(result.status, AIResultStatus.authenticationError);
      expect(result.isVerified, isFalse);
    });

    test('HuggingFaceProvider returns error when rawBytes are missing', () async {
      final provider = HuggingFaceProvider(apiKey: 'dummy_key');
      final result = await provider.identifyPlant(base64Image: 'fake_image', rawBytes: null);

      expect(result.status, AIResultStatus.authenticationError);
      expect(result.isPlantDetected, isFalse);
    });

    test('GrokProvider askBuddy returns authenticationError when API key is missing', () async {
      final provider = GrokProvider(apiKey: '');
      final result = await provider.askBuddy(prompt: 'Hello Grok');

      expect(result.status, AIResultStatus.authenticationError);
      expect(result.answerText.contains('missing') || result.answerText.contains('unavailable'), isTrue);
    });
  });
}
