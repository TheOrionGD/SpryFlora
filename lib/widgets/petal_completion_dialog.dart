import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import 'fun_bouncy_button.dart';
import 'fun_confetti_overlay.dart';

/// Interactive Petal Completion Challenge Dialog (Section 37)
/// When a plant reaches completion/maturity, the child can spin/tap petals to collect seeds,
/// earn rewards, mark plant completed, and view their personalized certificate.
class PetalCompletionDialog extends StatefulWidget {
  final PlantModel plant;
  final VoidCallback onComplete;

  const PetalCompletionDialog({
    super.key,
    required this.plant,
    required this.onComplete,
  });

  @override
  State<PetalCompletionDialog> createState() => _PetalCompletionDialogState();
}

class _PetalCompletionDialogState extends State<PetalCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  final List<bool> _pluckedPetals = List.filled(6, false);
  int _pluckedCount = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _pluckPetal(int index) {
    if (_pluckedPetals[index]) return;
    setState(() {
      _pluckedPetals[index] = true;
      _pluckedCount++;
      if (_pluckedCount >= 6) {
        _isFinished = true;
      }
    });
  }

  Future<void> _claimCompletionReward() async {
    final plantRepo = PlantRepository();
    final userService = UserService();

    await plantRepo.markPlantCompleted(widget.plant.id);
    await userService.incrementCompletedPlants();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: SkeuoTheme.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    '🌸 Petal Harvest Challenge! 🌸',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFinished
                        ? '🎉 Amazing job! You harvested all 6 magic seeds!'
                        : 'Tap each flower petal to collect magic seeds for your garden! (${6 - _pluckedCount} left)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF558B2F),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Flower Petal Wheel
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _spinCtrl,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _spinCtrl.value * 2 * math.pi,
                              child: Stack(
                                alignment: Alignment.center,
                                children: List.generate(6, (index) {
                                  final angle = (index * 60) * (math.pi / 180);
                                  final isPlucked = _pluckedPetals[index];

                                  return Transform.translate(
                                    offset: Offset(
                                      65 * math.cos(angle),
                                      65 * math.sin(angle),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _pluckPetal(index),
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 300),
                                        scale: isPlucked ? 0.4 : 1.0,
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isPlucked
                                                ? const Color(0xFFFFD54F)
                                                : const Color(0xFFFF80AB),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.pink.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              isPlucked ? '✨' : '🌸',
                                              style: const TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),

                        // Center Flower Bud
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB300),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _isFinished ? '🏆' : '🌱',
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Claim Reward Button
                  if (_isFinished) ...[
                    FunBouncyButton(
                      text: 'Claim Certificate & Rewards! 🏅',
                      onPressed: _claimCompletionReward,
                      color: const Color(0xFF4CAF50),
                      textColor: Colors.white,
                      height: 54,
                      fontSize: 16,
                    ),
                  ] else ...[
                    Text(
                      'Tap all 6 petals to finish! ✨',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Confetti overlay on completion
          if (_isFinished)
            Positioned.fill(
              child: FunConfettiOverlay(
                isActive: _isFinished,
                child: const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
