import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/backend_warmup_service.dart';
import '../services/user_service.dart';
import '../widgets/leaves_particle_overlay.dart';

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
    Timer(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;

      final authService = AuthService();
      await authService.restoreSession();

      final userService = UserService();
      await userService.loadUserData();

      if (!mounted) return;

      final hasExistingUser = authService.isAuthenticated ||
          (userService.currentUser != null) ||
          await userService.hasUserData();

      if (!mounted) return;

      final targetScreen = hasExistingUser
          ? const HomeScreen()
          : const OnboardingScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => targetScreen,
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

                // Floating ambient leaves overlay (High Throughput)
                const Positioned.fill(
                  child: LeavesParticleOverlay(maxThroughput: true),
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

                                      // Center App Logo
                                      Image.asset(
                                        'assets/logo/logo.png',
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


