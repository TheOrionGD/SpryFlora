import 'dart:math' as math;
import 'package:flutter/material.dart';

enum RewardSplashMode {
  confetti,             // Joyful multi-color confetti & stars
  waterSplash,          // Blue water droplets & bubble ripples
  certificateAchievement // Golden stars, emerald leaves, trophy sparkles & ribbons
}

/// Kid & Family Friendly Reward Particle Splash Engine
/// Provides vibrant tactile celebrations on watering, daily check-in, and certificate unlocks.
class FunConfettiOverlay extends StatefulWidget {
  final bool isActive;
  final RewardSplashMode mode;
  final Widget child;

  const FunConfettiOverlay({
    super.key,
    required this.isActive,
    this.mode = RewardSplashMode.confetti,
    required this.child,
  });

  @override
  State<FunConfettiOverlay> createState() => _FunConfettiOverlayState();
}

class _FunConfettiOverlayState extends State<FunConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_SplashParticle> _particles;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.mode == RewardSplashMode.certificateAchievement
            ? 2400
            : 1800,
      ),
    );
    _controller.addListener(() => setState(() {}));
    _spawnParticles();
    if (widget.isActive) _startBurst();
  }

  @override
  void didUpdateWidget(FunConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _spawnParticles();
      _startBurst();
    }
  }

  void _spawnParticles() {
    final count = widget.mode == RewardSplashMode.certificateAchievement ? 60 : 40;
    _particles = List.generate(count, (_) => _SplashParticle(_rand, widget.mode));
  }

  void _startBurst() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive && _controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SplashPainter(
                  particles: _particles,
                  progress: _controller.value,
                  mode: widget.mode,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashParticle {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final Color color;
  final double size;
  final double rotationSpeed;
  final int shape; // 0=circle/droplet, 1=star, 2=leaf, 3=ribbon

  _SplashParticle(math.Random rand, RewardSplashMode mode)
      : startX = 0.2 + rand.nextDouble() * 0.6,
        startY = 0.35 + rand.nextDouble() * 0.3,
        speedX = (rand.nextDouble() - 0.5) * 1.8,
        speedY = -(rand.nextDouble() * 1.5 + 0.6),
        color = _pickColor(rand, mode),
        size = _pickSize(rand, mode),
        rotationSpeed = (rand.nextDouble() - 0.5) * 8.0,
        shape = _pickShape(rand, mode);

  static Color _pickColor(math.Random rand, RewardSplashMode mode) {
    switch (mode) {
      case RewardSplashMode.certificateAchievement:
        const certColors = [
          Color(0xFFFFD700), // Gold
          Color(0xFFFFB300), // Amber
          Color(0xFF4CAF50), // Emerald
          Color(0xFF81C784), // Light Green
          Color(0xFFFF7043), // Coral
          Color(0xFFFFEB3B), // Bright Yellow
          Color(0xFFFFFFFF), // Sparkle White
        ];
        return certColors[rand.nextInt(certColors.length)];

      case RewardSplashMode.waterSplash:
        const waterColors = [
          Color(0xFF29B6F6), // Sky Blue
          Color(0xFF0288D1), // Deep Water Blue
          Color(0xFF80D8FF), // Ice Splash
          Color(0xFF4DD0E1), // Cyan Aqua
          Color(0xFFE0F7FA), // Froth
        ];
        return waterColors[rand.nextInt(waterColors.length)];

      case RewardSplashMode.confetti:
        const partyColors = [
          Color(0xFFFF5722), // Deep Orange
          Color(0xFFFFC107), // Amber
          Color(0xFF4CAF50), // Green
          Color(0xFF2196F3), // Blue
          Color(0xFFE91E63), // Pink
          Color(0xFF9C27B0), // Purple
          Color(0xFF00BCD4), // Cyan
        ];
        return partyColors[rand.nextInt(partyColors.length)];
    }
  }

  static double _pickSize(math.Random rand, RewardSplashMode mode) {
    if (mode == RewardSplashMode.certificateAchievement) {
      return 8.0 + rand.nextDouble() * 12.0;
    }
    return 6.0 + rand.nextDouble() * 9.0;
  }

  static int _pickShape(math.Random rand, RewardSplashMode mode) {
    if (mode == RewardSplashMode.waterSplash) return 0; // droplet/circle
    if (mode == RewardSplashMode.certificateAchievement) {
      return rand.nextInt(3); // star, leaf, gold coin
    }
    return rand.nextInt(4); // circle, star, leaf, ribbon
  }
}

class _SplashPainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final double progress;
  final RewardSplashMode mode;

  _SplashPainter({
    required this.particles,
    required this.progress,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gravity = mode == RewardSplashMode.waterSplash ? 2.2 : 1.6;

    for (final p in particles) {
      // Physics trajectory
      final x = (p.startX + p.speedX * progress) * size.width;
      final y = (p.startY + p.speedY * progress + 0.5 * gravity * progress * progress) * size.height;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final scale = (1.0 - progress * 0.2).clamp(0.0, 1.2);
      final rotation = progress * p.rotationSpeed;

      if (y > size.height + 20 || x < -20 || x > size.width + 20) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(scale);

      switch (p.shape) {
        case 0:
          // Droplet / Particle circle
          if (mode == RewardSplashMode.waterSplash) {
            // Teardrop water droplet
            final dropPath = Path()
              ..moveTo(0, -p.size)
              ..quadraticBezierTo(p.size * 0.7, 0, 0, p.size * 0.8)
              ..quadraticBezierTo(-p.size * 0.7, 0, 0, -p.size)
              ..close();
            canvas.drawPath(dropPath, paint);
          } else {
            canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          }
          break;

        case 1:
          // Star
          _drawStar(canvas, p.size * 0.6, paint);
          break;

        case 2:
          // Leaf
          _drawLeaf(canvas, p.size * 0.7, paint);
          break;

        case 3:
          // Ribbon rectangle
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size * 1.4, height: p.size * 0.45),
              const Radius.circular(2),
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLeaf(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.8, 0, 0, size)
      ..quadraticBezierTo(-size * 0.8, 0, 0, -size)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
