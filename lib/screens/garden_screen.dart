import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/app_photo_view.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';
import 'plant_details_screen.dart';
import 'profile_settings_screen.dart';
import 'ai_eco_buddy_screen.dart';
import 'notification_center_screen.dart';
import 'realtime_plant_scanner_screen.dart';
import 'virtual_garden_screen.dart';
import '../models/garden_season.dart';

/// Kid-Friendly Magical Garden Screen
/// Lists user plants in their current state (growth stage, health, hydration, age),
/// includes quick-watering actions, daily quest progression, and a portal button
/// to open the full 3D Botanical Sanctuary (Virtual View).
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

  late GardenSeason _currentSeason;
  String _filterStatus = 'all'; // 'all', 'due', 'healthy'

  @override
  void initState() {
    super.initState();
    _currentSeason = GardenSeason.currentForDate(DateTime.now());
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

  List<PlantModel> _getFilteredPlants(List<PlantModel> allPlants) {
    if (_filterStatus == 'due') {
      return allPlants.where((p) => p.isWateringDue).toList();
    } else if (_filterStatus == 'healthy') {
      return allPlants.where((p) => p.health >= 80).toList();
    }
    return allPlants;
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _currentSeason.skyGradient,
          ),
        ),
        child: LeavesParticleOverlay(
          maxThroughput: true,
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
                final int healthyCount = plants.where((p) => p.health >= 80).length;
                final int totalPlants = plants.length;
                final int gardenHealth = plants.isEmpty
                    ? 0
                    : (plants.fold<int>(0, (sum, p) => sum + p.health) / totalPlants).round();
                final int streakDays = _userService.currentUser?.careStreakDays ?? 0;
                final filteredPlants = _getFilteredPlants(plants);

                return Column(
                  children: [
                    // Top App Header: Wooden Title Sign & Notifications
                    _buildGardenHeader(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Eco-Buddy Mascot Advice Banner
                            _buildMascotBanner(dueCount: dueCount, totalPlants: totalPlants),
                            const SizedBox(height: 14),

                            // Quick Stats Row: My Plants | Garden Health | Care Streak
                            _buildStatsRow(
                              plantCount: totalPlants,
                              avgHealth: gardenHealth,
                              streakDays: streakDays,
                            ),
                            const SizedBox(height: 18),

                            // ── Botanical Sanctuary Virtual View Portal Card ──
                            _buildBotanicalSanctuaryPortalCard(totalPlants: totalPlants),
                            const SizedBox(height: 20),

                            // ── Plant Collection Header & Filter Chips ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🌱 Plant Collection',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1B5E20),
                                      ),
                                    ),
                                    Text(
                                      'Live growth state, health & watering status',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: SkeuoTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
                                  ),
                                  child: Text(
                                    '$totalPlants total',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Filter Chips Row
                            if (totalPlants > 0)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label: 'All Plants ($totalPlants)',
                                      value: 'all',
                                      icon: '🌿',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                      label: 'Needs Water ($dueCount)',
                                      value: 'due',
                                      icon: '💧',
                                      highlightColor: const Color(0xFF0288D1),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                      label: 'Thriving ($healthyCount)',
                                      value: 'healthy',
                                      icon: '✨',
                                      highlightColor: const Color(0xFF2E7D32),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),

                            // ── Plants State List ──
                            if (totalPlants == 0)
                              _buildEmptyGardenHeroCard()
                            else if (filteredPlants.isEmpty)
                              _buildNoFilteredResultsCard()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredPlants.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return _buildPlantStateCard(filteredPlants[index]);
                                },
                              ),

                            const SizedBox(height: 20),

                            // Today's Mission & Batch Water Quest Card
                            _buildDailyQuestCard(
                              wateredCount: wateredTodayCount,
                              totalPlants: totalPlants,
                              dueCount: dueCount,
                            ),
                            const SizedBox(height: 18),

                            // "+ Add New Plant" Action Button
                            SizedBox(
                              width: double.infinity,
                              child: FunBouncyButton(
                                text: 'Add New Plant',
                                icon: Icons.add_rounded,
                                onPressed: () async {
                                  final added = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
                                  );
                                  if (added == true) _plantRepo.loadLocalData();
                                },
                                color: const Color(0xFF2E7D32),
                                height: 50,
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
                      'Live Botanical Sanctuary & Plant Status',
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

  /// Botanical Sanctuary Portal Card leading to Virtual View
  Widget _buildBotanicalSanctuaryPortalCard({required int totalPlants}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative leaves
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.park_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Text('🏝️', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Botanical Sanctuary',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Interactive 3D seasonal floating island with pinch-to-zoom and weather atmosphere.',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalPlants plant${totalPlants == 1 ? '' : 's'} on island',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA5D6A7),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF2E4032),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VirtualGardenScreen()),
                        );
                      },
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      label: Text(
                        'Virtual View 🏝️',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter Chip Widget
  Widget _buildFilterChip({
    required String label,
    required String value,
    required String icon,
    Color? highlightColor,
  }) {
    final bool isSelected = _filterStatus == value;
    final color = highlightColor ?? const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFC8E6C9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF2E4032),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rich Plant Card displaying plant in its current live state
  Widget _buildPlantStateCard(PlantModel plant) {
    final bool isDue = plant.isWateringDue;
    final int age = plant.ageInDays;
    final int health = plant.health;
    final String stageName = plant.growthStageName;

    // Health styling
    Color healthColor = const Color(0xFF43A047);
    String healthEmoji = '💚';
    String healthLabel = 'Thriving';
    if (health < 50) {
      healthColor = const Color(0xFFE53935);
      healthEmoji = '⚠️';
      healthLabel = 'Needs Attention';
    } else if (health < 75) {
      healthColor = const Color(0xFFFB8C00);
      healthEmoji = '💛';
      healthLabel = 'Fair';
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlantDetailsScreen(plantId: plant.id)),
        );
        _plantRepo.loadLocalData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDue ? const Color(0xFF81C784) : const Color(0xFFE5EBD8),
            width: isDue ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDue
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Photo, Name, Species, Water Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant Thumbnail / Photo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppPhotoView(
                        imagePath: plant.initialPhotoPath,
                        fit: BoxFit.cover,
                        fallback: Image.asset(
                          'assets/sprites/mascot_pot_winking.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.spa_rounded,
                            color: SkeuoTheme.primaryGreen,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plant.plantName,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B5E20),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          plant.speciesName,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF388E3C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '📍 ${plant.location}',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🌱 $stageName',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Water status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDue ? const Color(0xFFE53935) : const Color(0xFF0288D1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isDue ? '💧 Water Due' : '✨ Hydrated',
                      style: GoogleFonts.fredoka(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Health Indicator Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(healthEmoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            'Health: $healthLabel ($health%)',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: healthColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Age: $age ${age == 1 ? 'day' : 'days'}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SkeuoTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (health / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8F5E9),
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Quick Actions Bar
              Row(
                children: [
                  // Care Info Text
                  Expanded(
                    child: Text(
                      isDue
                          ? 'Needs water today to stay healthy!'
                          : 'Next watering in ${plant.wateringIntervalDays} days',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDue ? const Color(0xFFC62828) : SkeuoTheme.textSecondary,
                      ),
                    ),
                  ),

                  // Quick Water Button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDue ? const Color(0xFF0288D1) : const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                      onPressed: () => _quickWaterPlant(plant),
                      icon: const Icon(Icons.water_drop_rounded, size: 14),
                      label: Text(
                        isDue ? 'Water Now 💧' : 'Water 💧',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      message = "All plants hydrated! 🌟 Your garden is thriving. Check the Botanical Sanctuary virtual view!";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Image.asset(
              'assets/sprites/mascot_pot_winking.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Eco-Buddy Advice',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
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
                    fontSize: 12,
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

  /// Empty Garden State Hero Card
  Widget _buildEmptyGardenHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/sprites/boy_planting.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.nature_people_rounded,
                size: 70,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your Garden is Ready! 🌱',
            style: GoogleFonts.fredoka(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first plant to watch it grow, track hydration, and earn XP milestones!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: SkeuoTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          FunBouncyButton(
            text: 'Plant Your First Seed 🌿',
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
              );
              if (added == true) _plantRepo.loadLocalData();
            },
            color: const Color(0xFF2E7D32),
            height: 46,
          ),
        ],
      ),
    );
  }

  /// No filtered results
  Widget _buildNoFilteredResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'No plants match this filter',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _filterStatus = 'all'),
            child: Text(
              'View All Plants',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E7D32),
              ),
            ),
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
        borderRadius: BorderRadius.circular(20),
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
              minHeight: 8,
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
