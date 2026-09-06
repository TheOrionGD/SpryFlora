import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/plant_growth_animation.dart';
import 'add_plant_screen.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';
import 'plant_details_screen.dart';
import 'profile_settings_screen.dart';
import 'ai_eco_buddy_screen.dart';
import 'notification_center_screen.dart';

/// Redesigned Kid-Friendly Magical Garden Screen
/// Vibrant, skeuomorphic, highly interactive garden world with Eco-Buddy mascot guidance,
/// individual botanical plot cards, quick water actions, and daily quest progression.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with TickerProviderStateMixin {
  final PlantRepository _plantRepo = PlantRepository();
  final UserService _userService = UserService();

  late AnimationController _ambientCtrl;
  late AnimationController _windCtrl;

  @override
  void initState() {
    super.initState();
    _plantRepo.loadLocalData();
    _userService.loadUserData();

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _windCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _windCtrl.dispose();
    super.dispose();
  }

  Future<void> _quickWaterPlant(PlantModel plant) async {
    final now = DateTime.now();
    final updated = plant.copyWith(
      health: (plant.health + 15).clamp(0, 100),
      hydrationScore: (plant.hydrationScore + 20).clamp(0, 100),
      lastWateredDate: now,
      nextWateringDate: now.add(Duration(days: plant.wateringIntervalDays)),
    );
    await _plantRepo.updatePlant(updated);
    await _userService.addXp(25);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💧 Watered ${plant.plantName}! +25 XP 🌱'),
          backgroundColor: SkeuoTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _waterAllDuePlants() async {
    final plants = _plantRepo.plants;
    final duePlants = plants.where((p) => p.isWateringDue).toList();
    if (duePlants.isEmpty) return;

    for (final plant in duePlants) {
      await _quickWaterPlant(plant);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 All ${duePlants.length} due plants watered! Garden Thriving! 🌟'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety re-initialization check for hot reloads
    try {
      _windCtrl.isAnimating;
    } catch (_) {
      _ambientCtrl = AnimationController(
          vsync: this, duration: const Duration(seconds: 14))
        ..repeat();
      _windCtrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 2800))
        ..repeat(reverse: true);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_plantRepo, _ambientCtrl, _windCtrl]),
              builder: (context, _) {
                final plants = _plantRepo.plants;

                // Watered Today calculation
                final today = DateTime.now();
                final int wateredTodayCount = plants.where((p) {
                  final lw = p.lastWateredDate;
                  return lw.year == today.year &&
                      lw.month == today.month &&
                      lw.day == today.day;
                }).length;

                final int dueCount = plants.where((p) => p.isWateringDue).length;
                final int totalPlants = plants.length;
                final int gardenHealth = plants.isEmpty
                    ? 100
                    : (plants.fold<int>(0, (sum, p) => sum + p.health) / totalPlants).round();
                final int streakDays = _userService.currentUser?.careStreakDays ?? 1;

                return Column(
                  children: [
                    // Top App Header: Wooden Title Sign & Bell
                    _buildGardenHeader(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Eco-Buddy Mascot Advice Banner
                            _buildMascotBanner(dueCount: dueCount, totalPlants: totalPlants),
                            const SizedBox(height: 16),

                            // Quick Stats Row: My Plants | Garden Health | Care Streak
                            _buildStatsRow(
                              plantCount: totalPlants,
                              avgHealth: gardenHealth,
                              streakDays: streakDays,
                            ),
                            const SizedBox(height: 20),

                            // Magical Garden World Section Header
                            _buildSectionHeader(
                              title: '🌿 My Botanical Plots',
                              subtitle: totalPlants > 0
                                  ? '$totalPlants active plant${totalPlants > 1 ? 's' : ''} in your sanctuary'
                                  : 'Start your garden adventure today!',
                            ),
                            const SizedBox(height: 12),

                            // Main Interactive Garden Plots Grid
                            if (totalPlants == 0)
                              _buildEmptyGardenHeroCard()
                            else
                              _buildGardenPlotsGrid(plants),

                            const SizedBox(height: 24),

                            // Today's Mission & Batch Water Quest Card
                            _buildDailyQuestCard(
                              wateredCount: wateredTodayCount,
                              totalPlants: totalPlants,
                              dueCount: dueCount,
                            ),
                            const SizedBox(height: 20),

                            // Pinned "+ Add New Plant" Skeuomorphic Action Button
                            SizedBox(
                              width: double.infinity,
                              child: FunBouncyButton(
                                text: 'Add New Plant',
                                icon: Icons.add_rounded,
                                onPressed: () async {
                                  final added = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => const AddPlantScreen()),
                                  );
                                  if (added == true) _plantRepo.loadLocalData();
                                },
                                color: const Color(0xFF2E7D32),
                                height: 52,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
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
                MaterialPageRoute(builder: (_) => const AIEcoBuddyScreen()),
              );
              break;
            case 4:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  /// Wooden Skinned Top Header
  Widget _buildGardenHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                  ),
                  child: const Text('🌻', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Garden',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B5E20),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Kid-Friendly Botanical Sanctuary',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mascot Eco-Buddy Guidance Banner
  Widget _buildMascotBanner({required int dueCount, required int totalPlants}) {
    String message;
    if (totalPlants == 0) {
      message = "Hi Little Planter! 🌿 Tap 'Add New Plant' below to plant your very first seed!";
    } else if (dueCount > 0) {
      message = "Water Alert! 💧 $dueCount of your plant${dueCount > 1 ? 's need' : ' needs'} water today. Give them love!";
    } else {
      message = "Awesome job! 🌟 Your garden is thriving & fully hydrated today!";
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Image.asset(
              'assets/sprites/mascot_pot_happy.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                size: 40,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SpryBuddy Helper',
                      style: GoogleFonts.fredoka(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE TIP',
                        style: GoogleFonts.nunito(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: SkeuoTheme.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeuomorphic Stats Row: My Plants | Garden Health | Care Streak
  Widget _buildStatsRow({
    required int plantCount,
    required int avgHealth,
    required int streakDays,
  }) {
    return Row(
      children: [
        // My Plants
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'My Plants',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$plantCount',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Garden Health
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💚', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'Garden Health',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$avgHealth%',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Care Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'Care Streak',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${streakDays}d',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Section Header
  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SkeuoTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Main Interactive Kid-Friendly Botanical Plot Grid
  Widget _buildGardenPlotsGrid(List<PlantModel> plants) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: plants.length + 1,
          itemBuilder: (context, index) {
            if (index < plants.length) {
              final plant = plants[index];
              return _buildPlantPlotCard(plant);
            } else {
              return _buildAddPlantPlotCard();
            }
          },
        ),
      ],
    );
  }

  /// Individual Botanical Plot Card
  Widget _buildPlantPlotCard(PlantModel plant) {
    final bool isDue = plant.isWateringDue;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlantDetailsScreen(plantId: plant.id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDue ? const Color(0xFF81C784) : const Color(0xFFE5EBD8),
            width: isDue ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDue
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Grassy plot backdrop
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        color: const Color(0xFFF1F8EE),
                      ),
                    ),
                  ],
                ),
              ),

              // Plant Procedural Growth Animation Artwork
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                bottom: 82,
                child: CustomPaint(
                  painter: ProceduralPlantGrowthPainter(
                    progress: plant.growthProgress,
                    speciesName: plant.speciesName,
                    showPot: false,
                  ),
                ),
              ),

              // Water Status Badge (Top-Right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDue ? const Color(0xFFE53935) : const Color(0xFF03A9F4),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isDue ? '💧 Water Due' : '✨ Hydrated',
                    style: GoogleFonts.fredoka(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Bottom Details & Quick Water Bar
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wooden Plant Stake Plaque
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF795548), Color(0xFF5D4037)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.plantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${plant.speciesName} • ${plant.growthStageName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFECB3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Quick Water Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDue ? const Color(0xFF0288D1) : const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () => _quickWaterPlant(plant),
                        icon: const Icon(Icons.water_drop_rounded, size: 14),
                        label: Text(
                          isDue ? 'Water Now 💧' : 'Water 💧',
                          style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.w800),
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
    );
  }

  /// "+ Plant a New Seed" Interactive Card
  Widget _buildAddPlantPlotCard() {
    return GestureDetector(
      onTap: () async {
        final added = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AddPlantScreen()),
        );
        if (added == true) _plantRepo.loadLocalData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF81C784), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Plant a New Seed',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add plant',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF388E3C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Garden State Hero Card
  Widget _buildEmptyGardenHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Image.asset(
              'assets/sprites/boy_planting.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.nature_people_rounded,
                size: 80,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Garden is Ready! 🌱',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first plant to watch it grow, track hydration, and earn XP milestones!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SkeuoTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          FunBouncyButton(
            text: 'Plant Your First Seed 🌿',
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddPlantScreen()),
              );
              if (added == true) _plantRepo.loadLocalData();
            },
            color: const Color(0xFF2E7D32),
            height: 48,
          ),
        ],
      ),
    );
  }

  /// Today's Mission & Batch Water Quest Card
  Widget _buildDailyQuestCard({
    required int wateredCount,
    required int totalPlants,
    required int dueCount,
  }) {
    final int goal = totalPlants == 0 ? 1 : totalPlants;
    final double pct = (wateredCount / goal).clamp(0.0, 1.0);
    final bool isCompleted = wateredCount >= goal && totalPlants > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                "Today's Daily Quest",
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF43A047) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? '🎉 Complete ($wateredCount/$goal)' : '$wateredCount/$goal Watered',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? Colors.white : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF43A047) : const Color(0xFF66BB6A),
              ),
            ),
          ),
          if (dueCount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _waterAllDuePlants,
                icon: const Icon(Icons.water_drop_rounded, size: 18),
                label: Text(
                  'Water All Due Plants ($dueCount) 💧',
                  style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
