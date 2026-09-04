import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Upgraded High-Throughput Leaf Particle Overlay Widget.
/// Animates dense, multi-shaped, multi-colored floating botanical leaf particles & ambient spores over any screen backdrop.
class LeavesParticleOverlay extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final bool maxThroughput;

  const LeavesParticleOverlay({
    super.key,
    this.child,
    this.particleCount = 50,
    this.maxThroughput = true,
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
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _leavesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.maxThroughput
        ? math.max(widget.particleCount, 55)
        : widget.particleCount;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        AnimatedBuilder(
          animation: _leavesCtrl,
          builder: (context, _) {
            return IgnorePointer(
              child: CustomPaint(
                painter: _HighThroughputLeavesPainter(
                  t: _leavesCtrl.value,
                  count: count,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HighThroughputLeavesPainter extends CustomPainter {
  final double t;
  final int count;

  _HighThroughputLeavesPainter({
    required this.t,
    required this.count,
  });

  static final Map<int, List<_LeafParticleData>> _cachedParticles = {};

  List<_LeafParticleData> _getParticles(int total) {
    if (!_cachedParticles.containsKey(total)) {
      _cachedParticles[total] = List.generate(total, (i) {
        final rand = math.Random(i * 37 + 13);
        return _LeafParticleData(
          x: rand.nextDouble(),
          yStart: rand.nextDouble(),
          speed: 0.025 + rand.nextDouble() * 0.065,
          size: 7.0 + rand.nextDouble() * 16.0,
          phase: rand.nextDouble() * math.pi * 2,
          opacity: 0.20 + rand.nextDouble() * 0.45,
          colorIdx: i % 6,
          leafType: i % 5, // 5 distinct leaf geometries
          rotationSpeed: 0.5 + rand.nextDouble() * 2.0,
          swayAmplitude: 0.02 + rand.nextDouble() * 0.05,
          isForeground: i % 3 == 0,
        );
      });
    }
    return _cachedParticles[total]!;
  }

  static const _colors = [
    Color(0xFF81C784), // Fresh Spring Green
    Color(0xFF2ECC71), // Emerald Forest
    Color(0xFFFFD54F), // Golden Sunlight
    Color(0xFFC0CA33), // Lime Yellow
    Color(0xFFF1F8E9), // Soft Floral White
    Color(0xFFFFB74D), // Warm Amber
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final particles = _getParticles(count);
    final w = size.width;
    final h = size.height;

    for (final leaf in particles) {
      // 2D continuous physics: vertical float + horizontal wind sway
      final y = ((leaf.yStart - leaf.speed * t) % 1.0) * h;
      final sway = math.sin(t * math.pi * 2 + leaf.phase) * leaf.swayAmplitude * w;
      final x = (leaf.x * w + sway) % w;

      final paint = Paint()
        ..color = _colors[leaf.colorIdx].withValues(alpha: leaf.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);

      // 360° continuous leaf spin
      final rotation = t * math.pi * 2 * leaf.rotationSpeed + leaf.phase;
      canvas.rotate(rotation);

      // Subtle glowing aura for foreground leaves
      if (leaf.isForeground) {
        final auraPaint = Paint()
          ..color = _colors[leaf.colorIdx].withValues(alpha: leaf.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, leaf.size * 0.7, auraPaint);
      }

      // Draw specific vector leaf geometry
      switch (leaf.leafType) {
        case 0:
          _drawLanceolateLeaf(canvas, leaf.size, paint);
          break;
        case 1:
          _drawOakLeaf(canvas, leaf.size, paint);
          break;
        case 2:
          _drawMapleLeaf(canvas, leaf.size, paint);
          break;
        case 3:
          _drawIvyLeaf(canvas, leaf.size, paint);
          break;
        case 4:
        default:
          _drawSporeDot(canvas, leaf.size, paint);
          break;
      }

      canvas.restore();
    }
  }

  /// 1. Classic Lanceolate / Teardrop Leaf
  void _drawLanceolateLeaf(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, size / 2)
      ..quadraticBezierTo(size / 2, 0, 0, -size / 2)
      ..quadraticBezierTo(-size / 2, 0, 0, size / 2);
    canvas.drawPath(path, paint);
  }

  /// 2. Serrated Oak Leaf
  void _drawOakLeaf(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, s)
      ..quadraticBezierTo(s * 0.6, s * 0.5, s * 0.4, 0)
      ..quadraticBezierTo(s * 0.8, -s * 0.3, 0, -s)
      ..quadraticBezierTo(-s * 0.8, -s * 0.3, -s * 0.4, 0)
      ..quadraticBezierTo(-s * 0.6, s * 0.5, 0, s);
    canvas.drawPath(path, paint);
  }

  /// 3. Maple / Star Leaf
  void _drawMapleLeaf(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, s)
      ..lineTo(s * 0.3, s * 0.3)
      ..lineTo(s, s * 0.2)
      ..lineTo(s * 0.4, -s * 0.2)
      ..lineTo(0, -s)
      ..lineTo(-s * 0.4, -s * 0.2)
      ..lineTo(-s, s * 0.2)
      ..lineTo(-s * 0.3, s * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// 4. Heart-shaped Ivy Leaf
  void _drawIvyLeaf(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, s * 0.8)
      ..cubicTo(s, s * 0.2, s * 0.8, -s, 0, -s * 0.5)
      ..cubicTo(-s * 0.8, -s, -s, s * 0.2, 0, s * 0.8);
    canvas.drawPath(path, paint);
  }

  /// 5. Glowing Ambient Spore Dot
  void _drawSporeDot(Canvas canvas, double size, Paint paint) {
    canvas.drawCircle(Offset.zero, size * 0.35, paint);
  }

  @override
  bool shouldRepaint(_HighThroughputLeavesPainter old) =>
      old.t != t || old.count != count;
}

class _LeafParticleData {
  final double x, yStart, speed, size, phase, opacity;
  final int colorIdx;
  final int leafType;
  final double rotationSpeed;
  final double swayAmplitude;
  final bool isForeground;

  const _LeafParticleData({
    required this.x,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.phase,
    required this.opacity,
    required this.colorIdx,
    required this.leafType,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.isForeground,
  });
}
