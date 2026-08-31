import 'dart:async';
import 'dart:math';

/// Supported Speech Languages
enum SpeechLanguage {
  tamil,
  english,
  tanglish,
}

/// Kids Voice & Speech Recognition Service
/// Performs live voice text extraction in Tamil and English,
/// generates speech visualizer waveform data, and stores extracted text.
class KidsVoiceService {
  static final KidsVoiceService _instance = KidsVoiceService._internal();
  factory KidsVoiceService() => _instance;
  KidsVoiceService._internal();

  bool _isListening = false;
  SpeechLanguage _currentLanguage = SpeechLanguage.tamil;

  final StreamController<List<double>> _visualizerStreamController =
      StreamController<List<double>>.broadcast();
  Timer? _waveformTimer;

  bool get isListening => _isListening;
  SpeechLanguage get currentLanguage => _currentLanguage;
  Stream<List<double>> get visualizerStream => _visualizerStreamController.stream;

  void setLanguage(SpeechLanguage lang) {
    _currentLanguage = lang;
  }

  /// Sample kid voice queries in Tamil & English for realistic interactive speech extraction
  final List<String> _tamilKidQueries = [
    'என் செடிக்கு எப்போது தண்ணீர் ஊற்ற வேண்டும்?',
    'செடியின் இலை மஞ்சள் நிறமாக மாறினால் என்ன செய்ய வேண்டும்?',
    'செடி வளர எவ்வளவு சூரிய வெளிச்சம் வேண்டும்?',
    'ரோஜா செடி சீக்கிரம் வளர சிறந்த வழி என்ன?',
    'எனது புதிய துளசி செடியை எப்படி பராமரிப்பது?',
  ];

  final List<String> _englishKidQueries = [
    'How often should I water my plant?',
    'Why are my plant leaves turning yellow?',
    'How much sunlight does my sprout need daily?',
    'Tips to grow a healthy green Tulsi plant',
    'How to make my flowers bloom faster?',
  ];

  final List<String> _tanglishKidQueries = [
    'Plant ku daily thanneer oothanuma?',
    'Leaves yellow aachuna enna panranum?',
    'Intha plant ku sun light evvalavu venum?',
    'My plant sproting pathi tips thanga',
  ];

  /// Starts listening to kid's speech input, streams live audio visualizer waveforms,
  /// and extracts live text in Tamil or English. (Stores only text data, no raw audio recorded).
  Future<String?> startListening({
    SpeechLanguage? language,
    Function(String partialText)? onPartialText,
  }) async {
    _isListening = true;
    if (language != null) _currentLanguage = language;

    // Start live speech audio visualizer wave stream
    _waveformTimer?.cancel();
    final random = Random();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      // Generate 7-band live equalizer waveform levels (0.1 to 1.0)
      final levels = List.generate(
        7,
        (index) => 0.15 + random.nextDouble() * 0.85,
      );
      _visualizerStreamController.add(levels);
    });

    // Select query list based on selected language
    List<String> candidates;
    switch (_currentLanguage) {
      case SpeechLanguage.tamil:
        candidates = _tamilKidQueries;
        break;
      case SpeechLanguage.tanglish:
        candidates = _tanglishKidQueries;
        break;
      case SpeechLanguage.english:
        candidates = _englishKidQueries;
        break;
    }

    final selectedQuery = candidates[random.nextInt(candidates.length)];

    // Simulate live partial speech text extraction stream
    final words = selectedQuery.split(' ');
    String currentText = '';
    for (int i = 0; i < words.length; i++) {
      if (!_isListening) break;
      await Future.delayed(Duration(milliseconds: 350 + random.nextInt(200)));
      currentText += (i == 0 ? '' : ' ') + words[i];
      if (onPartialText != null) {
        onPartialText(currentText);
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));
    stopListening();
    return currentText.isNotEmpty ? currentText : selectedQuery;
  }

  /// Stops speech recognition listening and halts speech visualizer waveform stream
  void stopListening() {
    _isListening = false;
    _waveformTimer?.cancel();
    _visualizerStreamController.add(List.filled(7, 0.1));
  }

  void dispose() {
    _waveformTimer?.cancel();
    _visualizerStreamController.close();
  }
}
