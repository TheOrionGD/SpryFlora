import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/plant_growth_animation.dart';
import 'add_plant_screen.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';
import 'plant_details_screen.dart';
import 'profile_settings_screen.dart';

/// Complete Redesign of My Garden matching the reference image:
/// - Top Bar: Avatar + "My Garden" + Notification Bell + Overhanging leafy branches
/// - Stats Row: "My Plants" count card + "Garden Health" average percentage card
/// - Large 3D Floating Isometric Island with rolling hills backdrop
/// - Rich plants, trees, flowers & sprouts growing directly in the island plots
/// - Mission Card: "Today's Mission" (Watering goal + progress bar) & "Next Reward" (Mystery Seed)
/// - Pinned "+ Add New Plant" Button
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

  @override
  Widget build(BuildContext context) {
    // Safety check for hot reloads
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
      backgroundColor: const Color(0xFFD7F0E5),
      body: AnimatedBuilder(
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

          // Goal based strictly on total plant count
          final int missionGoal = plants.isEmpty ? 1 : plants.length;
          final int missionProgress = math.min(wateredTodayCount, missionGoal);

          // Garden Health calculated directly from the hydration rate
          final int gardenHealth = plants.isEmpty
              ? 100
              : ((wateredTodayCount / plants.length) * 100).round();

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Scenic Sunny Meadow & Distant Hills Landscape
              const Positioned.fill(
                child: _GardenScenicBackdrop(),
              ),

              // 2. Overhanging Leaf Vines in top corners
              Positioned(
                top: 0,
                left: 0,
                child: _buildCornerLeaves(isLeft: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _buildCornerLeaves(isLeft: false),
              ),

              // 3. Scrollable Page Content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Title & Subtitle
                    _buildGardenTitle(),

                    const SizedBox(height: 10),

                    // Quick Stats Row: My Plants (count) & Garden Health (%)
                    _buildStatsRow(
                        plantCount: plants.length, avgHealth: gardenHealth),

                    const SizedBox(height: 6),

                    // Center: Large 3D Isometric Island
                    Expanded(
                      child: Center(
                        child: _LargeIsometricIsland(
                          plants: plants,
                          windValue: _windCtrl.value,
                          ambientValue: _ambientCtrl.value,
                          onPlantTap: (plant) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlantDetailsScreen(plantId: plant.id),
                              ),
                            );
                          },
                          onAddSeedTap: () async {
                            final added =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) => const AddPlantScreen()),
                            );
                            if (added == true) _plantRepo.loadLocalData();
                          },
                        ),
                      ),
                    ),

                    // Bottom Section: Mission Card & "+ Add New Plant" Action Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Today's Mission Card (Next Reward removed)
                          _buildMissionRewardCard(
                            progress: missionProgress,
                            goal: missionGoal,
                          ),

                          const SizedBox(height: 10),

                          // Pinned "+ Add New Plant" Skeuomorphic Button
                          _buildAddPlantButton(),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
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
            case 3:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  /// Reference Header Title
  Widget _buildGardenTitle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍃', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 4),
            Text(
              'My Garden',
              style: GoogleFonts.fredoka(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B5E20),
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Grow plants, collect friends &\nmake your garden beautiful',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Reference Stats Row: My Plants card & Garden Health card
  Widget _buildStatsRow({required int plantCount, required int avgHealth}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Left: My Plants
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🌱', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Plants',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF558B2F),
                        ),
                      ),
                      Text(
                        '$plantCount',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right: Garden Health
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('💚', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garden Health',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF558B2F),
                        ),
                      ),
                      Text(
                        '$avgHealth%',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Today's Mission Card (Focused purely on daily watering goal)
  Widget _buildMissionRewardCard({required int progress, required int goal}) {
    final double pct = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 1.0;
    final bool isCompleted = progress >= goal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    "Today's Mission",
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784), width: 1),
                ),
                child: Text(
                  isCompleted
                      ? '🎉 Completed ($progress/$goal)'
                      : '$progress/$goal Watered',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? Colors.white : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  goal == 1
                      ? 'Water your plant to keep the garden green & healthy!'
                      : 'Water all $goal plants today to maintain 100% garden health!',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF558B2F),
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
        ],
      ),
    );
  }

  /// Pinned "+ Add New Plant" Button
  Widget _buildAddPlantButton() {
    return GestureDetector(
      onTap: () async {
        final added = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AddPlantScreen()),
        );
        if (added == true) _plantRepo.loadLocalData();
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF43A047),
              Color(0xFF2E7D32),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              'Add New Plant',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decorative Leaf Vines in top corners
  Widget _buildCornerLeaves({required bool isLeft}) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 0.9,
            colors: [
              const Color(0xFF43A047).withValues(alpha: 0.85),
              const Color(0xFF2E7D32).withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _VineLeavesPainter(),
        ),
      ),
    );
  }
}

