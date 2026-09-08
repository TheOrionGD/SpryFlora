import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/speech_visualizer.dart';
import '../widgets/app_background.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';
import 'garden_screen.dart';
import 'profile_settings_screen.dart';
import 'realtime_plant_scanner_screen.dart';
import 'virtual_garden_screen.dart';

/// Screen: AI Eco Buddy Chat
/// - Mascot Avatar & Dynamic User-Specific Conversation Flow
/// - Directly references user's real profile and database plants
/// - Provides contextual action buttons (+ Add Plant, Virtual View, Water Now)
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
  final UserService _userService = UserService();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _plantRepo.loadLocalData();
    _userService.loadUserData();
    _initInitialGreeting();
  }

  void _initInitialGreeting() {
    final plants = _plantRepo.plants;

    String greeting;
    if (plants.isEmpty) {
      greeting = "Hello! I'm your Eco Buddy 🌱\n\nYou don't have any plants added to your garden yet. Tap the '+ Add Plant' button below to scan and add your first plant!";
    } else {
      final plantNames = plants.map((p) => p.plantName).take(3).join(', ');
      greeting = "Hello! I'm your Eco Buddy 🌱\n\nI'm watching over your plants ($plantNames). Ask me anything about watering, sunlight, or overall garden health!";
    }

    _messages.add({
      'sender': 'buddy',
      'text': greeting,
      'time': 'Just now',
      'showActions': plants.isEmpty,
    });
  }

  List<String> get _quickQuestions {
    final plants = _plantRepo.plants;
    if (plants.isEmpty) {
      return [
        'How do I add a plant?',
        'Best beginner plants for kids?',
        'What is the Botanical Sanctuary?',
        'Why do plants need sunlight?',
      ];
    }
    final first = plants.first;
    return [
      'How is ${first.plantName} doing?',
      'When should I water ${first.plantName}?',
      'Sunlight needs for ${first.speciesName}?',
      'Give me a tip for my garden!',
    ];
  }

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
          'showActions': _plantRepo.plants.isEmpty,
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plants = _plantRepo.plants;
    final duePlants = plants.where((p) => p.isWateringDue).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
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
                  errorBuilder: (_, __, ___) => const Icon(
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
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: Column(
            children: [
              // ── Quick Suggestions Bar ──
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

              // ── Chat Messages ──
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    final showActions = msg['showActions'] == true;

                    return _buildMessageBubble(
                      text: msg['text'] as String,
                      isUser: isUser,
                      showAddPlantAction: showActions,
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

              // ── Persistent Action Buttons Dock ──
              _buildActionDock(plants: plants, duePlantsCount: duePlants.length),

              // ── Message Input Bar ──
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
                  child: Row(
                    children: [
                      // Voice Input Mic Button for Kids
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
                              color: const Color(0xFFC8E6C9),
                              width: 1.2,
                            ),
                          ),
                          child: TextField(
                            controller: _messageCtrl,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SkeuoTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask Eco-Buddy anything...',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 13,
                                color: SkeuoTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(_messageCtrl.text),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyPlantsScreen()),
              );
              break;
            case 3:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GardenScreen()),
              );
              break;
            case 4:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  /// Action Dock directly providing shortcut buttons to Add Plant, View Garden, etc.
  Widget _buildActionDock({required List<PlantModel> plants, required int duePlantsCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Colors.white.withValues(alpha: 0.95),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
                );
                if (added == true) {
                  _plantRepo.loadLocalData();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
              label: Text(
                'Add Plant',
                style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(color: Color(0xFFA5D6A7), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VirtualGardenScreen()),
                );
              },
              icon: const Text('🏝️', style: TextStyle(fontSize: 14)),
              label: Text(
                'Virtual Sanctuary',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(color: Color(0xFFA5D6A7), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GardenScreen()),
                );
              },
              icon: const Text('🌻', style: TextStyle(fontSize: 14)),
              label: Text(
                'My Garden',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    bool showAddPlantAction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/sprites/mascot_pot_happy.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        size: 18,
                        color: SkeuoTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF2E7D32)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE0E8D8), width: 1.2),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isUser ? Colors.white : SkeuoTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showAddPlantAction && !isUser) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: const Color(0xFF2E4032),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                ),
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
                  );
                  if (added == true) {
                    _plantRepo.loadLocalData();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                label: Text(
                  '🌱 Scan & Add Plant Now',
                  style: GoogleFonts.fredoka(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
