import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import 'fun_bouncy_button.dart';
import 'fun_confetti_overlay.dart';

/// Interactive Petal Completion Challenge Dialog
/// When a plant reaches completion or harvest stage, children tap petals to collect magic seeds,
/// earn rewards, complete the botanical journey, and view their personalized certificate.
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
  bool _isSubmitting = false;
  String? _lastFeedbackText;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _pluckPetal(int index) {
    if (_pluckedPetals[index] || _isSubmitting) return;

    HapticFeedback.lightImpact();

    setState(() {
      _pluckedPetals[index] = true;
      _pluckedCount++;
      _lastFeedbackText = '+30 XP Magic Seed! ✨';
      if (_pluckedCount >= 6) {
        _isFinished = true;
        _spinCtrl.stop();
        _lastFeedbackText = '🎉 All 6 Petals Harvested!';
      }
    });
  }

  void _harvestAllPetals() {
    if (_isFinished || _isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      for (int i = 0; i < 6; i++) {
        _pluckedPetals[i] = true;
      }
      _pluckedCount = 6;
      _isFinished = true;
      _spinCtrl.stop();
      _lastFeedbackText = '🎉 All Petals Harvested!';
    });
  }

  Future<void> _claimCompletionReward() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final plantRepo = PlantRepository();
      final userService = UserService();

      await plantRepo.markPlantCompleted(widget.plant.id);
      await userService.incrementCompletedPlants();
    } catch (e) {
      debugPrint('Error completing plant reward: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).maybePop();
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 220.0;
    const double radius = 68.0;
    const double petalSize = 52.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
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
                  // Title Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Text(
                      '🌸 Petal Harvest Challenge! 🌸',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Plant Name & Subtitle
                  Text(
                    widget.plant.plantName.isNotEmpty
                        ? widget.plant.plantName
                        : widget.plant.speciesName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    _isFinished
                        ? '🎉 Incredible job! All 6 magic seeds are harvested!'
                        : 'Tap all 6 glowing flower petals to collect your seeds!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF558B2F),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar & Counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCEDC8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seeds: $_pluckedCount / 6',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF33691E),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(6, (i) {
                            final plucked = _pluckedPetals[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: Text(
                                plucked ? '⭐' : '⚪',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Flower Petal Wheel
                  SizedBox(
                    height: wheelSize,
                    width: wheelSize,
                    child: AnimatedBuilder(
                      animation: _spinCtrl,
                      builder: (context, _) {
                        final rotationAngle =
                            _spinCtrl.value * 2 * math.pi;

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Soft Outer Flower Glow
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFF3E0)
                                    .withValues(alpha: 0.6),
                                border: Border.all(
                                  color: const Color(0xFFFFE082),
                                  width: 2,
                                ),
                              ),
                            ),

                            // Center Flower Core (Interactive)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (!_isFinished) {
                                  final nextIdx =
                                      _pluckedPetals.indexOf(false);
                                  if (nextIdx != -1) {
                                    _pluckPetal(nextIdx);
                                  }
                                }
                              },
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isFinished
                                        ? [
                                            const Color(0xFFFFD54F),
                                            const Color(0xFFFF8F00)
                                          ]
                                        : [
                                            const Color(0xFFFFCA28),
                                            const Color(0xFFFFA000)
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.amber.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isFinished ? '🏆' : '🌱',
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      if (!_isFinished)
                                        Text(
                                          '${6 - _pluckedCount} left',
                                          style: GoogleFonts.nunito(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF4E342E),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 6 Explicitly Positioned Petals with Exact Hit Areas
                            ...List.generate(6, (index) {
                              final baseAngle =
                                  (index * 60) * (math.pi / 180);
                              final currentAngle =
                                  baseAngle + rotationAngle;
                              final isPlucked = _pluckedPetals[index];

                              // Layout coordinates centered at wheelSize / 2
                              final double centerX =
                                  (wheelSize / 2) +
                                      radius * math.cos(currentAngle);
                              final double centerY =
                                  (wheelSize / 2) +
                                      radius * math.sin(currentAngle);

                              return Positioned(
                                left: centerX - (petalSize / 2),
                                top: centerY - (petalSize / 2),
                                width: petalSize,
                                height: petalSize,
                                child: GestureDetector(
                                  key: ValueKey('petal_button_$index'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _pluckPetal(index),
                                  child: AnimatedScale(
                                    duration: const Duration(
                                        milliseconds: 250),
                                    curve: Curves.elasticOut,
                                    scale: isPlucked ? 0.85 : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPlucked
                                              ? [
                                                  const Color(0xFFFFE082),
                                                  const Color(0xFFFFB300),
                                                ]
                                              : [
                                                  const Color(0xFFFF80AB),
                                                  const Color(0xFFE91E63),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isPlucked
                                                    ? Colors.amber
                                                    : Colors.pink)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          isPlucked ? '✨' : '🌸',
                                          style: const TextStyle(
                                              fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),

                  if (_lastFeedbackText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lastFeedbackText!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isFinished
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE91E63),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Claim Reward or Quick Harvest Action
                  if (_isFinished) ...[
                    FunBouncyButton(
                      text: _isSubmitting
                          ? 'Unlocking Certificate...'
                          : 'Claim Certificate & Rewards! 🏅',
                      onPressed: _claimCompletionReward,
                      color: const Color(0xFF4CAF50),
                      textColor: Colors.white,
                      height: 50,
                      fontSize: 15,
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('harvest_all_button'),
                          onPressed: _harvestAllPetals,
                          icon: const Text('🪄',
                              style: TextStyle(fontSize: 15)),
                          label: Text(
                            'Harvest All Petals',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00897B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Non-blocking Confetti Overlay on completion
          if (_isFinished)
            Positioned.fill(
              child: IgnorePointer(
                child: FunConfettiOverlay(
                  isActive: _isFinished,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
