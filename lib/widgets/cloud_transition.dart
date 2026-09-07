import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/skeuo_theme.dart';

/// Cartoon Cloud Transition Painter
/// Paints multi-layered, fluffy cumulus cartoon clouds that sweep and puff
/// across the screen to create a magical transition effect.
class CloudTransitionPainter extends CustomPainter {
  final double progress; // 0.0 (open) -> 1.0 (fully covered) -> 2.0 (parting away)
  final bool isReverse;

  CloudTransitionPainter({
    required this.progress,
    this.isReverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001) return;

    // effectiveCover: 0.0 = completely open, 1.0 = fully covered
    double effectiveCover;
    if (progress <= 1.0) {
      effectiveCover = Curves.easeOutCubic.transform(progress);
    } else {
      effectiveCover = 1.0 - Curves.easeInCubic.transform(progress - 1.0);
    }

    if (effectiveCover <= 0.001) return;

    final width = size.width;
    final height = size.height;

    // Background sky tint overlay to smoothly obscure background
    final backdropPaint = Paint()
      ..color = const Color(0xFFE8F6F3).withValues(alpha: (effectiveCover * 0.95).clamp(0.0, 0.95));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backdropPaint);

    // Layer 1: Backing Soft Sky/Mint Clouds
    final backPaint = Paint()
      ..color = const Color(0xFFD4EFDF).withValues(alpha: (effectiveCover * 0.9).clamp(0.0, 0.9))
      ..style = PaintingStyle.fill;

    // Layer 2: Main Fluffy White Skeuomorphic Clouds
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: (effectiveCover * 1.0).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    // Layer 3: Subtle Cloud Shadow for 3D depth
    final shadowPaint = Paint()
      ..color = const Color(0xFF1E8449).withValues(alpha: (effectiveCover * 0.12).clamp(0.0, 0.12))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final leftOffset = (1.0 - effectiveCover) * (width * 0.85);
    final rightOffset = (1.0 - effectiveCover) * (width * 0.85);
    final topOffset = (1.0 - effectiveCover) * (height * 0.6);
    final bottomOffset = (1.0 - effectiveCover) * (height * 0.6);

    // Draw Left Cloud Bank
    _drawCloudBank(
      canvas,
      shadowPaint,
      center: Offset(-leftOffset + width * 0.2, height * 0.4),
      baseRadius: width * 0.38,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      backPaint,
      center: Offset(-leftOffset + width * 0.2, height * 0.4),
      baseRadius: width * 0.36,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      whitePaint,
      center: Offset(-leftOffset + width * 0.25, height * 0.38),
      baseRadius: width * 0.34,
      spread: effectiveCover,
    );

    // Draw Right Cloud Bank
    _drawCloudBank(
      canvas,
      shadowPaint,
      center: Offset(width + rightOffset - width * 0.2, height * 0.65),
      baseRadius: width * 0.4,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      backPaint,
      center: Offset(width + rightOffset - width * 0.2, height * 0.65),
      baseRadius: width * 0.38,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      whitePaint,
      center: Offset(width + rightOffset - width * 0.24, height * 0.63),
      baseRadius: width * 0.35,
      spread: effectiveCover,
    );

    // Draw Top Cloud Swirl
    _drawCloudBank(
      canvas,
      backPaint,
      center: Offset(width * 0.5, -topOffset + height * 0.15),
      baseRadius: width * 0.42,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      whitePaint,
      center: Offset(width * 0.5, -topOffset + height * 0.12),
      baseRadius: width * 0.39,
      spread: effectiveCover,
    );

    // Draw Bottom Cloud Swirl
    _drawCloudBank(
      canvas,
      shadowPaint,
      center: Offset(width * 0.45, height + bottomOffset - height * 0.18),
      baseRadius: width * 0.46,
      spread: effectiveCover,
    );
    _drawCloudBank(
      canvas,
      whitePaint,
      center: Offset(width * 0.48, height + bottomOffset - height * 0.22),
      baseRadius: width * 0.44,
      spread: effectiveCover,
    );

