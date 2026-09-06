import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/widget_sync_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';

class WidgetGuideScreen extends StatelessWidget {
  const WidgetGuideScreen({super.key});

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
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Live Widget Preview Card
                        _buildWidgetPreviewCard(),
                        const SizedBox(height: 24),

                        // Installation Instructions Steps Card
                        _buildInstructionsCard(),
                        const SizedBox(height: 24),

                        // Action Button: Force Sync
                        SizedBox(
                          width: double.infinity,
                          child: FunBouncyButton(
                            text: '🔄 Sync Widget Data Now',
                            onPressed: () async {
                              await WidgetSyncService().updateWidgetData();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '✅ Home screen widget data synced with latest plant status!'),
                                  backgroundColor: SkeuoTheme.primaryGreen,
                                ),
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

  Widget _buildAppBar(BuildContext context) {
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
            'Home Screen Widget',
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

  Widget _buildWidgetPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E8449),
            Color(0xFF2ECC71),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'LIVE WIDGET PREVIEW',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mock Widget Container
          Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    'assets/sprites/mascot_pot_happy.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF4CAF50),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SpryFlora Garden',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '🌱 100% Healthy',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        '💧 All plants watered',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: SkeuoTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Add SpryFlora Widget',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildStepRow(
            stepNumber: '1',
            title: 'Go to Phone Home Screen',
            description:
                'Touch and hold an empty space on your phone\'s home screen until apps jiggle or settings appear.',
          ),
          const Divider(height: 20, color: Color(0xFFF1F8EE)),
          _buildStepRow(
            stepNumber: '2',
            title: 'Tap "+ Widgets" or "Widgets"',
            description:
                'Search for "SpryFlora" in the widget library list.',
          ),
          const Divider(height: 20, color: Color(0xFFF1F8EE)),
          _buildStepRow(
            stepNumber: '3',
            title: 'Drag SpryFlora Widget to Screen',
            description:
                'Choose the SpryFlora Garden Care Widget and place it on your home screen.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
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
    );
  }
}
