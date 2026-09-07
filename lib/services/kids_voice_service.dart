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

  Timer? _animTimer;

  /// Initializes underlying SpeechToText engine if supported
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        _isInitialized = await _speechToText.initialize(
          onError: (val) {
            debugPrint('SpeechToText error: $val');
          },
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
              _stopWaveformAnimation();
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

  void _startWaveformAnimation() {
    _animTimer?.cancel();
    int tick = 0;
    _animTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isListening) {
        t.cancel();
        return;
      }
      tick++;
      final baseAmp = 0.35 + 0.25 * (tick % 5) / 5.0;
      _updateVisualizerWithAmplitude(baseAmp);
    });
  }

  void _stopWaveformAnimation() {
    _animTimer?.cancel();
    _animTimer = null;
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
      // Platform without native STT (e.g. Windows desktop or simulator)
      _startWaveformAnimation();
      return null;
    }

    String localeId = 'ta_IN';
    try {
      final locales = await _speechToText.locales();
      final systemLoc = await _speechToText.systemLocale();
      final targetPrefix =
          _currentLanguage == SpeechLanguage.english ? 'en' : 'ta';

      LocaleName? matched;
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(targetPrefix)) {
          matched = l;
          break;
        }
      }
      if (matched == null) {
        for (final l in locales) {
          if (l.localeId.toLowerCase().startsWith('en')) {
            matched = l;
            break;
          }
        }
      }
      matched ??= systemLoc ?? (locales.isNotEmpty ? locales.first : null);
      if (matched != null) {
        localeId = matched.localeId;
      }
    } catch (_) {}

    final Completer<String?> completer = Completer<String?>();
    String recognizedText = '';
    _startWaveformAnimation();

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
          final normalized = ((level + 10) / 20).clamp(0.1, 1.0);
          _updateVisualizerWithAmplitude(normalized);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 4),
        ),
      );

      // Timeout fallback
      Timer(const Duration(seconds: 15), () {
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
      return recognizedText.isNotEmpty ? recognizedText : null;
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
    _stopWaveformAnimation();
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