    // Center Joining Puff when near 100% cover
    if (effectiveCover > 0.65) {
      final centerScale = (effectiveCover - 0.65) / 0.35;
      final centerRadius = (width * 0.45) * centerScale;
      canvas.drawCircle(Offset(width * 0.5, height * 0.5), centerRadius, whitePaint);
      canvas.drawCircle(Offset(width * 0.35, height * 0.52), centerRadius * 0.85, whitePaint);
      canvas.drawCircle(Offset(width * 0.65, height * 0.48), centerRadius * 0.85, whitePaint);
    }
  }

  void _drawCloudBank(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double baseRadius,
    required double spread,
  }) {
    // Cluster of overlapping fluffy circles
    final r = baseRadius * (0.8 + 0.2 * spread);
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(Offset(center.dx - r * 0.55, center.dy + r * 0.15), r * 0.75, paint);
    canvas.drawCircle(Offset(center.dx + r * 0.55, center.dy - r * 0.1), r * 0.78, paint);
    canvas.drawCircle(Offset(center.dx - r * 0.2, center.dy - r * 0.45), r * 0.68, paint);
    canvas.drawCircle(Offset(center.dx + r * 0.25, center.dy + r * 0.4), r * 0.65, paint);
  }

  @override
  bool shouldRepaint(covariant CloudTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A PageRoute that navigates between screens with an animated cartoon cloud transition
class CloudPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String? statusMessage;

  CloudPageRoute({
    required this.child,
    this.statusMessage = '🌱 Exploring Flora...',
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 950),
          reverseTransitionDuration: const Duration(milliseconds: 850),
          transitionsBuilder: (context, animation, secondaryAnimation, pageWidget) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                // Animation value runs 0.0 -> 1.0.
                // Map to progress 0.0 -> 2.0:
                // 0.0 -> 0.48: clouds close in (progress 0 -> 1)
                // 0.48 -> 0.52: fully closed (progress = 1.0)
                // 0.52 -> 1.0: clouds part open (progress 1 -> 2)
                final t = animation.value;
                double cloudProgress;
                if (t <= 0.48) {
                  cloudProgress = (t / 0.48).clamp(0.0, 1.0);
                } else if (t <= 0.52) {
                  cloudProgress = 1.0;
                } else {
                  cloudProgress = 1.0 + ((t - 0.52) / 0.48).clamp(0.0, 1.0);
                }

                // Show child once clouds have sufficiently closed
                final showChild = t >= 0.48;

                return Stack(
                  children: [
                    if (showChild) pageWidget,
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: t > 0.85,
                        child: CustomPaint(
                          painter: CloudTransitionPainter(progress: cloudProgress),
                        ),
                      ),
                    ),
                    if (cloudProgress >= 0.85 && cloudProgress <= 1.25 && statusMessage != null)
                      Positioned.fill(
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: _CloudStatusPill(message: statusMessage),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
}

/// Playful Status Badge shown during full cloud cover
class _CloudStatusPill extends StatelessWidget {
  final String message;

  const _CloudStatusPill({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF81C784), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: SkeuoTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static helper overlay to run any asynchronous task (e.g. plant save, watering analysis)
/// with a cartoon cloud transition.
class CloudTransitionOverlay {
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String message = '🌱 Processing Flora...',
  }) async {
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    final controller = AnimationController(
      vsync: overlayState,
      duration: const Duration(milliseconds: 400),
    );

    overlayEntry = OverlayEntry(
      builder: (ctx) => AnimatedBuilder(
        animation: controller,
        builder: (ctx, _) {
          final progress = controller.value;
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CloudTransitionPainter(progress: progress),
                  ),
                ),
                if (progress >= 0.7)
                  Positioned.fill(
                    child: Center(
                      child: _CloudStatusPill(message: message),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    overlayState.insert(overlayEntry);

    try {
      // 1. Close clouds in
      await controller.forward();

      // 2. Perform background task while covered in clouds
      final startTime = DateTime.now();
      final result = await task();
      final elapsed = DateTime.now().difference(startTime);

      // Ensure clouds stay visible for at least 350ms for delightful visual feeling
      if (elapsed < const Duration(milliseconds: 350)) {
        await Future.delayed(const Duration(milliseconds: 350) - elapsed);
      }

      // 3. Part clouds out
      await controller.reverse();

      return result;
    } finally {
      controller.dispose();
      overlayEntry.remove();
    }
  }
}
