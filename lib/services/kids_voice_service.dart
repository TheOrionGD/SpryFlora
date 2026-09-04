import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Supported Speech Languages
enum SpeechLanguage {
  tamil,
  english,
  tanglish,
}

/// Kids Voice & Speech Recognition Service
/// Performs real live speech recognition in Tamil, English, and Tanglish,
/// streams real microphone sound level data to the 7-band visualizer, and returns transcribed text.
class KidsVoiceService {
  static final KidsVoiceService _instance = KidsVoiceService._internal();
  factory KidsVoiceService() => _instance;
  KidsVoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  SpeechLanguage _currentLanguage = SpeechLanguage.tamil;

  final StreamController<List<double>> _visualizerStreamController =
      StreamController<List<double>>.broadcast();

  bool get isListening => _isListening;
  SpeechLanguage get currentLanguage => _currentLanguage;
  Stream<List<double>> get visualizerStream => _visualizerStreamController.stream;

  void setLanguage(SpeechLanguage lang) {
    _currentLanguage = lang;
  }

  /// Initializes underlying SpeechToText engine if supported
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        _isInitialized = await _speechToText.initialize(
          onError: (val) => debugPrint('SpeechToText error: $val'),
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
              _updateVisualizerWithAmplitude(0.0);
            }
          },
        );
      } else {
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('SpeechToText initialization failed: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  /// Starts listening to speech input and streams live audio visualizer waveforms based on real microphone sound levels.
  /// If [inputText] is supplied, streams partial text updates to [onPartialText].
  Future<String?> startListening({
    SpeechLanguage? language,
    String? inputText,
    Function(String partialText)? onPartialText,
  }) async {
    _isListening = true;
    if (language != null) _currentLanguage = language;

    if (inputText != null && inputText.isNotEmpty) {
      final words = inputText.split(' ');
      String currentText = '';
      for (int i = 0; i < words.length; i++) {
        if (!_isListening) break;
        await Future.delayed(const Duration(milliseconds: 120));
        currentText += (i == 0 ? '' : ' ') + words[i];
        _updateVisualizerWithAmplitude(0.4 + (i % 3) * 0.2);
        if (onPartialText != null) {
          onPartialText(currentText);
        }
      }
      stopListening();
      return currentText;
    }

    final available = await initialize();
    if (!available) {
      _isListening = false;
      _updateVisualizerWithAmplitude(0.0);
      return null;
    }

    String localeId = 'ta_IN';
    if (_currentLanguage == SpeechLanguage.english) {
      localeId = 'en_US';
    } else if (_currentLanguage == SpeechLanguage.tanglish) {
      localeId = 'ta_IN';
    }

    final Completer<String?> completer = Completer<String?>();
    String recognizedText = '';

    try {
      await _speechToText.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          if (onPartialText != null && recognizedText.isNotEmpty) {
            onPartialText(recognizedText);
          }
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(recognizedText);
          }
        },
        onSoundLevelChange: (level) {
          // Normalize decibel level (-10dB to +10dB) into 0.1 to 1.0 amplitude
          final normalized = ((level + 10) / 20).clamp(0.1, 1.0);
          _updateVisualizerWithAmplitude(normalized);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        ),
      );

      // Auto resolve after timeout if no final result fired
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(recognizedText.isNotEmpty ? recognizedText : null);
        }
      });

      final result = await completer.future;
      stopListening();
      return result;
    } catch (e) {
      debugPrint('Error during speech recognition: $e');
      stopListening();
      return null;
    }
  }

  /// Maps microphone sound amplitude into 7-band visualizer heights
  void _updateVisualizerWithAmplitude(double amplitude) {
    if (!_visualizerStreamController.isClosed) {
      final amp = amplitude.clamp(0.1, 1.0);
      final levels = [
        (amp * 0.6).clamp(0.1, 1.0),
        (amp * 0.85).clamp(0.1, 1.0),
        (amp * 1.0).clamp(0.1, 1.0),
        (amp * 0.95).clamp(0.1, 1.0),
        (amp * 0.75).clamp(0.1, 1.0),
        (amp * 0.55).clamp(0.1, 1.0),
        (amp * 0.35).clamp(0.1, 1.0),
      ];
      _visualizerStreamController.add(levels);
    }
  }

  /// Stops speech recognition listening and resets visualizer waveform to quiet state
  void stopListening() {
    _isListening = false;
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _updateVisualizerWithAmplitude(0.0);
  }

  void dispose() {
    stopListening();
    _visualizerStreamController.close();
  }
}
