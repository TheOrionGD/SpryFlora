import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom cloud transition overlay that sweeps animated fluffy clouds
/// across the screen to create a seamless, magical cloud transition between screens & stages.
///
/// Can be used either:
/// 1) Declaratively with [animationValue] (e.g. driven by external AnimationController).
/// 2) Imperatively via `CloudTransitionOverlay.of(context)?.triggerTransition(onCovered: ...)`.
class CloudTransitionOverlay extends StatefulWidget {
  final double? animationValue;
  final Widget child;

  const CloudTransitionOverlay({
    super.key,
    this.animationValue,
    required this.child,
  });

  static CloudTransitionOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<CloudTransitionOverlayState>();
  }

  @override
  State<CloudTransitionOverlay> createState() => CloudTransitionOverlayState();
}

class CloudTransitionOverlayState extends State<CloudTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _internalAnimCtrl;

  @override
  void initState() {
    super.initState();
    _internalAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _internalAnimCtrl.dispose();
    super.dispose();
  }

  /// Triggers a cloud transition sweep. Invokes [onCovered] at peak cloud cover (400ms mark).
  void triggerTransition({VoidCallback? onCovered}) {
    _internalAnimCtrl.forward(from: 0.0);

    Timer(const Duration(milliseconds: 400), () {
      if (mounted && onCovered != null) {
        onCovered();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _internalAnimCtrl,
      builder: (context, _) {
        final val = widget.animationValue ?? _internalAnimCtrl.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (val > 0.0 && val < 1.0)
              IgnorePointer(
                child: CustomPaint(
                  painter: _CloudTransitionPainter(progress: val),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CloudTransitionPainter extends CustomPainter {
  final double progress;

  _CloudTransitionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Envelope: 0.0 -> 0.5 (climbing to 1.0 coverage) -> 1.0 (dropping back to 0.0)
    final coverage = math.sin(progress * math.pi);
    if (coverage <= 0.01) return;

    final w = size.width;
    final h = size.height;

    // 1. Semi-transparent misty background wash
    final mistPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: coverage * 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), mistPaint);

    // 2. Multi-layered cloud puffs sweeping from edges to center
    _drawCloudLayer(
      canvas: canvas,
      size: size,
      coverage: coverage,
      cloudColor: const Color(0xFFFFFFFF).withValues(alpha: coverage * 0.95),
      speedFactor: 1.0,
    );

    _drawCloudLayer(
      canvas: canvas,
      size: size,
      coverage: coverage,
      cloudColor: const Color(0xFFB2EBF2).withValues(alpha: coverage * 0.65),
      speedFactor: 0.75,
    );

    _drawCloudLayer(
      canvas: canvas,
      size: size,
      coverage: coverage,
      cloudColor: const Color(0xFFE8F5E9).withValues(alpha: coverage * 0.75),
      speedFactor: 1.25,
    );
  }

  void _drawCloudLayer({
    required Canvas canvas,
    required Size size,
    required double coverage,
    required Color cloudColor,
    required double speedFactor,
  }) {
    final paint = Paint()..color = cloudColor;
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Top cloud wave
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.5 * coverage);

    // Fluffy cloud arcs across width
    final puffs = 6;
    final step = w / puffs;

    for (int i = puffs; i >= 0; i--) {
      final cx = (i - 0.5) * step;
      final cy = h * 0.5 * coverage + math.sin(i * 1.5 + progress * 4) * 25;
      final ry = 60 * coverage;
      path.quadraticBezierTo(cx, cy + ry, i * step, h * 0.45 * coverage);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Bottom cloud wave floating upwards
    final botPath = Path();
    botPath.moveTo(0, h);
    botPath.lineTo(w, h);
    botPath.lineTo(w, h - h * 0.55 * coverage);

    for (int i = puffs; i >= 0; i--) {
      final cx = (i - 0.5) * step;
      final cy = h - (h * 0.55 * coverage) - math.cos(i * 2.0 + progress * 3) * 20;
      final ry = 70 * coverage;
      botPath.quadraticBezierTo(cx, cy - ry, i * step, h - (h * 0.5 * coverage));
    }
    botPath.close();
    canvas.drawPath(botPath, paint);

    // Center cloud circles swelling during peak coverage
    if (coverage > 0.3) {
      final centerPaint = Paint()..color = cloudColor;
      final centerScale = (coverage - 0.3) / 0.7;
      canvas.drawCircle(
        Offset(w * 0.3, h * 0.4),
        w * 0.45 * centerScale,
        centerPaint,
      );
      canvas.drawCircle(
        Offset(w * 0.7, h * 0.55),
        w * 0.5 * centerScale,
        centerPaint,
      );
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.48),
        w * 0.55 * centerScale,
        centerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
