import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable Leaf Particle Overlay Widget.
/// Animates floating/falling botanical leaf particles over any backdrop.
class LeavesParticleOverlay extends StatefulWidget {
  final Widget? child;

  const LeavesParticleOverlay({
    super.key,
    this.child,
  });

  @override
  State<LeavesParticleOverlay> createState() => _LeavesParticleOverlayState();
}

class _LeavesParticleOverlayState extends State<LeavesParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _leavesCtrl;

  @override
  void initState() {
    super.initState();
    _leavesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _leavesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        AnimatedBuilder(
          animation: _leavesCtrl,
          builder: (context, _) {
            return IgnorePointer(
              child: CustomPaint(
                painter: _SharedLeavesPainter(t: _leavesCtrl.value),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SharedLeavesPainter extends CustomPainter {
  final double t;

  const _SharedLeavesPainter({required this.t});

  static final _leaves = List.generate(16, (i) {
    final rand = math.Random(i * 31 + 7);
    return _SharedLeafData(
      x: rand.nextDouble(),
      yStart: rand.nextDouble(),
      speed: 0.035 + rand.nextDouble() * 0.055,
      size: 8.0 + rand.nextDouble() * 14.0,
      phase: rand.nextDouble() * math.pi * 2,
      opacity: 0.25 + rand.nextDouble() * 0.30,
      colorIdx: i % 3,
    );
  });

  static const _colors = [
    Color(0xFFA5D6A7), // light leaf green
    Color(0xFFFFD54F), // golden sunlight yellow
    Color(0xFFFFFFFF), // soft white particle
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    for (final leaf in _leaves) {
      final y = ((leaf.yStart - leaf.speed * t) % 1.0) * size.height;
      final x = (leaf.x + math.sin(t * math.pi * 2 + leaf.phase) * 0.045) *
          size.width;
      final paint = Paint()
        ..color = _colors[leaf.colorIdx].withValues(alpha: leaf.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 1.5 + leaf.phase);

      final path = Path()
        ..moveTo(0, leaf.size / 2)
        ..quadraticBezierTo(leaf.size / 2, 0, 0, -leaf.size / 2)
        ..quadraticBezierTo(-leaf.size / 2, 0, 0, leaf.size / 2);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SharedLeavesPainter old) => old.t != t;
}

class _SharedLeafData {
  final double x, yStart, speed, size, phase, opacity;
  final int colorIdx;

  const _SharedLeafData({
    required this.x,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.phase,
    required this.opacity,
    required this.colorIdx,
  });
}
