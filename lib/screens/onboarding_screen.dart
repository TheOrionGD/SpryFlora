import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/fun_confetti_overlay.dart';
import 'login_screen.dart';

/// Onboarding Screens (02, 03, 04 from 255.jpg)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _floatCtrl;
  int _currentPage = 0;
  bool _showConfetti = false;

  static const _pages = [
    _OnboardPage(
      imagePath: 'assets/sprites/boy_planting.png',
      title: 'Welcome to\nSpryFlora!',
      subtitle:
          'Begin your green journey\nand grow your\nown virtual plant.',
      topGradient: [Color(0xFFBCE3F5), Color(0xFFD8F1FE), Color(0xFFE8F5E9)],
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/boy_phone_scanning.png',
      title: 'AI Monitors\nYour Plant',
      subtitle:
          'Get AI-powered care tips\nand health updates\nevery day.',
      topGradient: [Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFFE8F5E9)],
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/mascot_pot_happy.png',
      title: 'Your Virtual\nPlant Companion',
      subtitle:
          'Take care daily and watch\nyour plant grow healthy\nand strong!',
      topGradient: [Color(0xFFC8E6C9), Color(0xFFE8F5E9), Color(0xFFFFFDF2)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _showConfetti = false;
    });
  }

  void _goToNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _showConfetti = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final userService = UserService();
    await userService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const LoginScreen(),
        transitionsBuilder: (_, a1, a2, child) => FadeTransition(
          opacity: a1,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: Scaffold(
        backgroundColor: SkeuoTheme.background,
        body: Stack(
          children: [
            // Top Sky/Botanical Gradient Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.58,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: page.topGradient,
                  ),
                ),
              ),
            ),

            // PageView Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final p = _pages[index];
                return Column(
                  children: [
                    // Top Illustration
                    Expanded(
                      flex: 6,
                      child: SafeArea(
                        bottom: false,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (context, child) {
                              final offset =
                                  math.sin(_floatCtrl.value * math.pi) * 6;
                              return Transform.translate(
                                offset: Offset(0, offset),
                                child: child,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Image.asset(
                                p.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/logo/mascot_transparent.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Ivory Card
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                        decoration: const BoxDecoration(
                          color: SkeuoTheme.background,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(36)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0F000000),
                              offset: Offset(0, -6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: SkeuoTheme.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  p.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: SkeuoTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Navigation Controls: Skip | Dots | Next
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Skip Button
                                  TextButton(
                                    onPressed: _finishOnboarding,
                                    child: Text(
                                      'Skip',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: SkeuoTheme.textSecondary,
                                      ),
                                    ),
                                  ),

                                  // Dot Indicators
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      _pages.length,
                                      (dotIdx) {
                                        final isAct = dotIdx == _currentPage;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          width: isAct ? 18 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isAct
                                                ? SkeuoTheme.primaryGreen
                                                : const Color(0xFFC8E6C9),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Next Circular Button
                                  GestureDetector(
                                    onTap: _goToNext,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: SkeuoTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: SkeuoTheme.primaryGreen
                                                .withValues(alpha: 0.35),
                                            offset: const Offset(0, 4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String imagePath;
  final String title;
  final String subtitle;
  final List<Color> topGradient;

  const _OnboardPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.topGradient,
  });
}