/// Large 3D Isometric Island Component
class _LargeIsometricIsland extends StatelessWidget {
  final List<PlantModel> plants;
  final double windValue;
  final double ambientValue;
  final Function(PlantModel) onPlantTap;
  final VoidCallback onAddSeedTap;

  const _LargeIsometricIsland({
    required this.plants,
    required this.windValue,
    required this.ambientValue,
    required this.onPlantTap,
    required this.onAddSeedTap,
  });

  // 4x4 Grid for rich spacious island matching reference!
  static const int gridSize = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enlarge island width to fill 98% of container up to 520px!
        final double islandWidth = math.min(constraints.maxWidth * 0.98, 520.0);
        final double islandHeight = islandWidth * 0.85;

        final double tileW = islandWidth / gridSize;
        final double tileH = tileW * 0.50;

        final double originX = islandWidth / 2;
        final double originY = islandHeight * 0.20;

        // Build list of tile slots sorted by (col + row) for 2.5D depth ordering
        final List<_PlotSlot> slots = [];
        int plantIndex = 0;

        for (int row = 0; row < gridSize; row++) {
          for (int col = 0; col < gridSize; col++) {
            final double posX = originX + (col - row) * (tileW / 2);
            final double posY = originY + (col + row) * (tileH / 2);
            final int depth = col + row;

            PlantModel? plant;
            bool isAddSlot = false;

            if (plantIndex < plants.length) {
              plant = plants[plantIndex];
              plantIndex++;
            } else if (plantIndex == plants.length) {
              isAddSlot = true;
              plantIndex++;
            }

            slots.add(_PlotSlot(
              col: col,
              row: row,
              posX: posX,
              posY: posY,
              depth: depth,
              plant: plant,
              isAddSlot: isAddSlot,
            ));
          }
        }

        // Sort by depth so background tiles render first
        slots.sort((a, b) => a.depth.compareTo(b.depth));

