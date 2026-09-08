import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
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

    test('resolveLocale correctly preserves Tamil and Tanglish without falling back to en_US', () {
      final availableLocales = [
        LocaleName('en_US', 'English (United States)'),
        LocaleName('en_GB', 'English (United Kingdom)'),
        LocaleName('ta_IN', 'Tamil (India)'),
      ];

      // Tamil matches ta_IN
      final tamilRes = KidsVoiceService.resolveLocale(
        language: SpeechLanguage.tamil,
        locales: availableLocales,
      );
      expect(tamilRes, equals('ta_IN'));

      // Tanglish matches ta_IN when available
      final tanglishRes = KidsVoiceService.resolveLocale(
        language: SpeechLanguage.tanglish,
        locales: availableLocales,
      );
      expect(tanglishRes, equals('ta_IN'));

      // When only English is available on device, Tamil strictly resolves to ta_IN for network recognition, NEVER en_US
      final onlyEnglishLocales = [
        LocaleName('en_US', 'English (United States)'),
      ];
      final tamilFallbackRes = KidsVoiceService.resolveLocale(
        language: SpeechLanguage.tamil,
        locales: onlyEnglishLocales,
      );
      expect(tamilFallbackRes, equals('ta_IN'));

      // Tanglish with en_IN available uses en_IN
      final indianEnglishLocales = [
        LocaleName('en_IN', 'English (India)'),
        LocaleName('en_US', 'English (United States)'),
      ];
      final tanglishIndianRes = KidsVoiceService.resolveLocale(
        language: SpeechLanguage.tanglish,
        locales: indianEnglishLocales,
      );
      expect(tanglishIndianRes, equals('en_IN'));

      // English resolves to en_US
      final englishRes = KidsVoiceService.resolveLocale(
        language: SpeechLanguage.english,
        locales: availableLocales,
      );
      expect(englishRes, equals('en_US'));
    });
  });
}
