import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import '../services/ai_service.dart';
import 'speech_visualizer.dart';

/// Skeuomorphic Flora AI Plant Doctor Modal Sheet
class FloraAISheet extends StatefulWidget {
  final PlantModel plant;
  final List<DailyCheckinModel> history;

  const FloraAISheet({
    super.key,
    required this.plant,
    this.history = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required PlantModel plant,
    List<DailyCheckinModel> history = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FloraAISheet(plant: plant, history: history),
    );
  }

  @override
  State<FloraAISheet> createState() => _FloraAISheetState();
}

class _FloraAISheetState extends State<FloraAISheet> {
  final AIService _aiService = AIService();
  final TextEditingController _questionCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '☀️ How much sunlight is best?',
    '💧 Check my watering schedule',
    '🍃 What if leaves turn yellow?',
    '🌱 Tips for this growth stage',
    '🩺 Diagnose overall health',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialGuidance();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialGuidance() async {
    setState(() => _isLoading = true);
    final guidance = await _aiService.getStageCareGuidance(widget.plant);
    if (mounted) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': guidance,
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _askQuestion(String question) async {
    final cleanQ = question.trim();
    if (cleanQ.isEmpty) return;

    _questionCtrl.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': cleanQ});
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await _aiService.askFloraAI(
      plant: widget.plant,
      userQuestion: cleanQ,
      history: widget.history,
    );

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Flora AI Doctor',
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'AI ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Botanical mentor for ${widget.plant.plantName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Diagnostic Snapshot Pill Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD6E4DB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricPill('🌱 Stage', widget.plant.growthStageName, Colors.teal),
                _buildMetricPill('🩺 Health', '${widget.plant.health}%', Colors.green),
                _buildMetricPill('💧 Water', '${widget.plant.hydrationScore}%', Colors.blue),
                _buildMetricPill('☀️ Sun', '${widget.plant.sunlightScore}%', Colors.orange),
              ],
            ),
          ),

          const Divider(height: 1),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }

                final msg = _messages[index];
                final isAi = msg['sender'] == 'ai';
                return _buildChatBubble(msg['text'] ?? '', isAi);
              },
            ),
          ),

          // Suggested Prompts Carousel
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  side: BorderSide(color: Colors.green.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _askQuestion(prompt),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Kids Voice Recognition Mic Button
                  GestureDetector(
                    onTap: () {
                      SpeechVisualizerWidget.show(
                        context,
                        onSpeechExtracted: (extractedText) {
                          _askQuestion(extractedText);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD6E4DB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _questionCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _askQuestion,
                        decoration: const InputDecoration(
                          hintText: 'Type or speak in தமிழ் / English...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _askQuestion(_questionCtrl.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) ...[
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Icon(Icons.psychology_alt_rounded, size: 16, color: Color(0xFF2E7D32)),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAi ? Colors.white : const Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAi ? 4 : 20),
                  bottomRight: Radius.circular(isAi ? 20 : 4),
                ),
                border: isAi ? Border.all(color: const Color(0xFFDDE8E0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isAi ? const Color(0xFF1B3B2B) : Colors.white,
                  fontWeight: isAi ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Icon(Icons.psychology_alt_rounded, size: 16, color: Color(0xFF2E7D32)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDE8E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 10),
                Text(
                  'Flora AI is thinking...',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
