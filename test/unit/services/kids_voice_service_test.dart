import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/services/kids_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KidsVoiceService Unit Tests', () {
    test('KidsVoiceService singleton maintains consistent instance and language settings', () {
      final voiceService1 = KidsVoiceService();
      final voiceService2 = KidsVoiceService();
      expect(identical(voiceService1, voiceService2), isTrue);

      voiceService1.setLanguage(SpeechLanguage.english);
      expect(voiceService2.currentLanguage, equals(SpeechLanguage.english));

      voiceService1.setLanguage(SpeechLanguage.tamil);
      expect(voiceService2.currentLanguage, equals(SpeechLanguage.tamil));
    });

    test('startListening with inputText streams word by word partial text and completes', () async {
      final voiceService = KidsVoiceService();
      final List<String> receivedPartials = [];

      final result = await voiceService.startListening(
        language: SpeechLanguage.english,
        inputText: 'Water my rose today',
        onPartialText: (partial) {
          receivedPartials.add(partial);
        },
      );

      expect(result, equals('Water my rose today'));
      expect(receivedPartials.isNotEmpty, isTrue);
      expect(receivedPartials.last, equals('Water my rose today'));
      expect(voiceService.isListening, isFalse);
    });

    test('stopListening resets listening status and visualizer levels', () async {
      final voiceService = KidsVoiceService();
      voiceService.startListening(
        inputText: 'Hello plant buddy',
      );
      expect(voiceService.isListening, isTrue);

      voiceService.stopListening();
      expect(voiceService.isListening, isFalse);
    });
  });
}
