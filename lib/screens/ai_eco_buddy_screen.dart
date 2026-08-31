import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/speech_visualizer.dart';

/// Screen 15: AI Eco Buddy Chat (from 255.jpg)
/// - Top Bar: Back button + "AI Eco Buddy"
/// - Mascot Avatar & Natural Conversation Flow
/// - Preloaded with sample conversation:
///   * Buddy: "Hello! I'm your Eco Buddy 🌱 Ask me anything about plants."
///   * User: "Why are my leaves yellow?"
///   * Buddy: "Yellow leaves can be caused by overwatering, underwatering, or lack of sunlight."
/// - Text Field: "Type a message..." with green send button
class AIEcoBuddyScreen extends StatefulWidget {
  final PlantModel? initialPlant;

  const AIEcoBuddyScreen({
    super.key,
    this.initialPlant,
  });

  @override
  State<AIEcoBuddyScreen> createState() => _AIEcoBuddyScreenState();
}

class _AIEcoBuddyScreenState extends State<AIEcoBuddyScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AIService _aiService = AIService();
  final PlantRepository _plantRepo = PlantRepository();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'buddy',
      'text': "Hello! I'm your Eco Buddy 🌱\nAsk me anything about plants.",
      'time': 'Just now',
    },
    {
      'sender': 'user',
      'text': "Why are my leaves yellow?",
      'time': 'Just now',
    },
    {
      'sender': 'buddy',
      'text':
          "Yellow leaves can be caused by overwatering, underwatering, or lack of sunlight.",
      'time': 'Just now',
    },
  ];

  bool _isTyping = false;

  final List<String> _quickQuestions = [
    'How often should I water?',
    'Best sunlight for indoor plants?',
    'How to prevent root rot?',
    'When will my plant blossom?',
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _messageCtrl.clear();
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': clean,
        'time': 'Just now',
      });
      _isTyping = true;
    });

    _scrollToBottom();

    final plant = widget.initialPlant ??
        (_plantRepo.plants.isNotEmpty ? _plantRepo.plants.first : null);

    final reply = await _aiService.askFloraAI(
      plant: plant,
      userQuestion: clean,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'buddy',
          'text': reply,
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkeuoTheme.background,
      appBar: AppBar(
        backgroundColor: SkeuoTheme.background,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: SkeuoTheme.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/sprites/mascot_pot_happy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.eco_rounded,
                    size: 20,
                    color: SkeuoTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Eco Buddy',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Quick Suggestions Bar ─────────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = _quickQuestions[index];
                return GestureDetector(
                  onTap: () => _sendMessage(q),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC8E6C9),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        q,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE8F5E9)),

          // ── Chat Messages ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return _buildMessageBubble(
                  text: msg['text'] as String,
                  isUser: isUser,
                );
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Eco Buddy is thinking...',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Message Input Bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  // Voice Input Mic Button for Kids (Tamil & English Speech Extraction)
                  GestureDetector(
                    onTap: () {
                      SpeechVisualizerWidget.show(
                        context,
                        onSpeechExtracted: (extractedText) {
                          _sendMessage(extractedText);
                        },
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFDCEDC8),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _messageCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type or speak in தமிழ் / English...',
                          hintStyle: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFFA5D6A7),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageCtrl.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
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
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : const Color(0xFF1B5E20),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
