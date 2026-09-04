import 'package:flutter/material.dart';
import '../models/milestone_stage.dart';
import 'grassy_mound_clipper.dart';

/// Scenic rounded card widget representing a single stage in the Mascot Journey Map.
/// Card dimensions: 130x160 px.
class MilestoneCard extends StatelessWidget {
  final MilestoneStage stage;
  final VoidCallback onTap;

  const MilestoneCard({
    super.key,
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: stage.isUnlocked ? onTap : () => _showLockedSnackBar(context),
      child: Container(
        width: 130,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: stage.isCurrent
                  ? const Color(0xFF2ECC71).withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.18),
              blurRadius: stage.isCurrent ? 18 : 12,
              spreadRadius: stage.isCurrent ? 3 : 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. TOP LAYER: Sky-to-mist vertical gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: stage.isUnlocked
                          ? [
                              const Color(0xFF81D4FA), // Vibrant sky blue
                              const Color(0xFFE0F7FA), // Soft mist cyan
                              const Color(0xFFE8F5E9), // Gentle plant mist
                            ]
                          : [
                              const Color(0xFFB0BEC5), // Muted sky grey
                              const Color(0xFFCFD8DC),
                              const Color(0xFFECEFF1),
                            ],
                    ),
                  ),
                ),
              ),

              // Sun / Cloud subtle scenic detail in background top
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 10,
                child: Container(
                  width: 32,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),

              // 2. BOTTOM LAYER: Organic grassy hill mound drawn using CustomClipper
              Positioned.fill(
                child: ClipPath(
                  clipper: GrassyMoundClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: stage.isUnlocked
                            ? [
                                const Color(0xFF2ECC71), // Vibrant grass green
                                const Color(0xFF27AE60), // Deep soil green
                              ]
                            : [
                                const Color(0xFF78909C), // Muted grass
                                const Color(0xFF546E7A),
                              ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. CENTER LAYER: Mascot/plant asset display with Icon fallback
              Positioned(
                top: 25,
                left: 0,
                right: 0,
                bottom: 25,
                child: Center(
                  child: Image.asset(
                    stage.assetPath,
                    width: 78,
                    height: 78,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to Icon if image asset fails or missing
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          stage.fallbackIcon,
                          size: 42,
                          color: stage.isUnlocked
                              ? const Color(0xFF27AE60)
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. OVERLAY TOP-RIGHT: Level Number Pill Badge (e.g., "#1", "#2")
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: stage.isCurrent
                        ? const Color(0xFFF1C40F) // Gold pill for active
                        : stage.isCompleted
                            ? const Color(0xFF2ECC71) // Green pill for completed
                            : const Color(0xFF455A64), // Muted dark for locked
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '#${stage.stageNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 5. COMPLETED BADGE (Top-left checkmark)
              if (stage.isCompleted)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),

              // 6. BOTTOM LABEL: Stage Title Banner
              Positioned(
                left: 6,
                right: 6,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    stage.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: stage.isUnlocked
                          ? const Color(0xFF1E8449)
                          : const Color(0xFF546E7A),
                    ),
                  ),
                ),
              ),

              // 7. LOCKED OVERLAY: Dark translucent overlay + Lock Icon when isUnlocked is false
              if (!stage.isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.65),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),

              // 8. ACTIVE CURRENT GLOW BORDER
              if (stage.isCurrent)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF1C40F),
                        width: 3.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete Stage #${stage.stageNumber - 1} to unlock ${stage.title}!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF34495E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
