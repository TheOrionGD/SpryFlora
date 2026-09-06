import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'ai_eco_buddy_screen.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I know when my plant needs water?',
      answer:
          'SpryFlora automatically calculates watering schedules based on plant species, pot size, and humidity. Check your Main Dashboard or My Plants screen for watering alerts marked "💧 Now!"',
    ),
    _FaqItem(
      question: 'What is the Mascot Companion?',
      answer:
          'Your mascot sprout grows as you take good care of real plants! Every time you water plants or log daily check-ins, your mascot gains XP and levels up.',
    ),
    _FaqItem(
      question: 'How do AI Leaf Scanning & Disease AI work?',
      answer:
          'Take a photo of any leaf using the camera button. SpryFlora\'s AI vision model identifies the species and detects diseases, bugs, or yellowing leaves.',
    ),
    _FaqItem(
      question: 'How do I earn Master Planter Certificates?',
      answer:
          'Keep your plants healthy and complete daily quests! Once you reach care milestones, certificates unlock automatically in the My Certifications section.',
    ),
    _FaqItem(
      question: 'Can I use SpryFlora offline?',
      answer:
          'Yes! All your plant logs, watering reminders, and local data are stored on your device and sync when you re-connect.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Help Banner Card
                        _buildHelpBannerCard(),
                        const SizedBox(height: 24),

                        // FAQ Header
                        Text(
                          'Frequently Asked Questions',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // FAQ List
                        ..._faqs.map((faq) => _buildFaqTile(faq)),

                        const SizedBox(height: 24),

                        // Ask AI Eco Buddy CTA
                        SizedBox(
                          width: double.infinity,
                          child: FunBouncyButton(
                            text: '🌿 Ask AI Eco Buddy 🎙️',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const AIEcoBuddyScreen()),
                              );
                            },
                            color: const Color(0xFF2E7D32),
                            height: 50,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: SkeuoTheme.textPrimary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Help & Botanical Support',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: SkeuoTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpBannerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contact_support_rounded,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help Growing Plants?',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                Text(
                  'Explore answers below or ask our 24/7 AI Eco-Buddy assistant!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: GoogleFonts.nunito(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
            ),
          ),
          iconColor: const Color(0xFF2E7D32),
          collapsedIconColor: SkeuoTheme.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq.answer,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: SkeuoTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
