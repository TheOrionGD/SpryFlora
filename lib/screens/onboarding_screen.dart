import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/backend_warmup_service.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/cloud_transition_overlay.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/video_background_backdrop.dart';
import 'landing_selection_screen.dart';

/// 9-Screen 50-Second Automated Cloud Flow Onboarding
/// Features 5-second auto-timer per screen, custom cloud transition sweep between screens,
/// zero skip/next buttons, and background Render engine warming.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _floatCtrl;
  late final AnimationController _slideTimerCtrl;
  late final AnimationController _cloudAnimCtrl;

  int _currentPage = 0;
  bool _showConfetti = false;
  Timer? _autoFlowTimer;
  final BackendWarmupService _warmupService = BackendWarmupService();

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      imagePath: 'assets/sprites/boy_planting.png',
      title: 'Welcome to\nSpryFlora Cloud!',
      subtitle:
          'Begin your green journey with an AI-powered\nbotanical companion & cloud sync.',
      badgeText: '01 • BOTANICAL PORTAL',
      accentColor: Color(0xFF2ECC71),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/boy_phone_scanning.png',
      title: 'AI Plant Health\nDiagnostics',
      subtitle:
          'Scan any leaf with vision AI to instantly detect\ndiseases, bugs & organic treatments.',
      badgeText: '02 • AI LEAF SCANNER',
      accentColor: Color(0xFF3498DB),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/mascot_pot_happy.png',
      title: 'Meet Your Virtual\nCompanion',
      subtitle:
          'Watch your happy sprout mascot react, celebrate &\ngrow alongside your real plants.',
      badgeText: '03 • MASCOT COMPANION',
      accentColor: Color(0xFFE67E22),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/plant_potted.png',
      title: 'Precision H2O &\nSoil Tracking',
      subtitle:
          'Smart hydration schedules tailored to plant species,\npot dimensions & humidity.',
      badgeText: '04 • SMART HYDRATION',
      accentColor: Color(0xFF1ABC9C),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/mascot_pot_winking.png',
      title: 'Flora AI Eco-Buddy\n24/7 Q&A',
      subtitle:
          'Ask anything about soil pH, pruning, or sunlight\nto your instant AI companion.',
      badgeText: '05 • FLORA AI ASSISTANT',
      accentColor: Color(0xFF9B59B6),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/trophy_champion.png',
      title: '16-Level Gamified\nGarden Journey',
      subtitle:
          'Earn eco-XP, complete daily care quests &\nunlock legendary botanical trophies.',
      badgeText: '06 • GAMIFIED MAP',
      accentColor: Color(0xFFF1C40F),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/avatar_boy_hero.png',
      title: 'Real-Time Cloud\nSynchronization',
      subtitle:
          'Your plant logs, check-ins & photos sync\nseamlessly across all your devices.',
      badgeText: '07 • CLOUD SYNC',
      accentColor: Color(0xFF34495E),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/mascot_graduate_logo.png',
      title: 'Verifiable Master\nPlanter Certificates',
      subtitle:
          'Graduate through care milestones & receive\nofficial eco-hero diploma certificates.',
      badgeText: '08 • ECO CERTIFICATIONS',
      accentColor: Color(0xFFE74C3C),
    ),
    _OnboardPage(
      imagePath: 'assets/sprites/mascot_celebrating_confetti.png',
      title: 'Cloud Engine\nReady for Launch!',
      subtitle:
          'SpryFlora cloud engine is hot, synchronized &\nready for instant AI & data requests.',
      badgeText: '09 • CLOUD READY',
      accentColor: Color(0xFF2ECC71),
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

    _slideTimerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _cloudAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _warmupService.addListener(_onWarmupStatusChanged);
    _warmupService.startWarmup();

    _start5SecSlideFlow();
  }

  @override
  void dispose() {
    _autoFlowTimer?.cancel();
    _warmupService.removeListener(_onWarmupStatusChanged);
    _pageController.dispose();
    _floatCtrl.dispose();
    _slideTimerCtrl.dispose();
    _cloudAnimCtrl.dispose();
    super.dispose();
  }

  void _onWarmupStatusChanged() {
    if (mounted) setState(() {});
  }

  void _start5SecSlideFlow() {
    _slideTimerCtrl.forward(from: 0.0);

    _autoFlowTimer?.cancel();
    _autoFlowTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _triggerCloudTransitionToNextPage();
    });
  }

  void _triggerCloudTransitionToNextPage() {
    if (_currentPage < _pages.length - 1) {
      final nextIdx = _currentPage + 1;
      _cloudAnimCtrl.forward(from: 0.0).then((_) {
        if (mounted) _cloudAnimCtrl.reset();
      });

      // Animate page right at peak cloud cover (400ms mark)
      Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextIdx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
        setState(() {
          _currentPage = nextIdx;
        });
        _slideTimerCtrl.forward(from: 0.0);
      });
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    _autoFlowTimer?.cancel();
    _slideTimerCtrl.stop();
    setState(() => _showConfetti = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final userService = UserService();
    await userService.setOnboardingCompleted(true);

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const LandingSelectionScreen(),
          transitionsBuilder: (_, a1, a2, child) => FadeTransition(
            opacity: a1,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: AnimatedBuilder(
        animation: _cloudAnimCtrl,
        builder: (context, child) {
          return CloudTransitionOverlay(
            animationValue: _cloudAnimCtrl.value,
            child: child!,
          );
        },
        child: Scaffold(
          backgroundColor: SkeuoTheme.background,
          body: Stack(
            children: [
              // 1. Top Video Background Backdrop & Floating Leaves
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.58,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const VideoBackgroundBackdrop(),
                    const LeavesParticleOverlay(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            SkeuoTheme.background.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Top Header Branding Badge
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SpryFlora • Botanical Journey 🌿',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Left Back Button to return to Portal
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LandingSelectionScreen()),
                        );
                      }
                    },
                    tooltip: 'Return to Portal',
                  ),
                ),
              ),

              // 3. Automated & Interactive PageView Content
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _slideTimerCtrl.forward(from: 0.0);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final p = _pages[index];
                  return Column(
                    key: ValueKey('onboard_page_$index'),
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
                                padding: const EdgeInsets.fromLTRB(28, 48, 28, 20),
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

                      // Bottom Ivory Content Card
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
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
                                  // Badge Pill Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            p.accentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      p.badgeText,
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: p.accentColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Main Title
                                  Text(
                                    p.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: SkeuoTheme.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Subtitle Description
                                  Text(
                                    p.subtitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: SkeuoTheme.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom Automated 5-Second Timer Bar & 9-Step Indicators
                              Column(
                                children: [
                                  // Smooth 5-Second Linear Timer Progress Bar
                                  AnimatedBuilder(
                                    animation: _slideTimerCtrl,
                                    builder: (context, _) {
                                      return Container(
                                        height: 5,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E0E0),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _slideTimerCtrl.value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  p.accentColor,
                                                  SkeuoTheme.primaryGreen,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // 9 Step Progress Dots (Clickable)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _pages.length,
                                      (dotIdx) {
                                        final isAct = dotIdx == index;
                                        final isPast = dotIdx < index;
                                        return GestureDetector(
                                          onTap: () {
                                            if (_pageController.hasClients) {
                                              _pageController.animateToPage(
                                                dotIdx,
                                                duration: const Duration(
                                                    milliseconds: 350),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 350),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            width: isAct ? 22 : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isAct
                                                  ? p.accentColor
                                                  : isPast
                                                      ? SkeuoTheme.primaryGreen
                                                          .withValues(alpha: 0.5)
                                                      : const Color(0xFFD0E0D0),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Caption indicator
                                  Text(
                                    'Auto-flow: 5s per screen (${index + 1}/9)',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: SkeuoTheme.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}

class _OnboardPage {
    final String imagePath;
    final String title;
    final String subtitle;
    final String badgeText;
    final Color accentColor;

    const _OnboardPage({
      required this.imagePath,
      required this.title,
      required this.subtitle,
      required this.badgeText,
      required this.accentColor,
    });
  }
