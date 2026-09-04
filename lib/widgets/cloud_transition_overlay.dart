import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clash of Clans (CoC) Style Cloud Transition Overlay Widget.
/// Animates 4 puffy cloud layers from all screen edges (left, right, top, bottom)
/// to fully occlude the screen at 50% progress, executes onCovered(), and parts outward.
class CloudTransitionOverlay extends StatefulWidget {
  final Widget child;

  const CloudTransitionOverlay({
    super.key,
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
  late final AnimationController _animCtrl;
  VoidCallback? _onCoveredCallback;
  bool _hasTriggeredCovered = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _animCtrl.addListener(() {
      if (_animCtrl.value >= 0.5 && !_hasTriggeredCovered) {
        _hasTriggeredCovered = true;
        _onCoveredCallback?.call();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Triggers the full Clash of Clans cloud sweep transition.
  void triggerTransition({required VoidCallback onCovered}) {
    if (_animCtrl.isAnimating) return;
    _onCoveredCallback = onCovered;
    _hasTriggeredCovered = false;
    _animCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final progress = _animCtrl.value;

        return Stack(
          children: [
            widget.child,
            if (progress > 0.0 && progress < 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CoCCloudSweepPainter(progress: progress),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CoCCloudSweepPainter extends CustomPainter {
  final double progress;

  _CoCCloudSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Envelope: 0.0 -> 0.5 (clouds close to 100% coverage), 0.5 -> 1.0 (clouds part)
    final double coverage = (progress <= 0.5)
        ? (progress / 0.5)
        : (1.0 - (progress - 0.5) / 0.5);

    final double cubicCoverage = Curves.easeOutQuart.transform(coverage);

    final Paint mainCloudPaint = Paint()
      ..color = const Color(0xFFF7F9F9)
      ..style = PaintingStyle.fill;

    final Paint shadowCloudPaint = Paint()
      ..color = const Color(0xFFD6EAF8).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final Paint accentCloudPaint = Paint()
      ..color = const Color(0xFFA9CCE3).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    final double maxMoveX = size.width * 0.60;
    final double maxMoveY = size.height * 0.60;

    final double topOffset = (cubicCoverage * maxMoveY) - (size.height * 0.25);
    final double bottomOffset = size.height - (cubicCoverage * maxMoveY) + (size.height * 0.25);
    final double leftOffset = (cubicCoverage * maxMoveX) - (size.width * 0.25);
    final double rightOffset = size.width - (cubicCoverage * maxMoveX) + (size.width * 0.25);

    // 1. Top Cloud Layer
    _drawHorizontalPuffyClouds(canvas, size, topOffset, isTop: true, mainPaint: mainCloudPaint, shadowPaint: shadowCloudPaint, accentPaint: accentCloudPaint);

    // 2. Bottom Cloud Layer
    _drawHorizontalPuffyClouds(canvas, size, bottomOffset, isTop: false, mainPaint: mainCloudPaint, shadowPaint: shadowCloudPaint, accentPaint: accentCloudPaint);

    // 3. Left Cloud Layer
    _drawVerticalPuffyClouds(canvas, size, leftOffset, isLeft: true, mainPaint: mainCloudPaint, shadowPaint: shadowCloudPaint);

    // 4. Right Cloud Layer
    _drawVerticalPuffyClouds(canvas, size, rightOffset, isLeft: false, mainPaint: mainCloudPaint, shadowPaint: shadowCloudPaint);
  }

  void _drawHorizontalPuffyClouds(
    Canvas canvas,
    Size size,
    double baseY, {
    required bool isTop,
    required Paint mainPaint,
    required Paint shadowPaint,
    required Paint accentPaint,
  }) {
    final double dir = isTop ? 1.0 : -1.0;
    final Path pathMain = Path();
    final Path pathShadow = Path();

    if (isTop) {
      pathMain.moveTo(0, 0);
      pathMain.lineTo(0, baseY);
      pathShadow.moveTo(0, 0);
      pathShadow.lineTo(0, baseY - 25 * dir);
    } else {
      pathMain.moveTo(0, size.height);
      pathMain.lineTo(0, baseY);
      pathShadow.moveTo(0, size.height);
      pathShadow.lineTo(0, baseY - 25 * dir);
    }

    const int puffs = 8;
    final double step = size.width / (puffs - 1);

    for (int i = 0; i < puffs; i++) {
      final double x = i * step;
      final double nextX = (i + 1) * step;
      final double puffRadius = step * 0.75;
      final double wave = math.sin(i * 1.8) * 18;

      pathMain.quadraticBezierTo(
        x + step / 2,
        baseY + (puffRadius * dir) + wave,
        nextX,
        baseY,
      );

      pathShadow.quadraticBezierTo(
        x + step / 2,
        baseY + ((puffRadius + 20) * dir) + wave,
        nextX,
        baseY - 12 * dir,
      );
    }

    if (isTop) {
      pathMain.lineTo(size.width, 0);
      pathShadow.lineTo(size.width, 0);
    } else {
      pathMain.lineTo(size.width, size.height);
      pathShadow.lineTo(size.width, size.height);
    }

    pathMain.close();
    pathShadow.close();

    canvas.drawPath(pathShadow, shadowPaint);
    canvas.drawPath(pathMain, mainPaint);
  }

  void _drawVerticalPuffyClouds(
    Canvas canvas,
    Size size,
    double baseX, {
    required bool isLeft,
    required Paint mainPaint,
    required Paint shadowPaint,
  }) {
    final double dir = isLeft ? 1.0 : -1.0;
    final Path pathMain = Path();

    if (isLeft) {
      pathMain.moveTo(0, 0);
      pathMain.lineTo(baseX, 0);
    } else {
      pathMain.moveTo(size.width, 0);
      pathMain.lineTo(baseX, 0);
    }

    const int puffs = 10;
    final double step = size.height / (puffs - 1);

    for (int i = 0; i < puffs; i++) {
      final double y = i * step;
      final double nextY = (i + 1) * step;
      final double puffRadius = step * 0.70;
      final double wave = math.cos(i * 1.6) * 16;

      pathMain.quadraticBezierTo(
        baseX + (puffRadius * dir) + wave,
        y + step / 2,
        baseX,
        nextY,
      );
    }

    if (isLeft) {
      pathMain.lineTo(0, size.height);
    } else {
      pathMain.lineTo(size.width, size.height);
    }

    pathMain.close();
    canvas.drawPath(pathMain, mainPaint);
  }

  @override
  bool shouldRepaint(_CoCCloudSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
