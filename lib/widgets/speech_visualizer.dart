import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/kids_voice_service.dart';
import '../theme/skeuo_theme.dart';

/// Interactive Speech Visualizer & Kids Voice Extraction Modal / Widget
class SpeechVisualizerWidget extends StatefulWidget {
  final Function(String extractedText) onSpeechExtracted;
  final SpeechLanguage initialLanguage;

  const SpeechVisualizerWidget({
    super.key,
    required this.onSpeechExtracted,
    this.initialLanguage = SpeechLanguage.tamil,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String extractedText) onSpeechExtracted,
    SpeechLanguage initialLanguage = SpeechLanguage.tamil,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SpeechVisualizerWidget(
          onSpeechExtracted: onSpeechExtracted,
          initialLanguage: initialLanguage,
        ),
      ),
    );
  }

  @override
  State<SpeechVisualizerWidget> createState() => _SpeechVisualizerWidgetState();
}

class _SpeechVisualizerWidgetState extends State<SpeechVisualizerWidget>
    with SingleTickerProviderStateMixin {
  final KidsVoiceService _voiceService = KidsVoiceService();
  late SpeechLanguage _selectedLanguage;
  bool _isListening = false;
  String _extractedText = '';
  String _statusMessage = 'Listening... Speak into your microphone';
  late AnimationController _pulseCtrl;
  final TextEditingController _textController = TextEditingController();

  List<String> get _quickPrompts {
    switch (_selectedLanguage) {
      case SpeechLanguage.tamil:
        return const [
          '💧 என் செடிக்கு எப்போது தண்ணீர் ஊற்ற வேண்டும்?',
          '☀️ இதற்கு எவ்வளவு சூரிய வெளிச்சம் தேவை?',
          '🍂 இலைகள் ஏன் மஞ்சள் நிறமாக மாறுகின்றன?',
          '🌱 என் செடி ஆரோக்கியமாக வளர்கிறதா?',
          '🐛 பூச்சிகளிலிருந்து செடியை எப்படி பாதுகாப்பது?',
        ];
      case SpeechLanguage.tanglish:
        return const [
          '💧 Plant-ku eppo thanneer oothanum?',
          '☀️ Ivlo sunlight pothuma?',
          '🍂 Leaves yen manjala maaruthu?',
          '🌱 Plant nalla aarokkiyama irukka?',
          '🐛 Insects varama eppadi paathukardhu?',
        ];
      case SpeechLanguage.english:
        return const [
          '💧 How often should I water my plant?',
          '☀️ How much sunlight does it need?',
          '🍂 Why are the leaves turning yellow?',
          '🌱 Is my plant healthy and growing well?',
          '🐛 How do I protect it from bugs or pests?',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startListeningSession();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListeningSession() async {
    setState(() {
      _isListening = true;
      _statusMessage = 'Listening... Speak in ${_getLanguageName(_selectedLanguage)}';
    });

    final extracted = await _voiceService.startListening(
      language: _selectedLanguage,
      onPartialText: (partial) {
        if (mounted) {
          setState(() {
            _extractedText = partial;
            _textController.text = partial;
            _statusMessage = 'Transcribing live voice...';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isListening = false;
        if (extracted != null && extracted.isNotEmpty) {
          _extractedText = extracted;
          _textController.text = extracted;
          _statusMessage = 'Speech captured! Tap Use Extracted Text below:';
        } else if (_textController.text.trim().isNotEmpty) {
          _statusMessage = 'Voice text ready';
        } else {
          _statusMessage = 'Tap mic to speak, select a question, or type below:';
        }
      });
    }
  }

  String _getLanguageName(SpeechLanguage lang) {
    switch (lang) {
      case SpeechLanguage.tamil:
        return 'தமிழ் (Tamil)';
      case SpeechLanguage.english:
        return 'English';
      case SpeechLanguage.tanglish:
        return 'Tanglish';
    }
  }

  void _confirmExtractedText() {
    final textToUse = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : _extractedText.trim();

    if (textToUse.isNotEmpty &&
        !textToUse.startsWith('Listening...') &&
        !textToUse.startsWith('Speak into')) {
      widget.onSpeechExtracted(textToUse);
      Navigator.of(context).pop();
    }
  }

  void _selectQuickPrompt(String prompt) {
    final cleanPrompt = prompt.replaceFirst(RegExp(r'^[^\w\s\u0B80-\u0BFF]+\s*'), '');
    setState(() {
      _extractedText = cleanPrompt;
      _textController.text = cleanPrompt;
      _statusMessage = 'Quick question selected! Ready to submit.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header & Language Selector Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎙️ ', style: TextStyle(fontSize: 20)),
                  Text(
                    'Kids Voice Recognition',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Language Choice Chips (Tamil / English / Tanglish)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: SpeechLanguage.values.map((lang) {
              final isSelected = _selectedLanguage == lang;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    _getLanguageName(lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: SkeuoTheme.primaryGreen,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                      _startListeningSession();
                    }
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Live Speech Waveform Equalizer Visualizer ─────────────────────
          StreamBuilder<List<double>>(
            stream: _voiceService.visualizerStream,
            initialData: List.filled(7, 0.2),
            builder: (context, snapshot) {
              final levels = snapshot.data ?? List.filled(7, 0.2);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (index) {
                  final height = 15.0 + (levels[index] * 45.0);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 8,
                    height: height,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Quick Voice Question Chips ──────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Questions:',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF81C784),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return GestureDetector(
                  onTap: () => _selectQuickPrompt(prompt),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        prompt,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Extracted Live Text Display Box (Editable) ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? const Color(0xFF00E676).withValues(alpha: 0.6)
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isListening
                          ? Icons.record_voice_over_rounded
                          : Icons.text_snippet_rounded,
                      size: 16,
                      color: const Color(0xFF81C784),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF81C784),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 2,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Speak or type your plant question here...',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _extractedText = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Controls: Mic Retake & Confirm Extracted Text Button
          Row(
            children: [
              // Retake Speech Button
              GestureDetector(
                onTap: _startListeningSession,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Icon(
                        _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: _isListening
                            ? const Color(0xFF00E676)
                            : Colors.white,
                        size: 26,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Confirm Extracted Text Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmExtractedText,
                  icon: const Icon(Icons.check_rounded, size: 22),
                  label: Text(
                    'Use Extracted Text',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SkeuoTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
