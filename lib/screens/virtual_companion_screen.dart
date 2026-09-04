import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import 'ai_eco_buddy_screen.dart';
import 'garden_screen.dart';

import '../widgets/leaves_particle_overlay.dart';
import '../widgets/video_background_backdrop.dart';

/// Screen 14: Virtual Companion (from 255.jpg)
/// - Top Bar: "Virtual Companion"
/// - Animated interactive mascot sprout in terracotta pot
/// - Status Badge: "Healthy / Level 4"
/// - Daily Status Checklist:
///   * Watered Today (green check)
///   * Photo Uploaded (green check)
///   * Plant Healthy (green check)
/// - "View Growth Journey" button
class VirtualCompanionScreen extends StatefulWidget {
  const VirtualCompanionScreen({super.key});

  @override
  State<VirtualCompanionScreen> createState() => _VirtualCompanionScreenState();
}

class _VirtualCompanionScreenState extends State<VirtualCompanionScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final PlantRepository _plantRepo = PlantRepository();

  late AnimationController _idleCtrl;
  late AnimationController _sparkleCtrl;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  Future<void> _interactWithCompanion() async {
    setState(() => _showConfetti = true);
    await _userService.waterVirtualPlant();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _showConfetti = false);
  }

  @override
  Widget build(BuildContext context) {
    final virtualPlant = _userService.virtualPlant;
    final health = virtualPlant?.health ?? 90;
    final level = virtualPlant?.level ?? 4;

    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          title: Text(
            'Virtual Companion',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.park_rounded, color: Color(0xFF2ECC71)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GardenScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Continuous Video Background (assets/sprites/bg.mp4)
            const Positioned.fill(
              child: VideoBackgroundBackdrop(),
            ),

            // Soft Translucent Dark Overlay for legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Leaf Particle Effect Overlay
            const Positioned.fill(
              child: LeavesParticleOverlay(),
            ),

            // 3. Foreground Interactive UI
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                // ── Animated Companion Mascot in Pot ────────────────────────
                GestureDetector(
                  onTap: _interactWithCompanion,
                  child: AnimatedBuilder(
                    animation: _idleCtrl,
                    builder: (context, child) {
                      final floatY = math.sin(_idleCtrl.value * math.pi) * 8;
                      return Transform.translate(
                        offset: Offset(0, -floatY),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE8F5E9),
                          width: 4,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft glow circle
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC8E6C9)
                                      .withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Mascot Image
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: Image.asset(
                              'assets/sprites/mascot_pot_happy.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/logo/mascot_transparent.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_florist_rounded,
                                  size: 100,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Status: Healthy / Level 4 ─────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFF81C784), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded,
                          color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Health $health%  •  Level $level',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Daily Checklist Card ──────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE8F5E9),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildChecklistItem(
                        'Watered Today',
                        isDone: _plantRepo.plants.any((p) => !p.isWateringDue),
                      ),
                      const Divider(color: Color(0xFFF1F8E9), height: 20),
                      _buildChecklistItem(
                        'Photo Uploaded',
                        isDone: _plantRepo.plants
                            .any((p) => p.initialPhotoPath != null),
                      ),
                      const Divider(color: Color(0xFFF1F8E9), height: 20),
                      _buildChecklistItem(
                        'Plant Healthy ($health%)',
                        isDone: health >= 70,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── "Talk to Eco Buddy 🎙️" & "View Growth Journey" Buttons ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FunBouncyButton(
                        text: 'Voice Chat 🎙️',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AIEcoBuddyScreen(),
                            ),
                          );
                        },
                        color: const Color(0xFF2E7D32),
                        textColor: Colors.white,
                        height: 54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FunBouncyButton(
                        text: 'Growth Journey 🌿',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GardenScreen()),
                          );
                        },
                        color: const Color(0xFF4CAF50),
                        textColor: Colors.white,
                        height: 54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildChecklistItem(String title, {required bool isDone}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF37474F),
          ),
        ),
        const Spacer(),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
