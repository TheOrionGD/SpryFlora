import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/professional_landscape_certificate.dart';
import 'certificate_screen.dart';
import 'home_screen.dart';
import 'garden_screen.dart';
import 'my_plants_screen.dart';

/// My Certifications Screen:
/// - Displays earned/claimed landscape certificates with full gold seal
/// - Displays in-progress plants with frosted glass blur, padlock & remaining progress
class MyCertificationsScreen extends StatefulWidget {
  const MyCertificationsScreen({super.key});

  @override
  State<MyCertificationsScreen> createState() => _MyCertificationsScreenState();
}

class _MyCertificationsScreenState extends State<MyCertificationsScreen> {
  final PlantRepository _plantRepo = PlantRepository();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _plantRepo.loadLocalData();
    _userService.loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1B4D3E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🏆 My Certifications',
          style: GoogleFonts.cinzel(
            color: const Color(0xFF1B4D3E),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyPlantsScreen()),
              );
              break;
            case 2:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GardenScreen()),
              );
              break;
            case 3:
              Navigator.of(context).pop();
              break;
          }
        },
      ),
      body: AnimatedBuilder(
        animation: _plantRepo,
        builder: (context, _) {
          final plants = _plantRepo.plants;
          final user = _userService.currentUser;
          final String childName =
              (user != null && user.childName.trim().isNotEmpty)
                  ? user.childName.trim()
                  : 'Plant Hero';

          if (plants.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFFCE93D8), width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: Image.asset(
                          'assets/illustrations/garden_growth.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Certificates Yet',
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plant and nurture your plants to full maturity to earn official SpryFlora Certificates of Achievement!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF558B2F),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final unlockedCount = plants.where((p) => p.isCompleted).length;
          final lockedCount = plants.length - unlockedCount;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4D3E), Color(0xFF0D2E24)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                          border: Border.all(
                              color: const Color(0xFFFFD54F), width: 2),
                        ),
                        child: const Center(
                          child: Text('🎖️', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$childName\'s Honors',
                              style: GoogleFonts.cinzel(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$unlockedCount Earned Diplomas • $lockedCount In Progress',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC8E6C9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'Certificates of Achievement',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 12),

                // Certificates Landscape Gallery
                ...plants.map((plant) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _LandscapeCertificateItemCard(
                      plant: plant,
                      recipientName: childName,
                      onTap: () {
                        if (plant.isCompleted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CertificateScreen(plant: plant),
                            ),
                          );
                        } else {
                          _showLockedCertificateSheet(context, plant);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Interactive Modal explaining locked certificate status & remaining lifespan
  void _showLockedCertificateSheet(BuildContext context, PlantModel plant) {
    final int age = plant.ageInDays;
    final int lifespan = plant.lifespanDays;
    final int remainingDays = math.max(lifespan - age, 0);
    final double progress = plant.growthProgress;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Certificate Document Sprite Icon
              SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  'assets/sprites/certificate_doc.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFE65100),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Certificate Locked 🔒',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Complete all $lifespan days of nurturing ${plant.plantName} to unlock, download, and share your official Certificate of Achievement!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF558B2F),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lifespan Progress:',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B4D3E),
                    ),
                  ),
                  Text(
                    '$age / $lifespan Days (${(progress * 100).toStringAsFixed(0)}%)',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '⏳ $remainingDays days remaining until certificate unlocks',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD84315),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Got It! Keep Growing 🌱',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Realistic Landscape Certificate Item Card (Unlocked or Blurred with Lock)
class _LandscapeCertificateItemCard extends StatelessWidget {
  final PlantModel plant;
  final String recipientName;
  final VoidCallback onTap;

  const _LandscapeCertificateItemCard({
    required this.plant,
    required this.recipientName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = plant.isCompleted;
    final int age = plant.ageInDays;
    final int lifespan = plant.lifespanDays;
    final double progress = plant.growthProgress;
    final int remainingDays = math.max(lifespan - age, 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // The Authentic Landscape Certificate Component
              ProfessionalLandscapeCertificate(
                plant: plant,
                recipientName: recipientName,
              ),

              // Locked Frosted Glass Blur Overlay with Golden Padlock
              if (!isUnlocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                      child: Container(
                        color: const Color(0xFF0F261F).withValues(alpha: 0.72),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Golden Lock Emblem
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFEEB3),
                                    Color(0xFFD4AF37),
                                    Color(0xFF8C6D31)
                                  ],
                                ),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.lock_rounded,
                                    color: Colors.white, size: 26),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'CERTIFICATE LOCKED',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$remainingDays days remaining (${(progress * 100).toStringAsFixed(0)}% Mature)',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE8F5E9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFFD54F)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to preview credential & milestones',
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
