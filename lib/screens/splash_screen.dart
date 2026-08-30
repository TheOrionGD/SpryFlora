import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/user_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_setup_screen.dart';

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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _leavesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut),
    );

    _introCtrl.forward();

    _dotTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });

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
    Timer(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      final userService = UserService();
      final hasUser = await userService.hasUserData();
      final isOnboarded = await userService.isOnboardingCompleted();

      if (!mounted) return;
      Widget dest;
      if (hasUser && userService.currentUser != null) {
        dest = const HomeScreen();
      } else if (isOnboarded) {
        dest = const ProfileSetupScreen();
      } else {
        dest = const OnboardingScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => dest,
          transitionsBuilder: (_, a1, a2, child) =>
              FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_introCtrl, _bounceCtrl, _leavesCtrl]),
        builder: (context, _) {
          final floatY = math.sin(_bounceCtrl.value * math.pi) * 9;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF66BB6A), // Bright nature green top
                  Color(0xFF388E3C), // Vibrant mid green
                  Color(0xFF1B5E20), // Botanical deep base
                ],
              ),
            ),
            child: Stack(
              children: [
                // ── Floating ambient leaves (full-size, behind content) ──────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LeavesPainter(t: _leavesCtrl.value),
                  ),
                ),

                // ── Main centered content ─────────────────────────────────────
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // ── Logo ────────────────────────────────────────────
                          Transform.translate(
                            offset: Offset(0, -floatY),
                            child: Transform.scale(
                              scale: _scaleAnim.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow ring
                                  Container(
                                    width: 210,
                                    height: 210,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(
                                            alpha: 0.15 *
                                                math.sin(_bounceCtrl.value *
                                                    math.pi),
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Logo image — frameless, no background
                                  SizedBox(
                                    width: 165,
                                    height: 165,
                                    child: Image.asset(
                                      'assets/sprites/mascot_pot_happy.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/logo/mascot_transparent.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            Image.asset(
                                          'assets/logo/logo.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.local_florist_rounded,
                                            size: 100,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── App Name ────────────────────────────────────────
                          Text(
                            'SpryFlora',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: const [
                                Shadow(
                                  color: Color(0x660A2E0C),
                                  offset: Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Tagline (from Screen 1) ─────────────────────────
                          Column(
                            children: [
                              Text(
                                'Grow Plants',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Grow Future',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFD54F),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(flex: 2),

                          // ── Loading dots ────────────────────────────────────
                          Text(
                            'Loading${'.' * _dotCount}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