        return SizedBox(
          width: islandWidth,
          height: islandHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Large 3D Isometric Island Base with Cliff Depth & Shadow
              Positioned.fill(
                child: CustomPaint(
                  painter: _LargeIsometricIslandPainter(
                    gridSize: gridSize,
                    originX: originX,
                    originY: originY,
                    tileW: tileW,
                    tileH: tileH,
                  ),
                ),
              ),

              // 2. Plants & Interactive Plots placed in 2.5D Isometric Space
              ...slots.map((slot) {
                if (slot.plant != null) {
                  return _buildIsometricPlantItem(
                    slot: slot,
                    tileW: tileW,
                    tileH: tileH,
                  );
                } else if (slot.isAddSlot) {
                  return _buildIsometricAddSeedItem(
                    slot: slot,
                    tileW: tileW,
                    tileH: tileH,
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
        );
      },
    );
  }

  /// Plant Item on the Isometric Island Plot
  Widget _buildIsometricPlantItem({
    required _PlotSlot slot,
    required double tileW,
    required double tileH,
  }) {
    final plant = slot.plant!;
    final double itemWidth = tileW * 1.25;
    final double itemHeight = tileW * 1.45;

    // Organic Wind Sway oscillation
    final double swayAngle =
        math.sin((windValue * math.pi * 2) + (slot.depth * 1.2)) * 0.05;

    return Positioned(
      left: slot.posX - (itemWidth / 2),
      top: slot.posY - itemHeight + (tileH * 0.72),
      width: itemWidth,
      height: itemHeight,
      child: GestureDetector(
        onTap: () => onPlantTap(plant),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Plant Artwork rooted in grass tile (No Pot!)
            Positioned(
              bottom: 14,
              child: Transform.rotate(
                angle: swayAngle,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: itemWidth * 0.95,
                  height: itemHeight * 0.72,
                  child: CustomPaint(
                    painter: ProceduralPlantGrowthPainter(
                      progress: plant.growthProgress,
                      speciesName: plant.speciesName,
                      showPot: false,
                    ),
                  ),
                ),
              ),
            ),

            // Plant Name Plaque
            Positioned(
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D4C41), Color(0xFF4E342E)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  plant.plantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "+ Plant Seed" Plot Tile
  Widget _buildIsometricAddSeedItem({
    required _PlotSlot slot,
    required double tileW,
    required double tileH,
  }) {
    return Positioned(
      left: slot.posX - (tileW * 0.38),
      top: slot.posY - (tileH * 0.38),
      width: tileW * 0.76,
      height: tileH * 0.76,
      child: GestureDetector(
        onTap: onAddSeedTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.35),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Text('🌱', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _PlotSlot {
  final int col;
  final int row;
  final double posX;
  final double posY;
  final int depth;
  final PlantModel? plant;
  final bool isAddSlot;

  _PlotSlot({
    required this.col,
    required this.row,
    required this.posX,
    required this.posY,
    required this.depth,
    this.plant,
    this.isAddSlot = false,
  });
}

/// Large 3D Isometric Island Base Painter with Organic Lawn & Cliff Strata
class _LargeIsometricIslandPainter extends CustomPainter {
  final int gridSize;
  final double originX;
  final double originY;
  final double tileW;
  final double tileH;

  _LargeIsometricIslandPainter({
    required this.gridSize,
    required this.originX,
    required this.originY,
    required this.tileW,
    required this.tileH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double islandCliffDepth = tileH * 1.8;

    // Corner points of the isometric top diamond
    final topPoint = Offset(originX, originY);
    final rightPoint = Offset(
        originX + gridSize * (tileW / 2), originY + gridSize * (tileH / 2));
    final bottomPoint = Offset(originX, originY + gridSize * tileH);
    final leftPoint = Offset(
        originX - gridSize * (tileW / 2), originY + gridSize * (tileH / 2));

    // 1. Soft Ambient Floating Shadow beneath island
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B4332).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    final shadowPath = Path()
      ..moveTo(leftPoint.dx * 0.96, bottomPoint.dy + islandCliffDepth + 12)
      ..lineTo(originX, bottomPoint.dy + islandCliffDepth + 32)
      ..lineTo(rightPoint.dx * 1.04, bottomPoint.dy + islandCliffDepth + 12)
      ..lineTo(originX, bottomPoint.dy + islandCliffDepth - 10)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Left Cliff Strata (Earth & Clay layers)
    final leftCliffPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6D4C41),
          Color(0xFF5D4037),
          Color(0xFF4E342E),
          Color(0xFF3E2723),
        ],
      ).createShader(Rect.fromLTWH(leftPoint.dx, bottomPoint.dy,
          originX - leftPoint.dx, islandCliffDepth));

    final leftCliffPath = Path()
      ..moveTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(bottomPoint.dx, bottomPoint.dy)
      ..lineTo(bottomPoint.dx, bottomPoint.dy + islandCliffDepth)
      ..lineTo(leftPoint.dx, leftPoint.dy + islandCliffDepth)
      ..close();
    canvas.drawPath(leftCliffPath, leftCliffPaint);

    // 3. Right Cliff Strata (Darker shaded Earth layer)
    final rightCliffPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5D4037),
          Color(0xFF4E342E),
          Color(0xFF3E2723),
          Color(0xFF27150F),
        ],
      ).createShader(Rect.fromLTWH(
          originX, bottomPoint.dy, rightPoint.dx - originX, islandCliffDepth));

    final rightCliffPath = Path()
      ..moveTo(bottomPoint.dx, bottomPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy + islandCliffDepth)
      ..lineTo(bottomPoint.dx, bottomPoint.dy + islandCliffDepth)
      ..close();
    canvas.drawPath(rightCliffPath, rightCliffPaint);

    // 4. Overhanging Jagged Grass Fringe along cliff edge
    final fringePaint = Paint()..color = const Color(0xFF689F38);
    for (double i = 0; i <= 1.0; i += 0.04) {
      final lx = leftPoint.dx + (bottomPoint.dx - leftPoint.dx) * i;
      final ly = leftPoint.dy + (bottomPoint.dy - leftPoint.dy) * i;
      canvas.drawCircle(Offset(lx, ly + 3.5), 5.0, fringePaint);

      final rx = bottomPoint.dx + (rightPoint.dx - bottomPoint.dx) * i;
      final ry = bottomPoint.dy + (rightPoint.dy - bottomPoint.dy) * i;
      canvas.drawCircle(Offset(rx, ry + 3.5), 5.0, fringePaint);
    }

    // 5. UNIFIED NATURAL LAWN (Smooth organic garden lawn, NO chess board!)
    final lawnPath = Path()
      ..moveTo(topPoint.dx, topPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..lineTo(bottomPoint.dx, bottomPoint.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..close();

    final lawnPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFAED581), // Sunlight top green
          Color(0xFF9CCC65),
          Color(0xFF8BC34A),
          Color(0xFF7CB342), // Rich foreground green
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(leftPoint.dx, topPoint.dy,
          rightPoint.dx - leftPoint.dx, bottomPoint.dy - topPoint.dy));

    canvas.drawPath(lawnPath, lawnPaint);

    // 6. Natural Grass Tufts, Clover & Daisies sprinkled organically across the lawn
    final tuftPaint = Paint()
      ..color = const Color(0xFF558B2F).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final flowerWhite = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final flowerYellow = Paint()..color = const Color(0xFFFFD54F);

    void drawDaisy(double dx, double dy) {
      canvas.drawCircle(Offset(dx, dy), 3.0, flowerWhite);
      canvas.drawCircle(Offset(dx, dy), 1.5, flowerYellow);
    }

    void drawGrassTuft(double cx, double cy) {
      canvas.drawLine(Offset(cx - 3, cy), Offset(cx - 5, cy - 4), tuftPaint);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 5), tuftPaint);
      canvas.drawLine(Offset(cx + 3, cy), Offset(cx + 5, cy - 4), tuftPaint);
    }

