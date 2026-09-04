import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_screen.dart';
import '../services/backend_warmup_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _introCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _leavesCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  int _dotCount = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _leavesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut),
    );

    _introCtrl.forward();

    _dotTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });

    BackendWarmupService().startWarmup();
    _navigateAfterSplash();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _bounceCtrl.dispose();
    _leavesCtrl.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  void _navigateAfterSplash() {
    Timer(const Duration(milliseconds: 5000), () async {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const OnboardingScreen(),
          transitionsBuilder: (_, a1, a2, child) =>
              FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introCtrl, _bounceCtrl, _leavesCtrl]),
          builder: (context, _) {
            final floatY = math.sin(_bounceCtrl.value * math.pi) * 8;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Scenic Nature Field & Sky Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/sprites/image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF81D4FA),
                            Color(0xFFA5D6A7),
                            Color(0xFF388E3C),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating ambient leaves overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LeavesPainter(t: _leavesCtrl.value),
                  ),
                ),

                // 2. Center Main Hero Content (Mascot + Tagline)
                Positioned.fill(
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 3),

                            // Floating Animated Center Mascot
                            Transform.translate(
                              offset: Offset(0, -floatY),
                              child: Transform.scale(
                                scale: _scaleAnim.value,
                                child: SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Glowing background aura behind mascot
                                      Container(
                                        width: 220,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.35 +
                                                    0.15 *
                                                        math.sin(
                                                            _bounceCtrl.value *
                                                                math.pi),
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Center Mascot (mascot_transparent.png)
                                      Image.asset(
                                        'assets/logo/mascot_transparent.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 4. Taglines ("Grow Plants", "Grow Future" + Sprout Icon)
                            Column(
                              children: [
                                Text(
                                  'Grow Plants',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x99000000),
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Grow Future',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x99000000),
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tiny white sprout icon below "Grow Future"
                                const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),

                            const Spacer(flex: 2),

                            // 5. Loading indicator dots at bottom
                            Text(
                              'Loading${'.' * _dotCount}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                                shadows: const [
                                  Shadow(
                                    color: Color(0x80000000),
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Floating Leaves Painter ────────────────────────────────────────────────────
class _LeavesPainter extends CustomPainter {
  final double t;

  const _LeavesPainter({required this.t});

  static final _leaves = List.generate(14, (i) {
    final rand = math.Random(i * 31 + 7);
    return _LeafData(
      x: rand.nextDouble(),
      yStart: rand.nextDouble(),
      speed: 0.035 + rand.nextDouble() * 0.055,
      size: 7.0 + rand.nextDouble() * 13.0,
      phase: rand.nextDouble() * math.pi * 2,
      opacity: 0.18 + rand.nextDouble() * 0.22,
      colorIdx: i % 3,
    );
  });

  static const _colors = [
    Color(0xFFA5D6A7), // light green
    Color(0xFFFFD54F), // yellow
    Color(0xFFFFFFFF), // white
  ];

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(_LeavesPainter old) => old.t != t;
}

class _LeafData {
  final double x, yStart, speed, size, phase, opacity;
  final int colorIdx;

  const _LeafData({
    required this.x,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.phase,
    required this.opacity,
    required this.colorIdx,
  });
}