    // Organic distribution across the lawn
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cx = originX + (col - row) * (tileW / 2);
        final cy = originY + (col + row) * (tileH / 2) + (tileH * 0.45);

        if ((col + row) % 2 == 0) {
          drawGrassTuft(cx - 8, cy - 4);
          drawDaisy(cx + 10, cy + 2);
        } else {
          drawGrassTuft(cx + 6, cy - 2);
          drawDaisy(cx - 12, cy - 6);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LargeIsometricIslandPainter oldDelegate) =>
      false;
}

/// Scenic Sunny Meadow & Distant Hills Landscape Painter
class _GardenScenicBackdrop extends StatelessWidget {
  const _GardenScenicBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/sprites/image.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF90CAF9),
                  Color(0xFFC8E6C9),
                  Color(0xFFA5D6A7),
                  Color(0xFF81C784),
                ],
              ),
            ),
          ),
        ),
        CustomPaint(
          painter: _DistantHillsPainter(),
        ),
      ],
    );
  }
}

/// Distant Green Hills & Rolling Meadow Horizon
class _DistantHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Distant soft blue-green mountains
    final mountainPaint = Paint()
      ..color = const Color(0xFF80CBC4).withValues(alpha: 0.45);
    final mountainPath = Path()
      ..moveTo(0, size.height * 0.32)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.25,
          size.width * 0.45, size.height * 0.30)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.24, size.width, size.height * 0.28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Fluffy clouds in sky
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);
    void drawCloud(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r, cloudPaint);
      canvas.drawCircle(
          Offset(cx + r * 0.7, cy - r * 0.2), r * 0.8, cloudPaint);
      canvas.drawCircle(Offset(cx + r * 1.4, cy), r * 0.7, cloudPaint);
    }

    drawCloud(size.width * 0.15, size.height * 0.12, 18);
    drawCloud(size.width * 0.75, size.height * 0.10, 22);
  }

  @override
  bool shouldRepaint(covariant _DistantHillsPainter oldDelegate) => false;
}

/// Corner Decorative Vine Leaves
class _VineLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.9);

    void drawLeaf(double x, double y, double angle, double scale) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(14 * scale, -8 * scale, 28 * scale, 0)
        ..quadraticBezierTo(14 * scale, 8 * scale, 0, 0);
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    drawLeaf(10, 15, 0.4, 1.2);
    drawLeaf(30, 25, 0.8, 1.0);
    drawLeaf(45, 12, 0.2, 0.9);
    drawLeaf(15, 45, 1.2, 1.1);
  }

  @override
  bool shouldRepaint(covariant _VineLeavesPainter oldDelegate) => false;
}
