import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_season.dart';
import '../models/plant_model.dart';
import '../theme/skeuo_theme.dart';
import 'app_photo_view.dart';
import '../screens/plant_details_screen.dart';

/// Whimsical Isometric 3D Floating Botanical Garden Island
/// Modeled after the hand-drawn isometric garden artwork with dynamic seasonal backgrounds,
/// animated floating hearts, musical notes, birds, clouds, moon/sun, and interactive plants.
class IsometricGardenIsland extends StatefulWidget {
  final List<PlantModel> userPlants;
  final GardenSeason season;
  final Function(PlantModel plant)? onWaterPlant;
  final VoidCallback? onAddPlant;

  const IsometricGardenIsland({
    super.key,
    required this.userPlants,
    this.season = GardenSeason.autumn,
    this.onWaterPlant,
    this.onAddPlant,
  });

  @override
  State<IsometricGardenIsland> createState() => _IsometricGardenIslandState();
}

class _IsometricGardenIslandState extends State<IsometricGardenIsland>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _birdsCtrl;
  late AnimationController _notesCtrl;
  late AnimationController _cloudsCtrl;

  int? _selectedTileIndex;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _birdsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _notesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _cloudsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _birdsCtrl.dispose();
    _notesCtrl.dispose();
    _cloudsCtrl.dispose();
    super.dispose();
  }

  void _handleTileTap(int index, PlantModel? plant) {
    setState(() {
      _selectedTileIndex = index;
    });

    if (plant != null) {
      _showPlantDetailModal(plant);
    } else if (widget.onAddPlant != null) {
      widget.onAddPlant!();
    }
  }

  void _showPlantDetailModal(PlantModel plant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal drag handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Photo + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Captured Photo Preview Thumbnail
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppPhotoView(
                        imagePath: plant.initialPhotoPath,
                        fit: BoxFit.cover,
                        fallback: Image.asset(
                          'assets/sprites/mascot_pot_winking.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name, Species, Health
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.plantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${plant.speciesName} • ${plant.growthStageName}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SkeuoTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      size: 13, color: Color(0xFFE53935)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${plant.health}% Health',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: plant.isWateringDue
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFE1F5FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                plant.isWateringDue ? '💧 Water Due' : '✨ Hydrated',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: plant.isWateringDue
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF0277BD),
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
              const SizedBox(height: 20),

              // Action Buttons: Quick Water + Open Full Profile
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03A9F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (widget.onWaterPlant != null) {
                          widget.onWaterPlant!(plant);
                        }
                      },
                      icon: const Icon(Icons.water_drop_rounded, size: 18),
                      label: Text(
                        'Water Plant',
                        style: GoogleFonts.fredoka(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SkeuoTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlantDetailsScreen(plantId: plant.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: Text(
                        'Full Profile',
                        style: GoogleFonts.fredoka(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _birdsCtrl, _notesCtrl, _cloudsCtrl]),
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: 440,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.season.skyGradient,
              ),
            ),
            child: Stack(
              children: [
                // 1. Celestial Accent (Crescent Moon with Clover or Radiant Sun)
                Positioned(
                  top: 18,
                  right: 28,
                  child: _buildCelestialBody(widget.season),
                ),

                // 2. Drifting Fluffy Cloud
                Positioned(
                  top: 55,
                  left: -80 + (_cloudsCtrl.value * (MediaQuery.of(context).size.width + 160)) %
                      (MediaQuery.of(context).size.width + 200),
                  child: _buildCloud(),
                ),

                // 3. Silhouetted Flying Birds
                Positioned(
                  top: 75 + math.sin(_birdsCtrl.value * math.pi * 2) * 12,
                  left: 30 + ((1.0 - _birdsCtrl.value) * 220),
                  child: _buildFlyingBirds(),
                ),

                // 4. Corner Foliage with Water Dewdrops (from reference image)
                Positioned(
                  top: -15,
                  left: -15,
                  child: _buildCornerDewdropFoliage(widget.season),
                ),

                // 5. Floating Isometric Garden Island Painter & Gesture Layer
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPos = details.localPosition;
                        _detectIslandTap(localPos, box.size);
                      }
                    },
                    child: CustomPaint(
                      painter: _IsometricIslandPainter(
                        season: widget.season,
                        userPlants: widget.userPlants,
                        floatProgress: _floatCtrl.value,
                        notesProgress: _notesCtrl.value,
                        selectedTileIndex: _selectedTileIndex,
                      ),
                    ),
                  ),
                ),

                // 6. Floating Season Badge (Top Right Pill)
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.season.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.season.displayName} Sanctuary',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E4032),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _detectIslandTap(Offset localPos, Size size) {
    // 5x5 isometric grid mapping
    const int gridSize = 5;
    final center = Offset(size.width / 2, size.height * 0.58);
    const tileW = 44.0;
    const tileH = 22.0;

    int? hitIndex;
    double minDistance = 28.0;

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        final isoX = center.dx + (gx - gy) * (tileW / 2);
        final isoY = center.dy + (gx + gy) * (tileH / 2);

        final dist = (localPos - Offset(isoX, isoY)).distance;
        if (dist < minDistance) {
          minDistance = dist;
          hitIndex = gy * gridSize + gx;
        }
      }
    }

    if (hitIndex != null) {
      PlantModel? plant;
      if (hitIndex < widget.userPlants.length) {
        plant = widget.userPlants[hitIndex];
      }
      _handleTileTap(hitIndex, plant);
    }
  }

  /// Stylized Crescent Moon with Lucky Leaf charm (from reference image) or Sun
  Widget _buildCelestialBody(GardenSeason season) {
    if (season == GardenSeason.winter || season == GardenSeason.autumn) {
      // Whimsical golden crescent moon with green clover leaf
      return SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Crescent Moon
            CustomPaint(
              size: const Size(60, 60),
              painter: _CrescentMoonPainter(color: const Color(0xFFFFE066)),
            ),
            // Lucky Clover Leaf Charm on moon tip
            Positioned(
              top: 4,
              right: 6,
              child: Transform.rotate(
                angle: 0.35,
                child: const Text('🍀', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Radiant Golden Sun
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFE082).withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      );
    }
  }

  /// Fluffy White Organic Cloud
  Widget _buildCloud() {
    return Container(
      width: 140,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  /// Flying silhouettes of 2 birds
  Widget _buildFlyingBirds() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.15,
          child: const Text('🕊️', style: TextStyle(fontSize: 16, color: Color(0xFF263238))),
        ),
        const SizedBox(width: 8),
        Transform.translate(
          offset: const Offset(0, -6),
          child: const Text('🕊️', style: TextStyle(fontSize: 12, color: Color(0xFF37474F))),
        ),
      ],
    );
  }

  /// Artistic Oak / Botanical Leaf with Dewdrops (Top-left from reference image)
  Widget _buildCornerDewdropFoliage(GardenSeason season) {
    Color leafColor;
    switch (season) {
      case GardenSeason.autumn:
        leafColor = const Color(0xFFD36F3B); // Terracotta oak leaf
        break;
      case GardenSeason.spring:
        leafColor = const Color(0xFF7CB342);
        break;
      case GardenSeason.summer:
        leafColor = const Color(0xFF388E3C);
        break;
      case GardenSeason.winter:
        leafColor = const Color(0xFF5A7D6C);
        break;
    }

    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _CornerLeafPainter(leafColor: leafColor),
      ),
    );
  }
}

/// CustomPainter for Crescent Moon
class _CrescentMoonPainter extends CustomPainter {
  final Color color;
  _CrescentMoonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: Offset(size.width * 0.45, size.height * 0.5), radius: size.width * 0.45),
      -math.pi / 2,
      math.pi,
    );
    path.arcToPoint(
      Offset(size.width * 0.45, size.height * 0.05),
      radius: Radius.circular(size.width * 0.42),
      clockwise: false,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrescentMoonPainter oldDelegate) => false;
}

/// CustomPainter for Corner Oak Leaf with Water Droplets
class _CornerLeafPainter extends CustomPainter {
  final Color leafColor;
  _CornerLeafPainter({required this.leafColor});

  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = leafColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.7, 10, size.width * 0.85, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.9, 0, size.height * 0.8);
    path.close();

    canvas.drawPath(path, leafPaint);

    // Leaf Veins
    final veinPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.75, size.height * 0.6), veinPaint);

    // Dewdrops
    final dropPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.35), 7, dropPaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.45), 5.5, dropPaint);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.5), 4, dropPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerLeafPainter oldDelegate) => oldDelegate.leafColor != leafColor;
}

/// Isometric Garden Island Painter
class _IsometricIslandPainter extends CustomPainter {
  final GardenSeason season;
  final List<PlantModel> userPlants;
  final double floatProgress;
  final double notesProgress;
  final int? selectedTileIndex;

  _IsometricIslandPainter({
    required this.season,
    required this.userPlants,
    required this.floatProgress,
    required this.notesProgress,
    this.selectedTileIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Floating breathing bounce (up to 6 pixels vertical bob)
    final floatY = math.sin(floatProgress * math.pi) * 6.0;

    final center = Offset(size.width / 2, (size.height * 0.56) + floatY);
    const int gridSize = 5;
    const double tileW = 44.0;
    const double tileH = 22.0;

    // 1. Island Floating Soft Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final shadowPath = Path();
    shadowPath.moveTo(center.dx, center.dy + 72);
    shadowPath.lineTo(center.dx + (gridSize * tileW * 0.55), center.dy + 72 + (gridSize * tileH * 0.5));
    shadowPath.lineTo(center.dx, center.dy + 72 + (gridSize * tileH * 1.05));
    shadowPath.lineTo(center.dx - (gridSize * tileW * 0.55), center.dy + 72 + (gridSize * tileH * 0.5));
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Island Extrusion Base Depth (Soil layer)
    final soilPaint = Paint()
      ..color = season.islandSoilColor
      ..style = PaintingStyle.fill;

    final soilPath = Path();
    // Left bottom skirt
    soilPath.moveTo(center.dx - (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    soilPath.lineTo(center.dx, center.dy + (gridSize * tileH));
    soilPath.lineTo(center.dx + (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    // Extrude down by 26 px
    soilPath.lineTo(center.dx + (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5) + 26);
    soilPath.lineTo(center.dx, center.dy + (gridSize * tileH) + 26);
    soilPath.lineTo(center.dx - (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5) + 26);
    soilPath.close();
    canvas.drawPath(soilPath, soilPaint);

    // 3. Island Bevel Rim (Translucent rim tier)
    final bevelPaint = Paint()
      ..color = season.islandBevelColor
      ..style = PaintingStyle.fill;

    final bevelPath = Path();
    bevelPath.moveTo(center.dx - (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    bevelPath.lineTo(center.dx, center.dy + (gridSize * tileH));
    bevelPath.lineTo(center.dx + (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    bevelPath.lineTo(center.dx + (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5) + 8);
    bevelPath.lineTo(center.dx, center.dy + (gridSize * tileH) + 8);
    bevelPath.lineTo(center.dx - (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5) + 8);
    bevelPath.close();
    canvas.drawPath(bevelPath, bevelPaint);

    // 4. Island Top Surface (Grass Polygon with Rounded Isometric Feel)
    final surfacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: season.islandSurfaceColors,
      ).createShader(Rect.fromCenter(center: center, width: 260, height: 180))
      ..style = PaintingStyle.fill;

    final surfacePath = Path();
    surfacePath.moveTo(center.dx, center.dy);
    surfacePath.lineTo(center.dx + (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    surfacePath.lineTo(center.dx, center.dy + (gridSize * tileH));
    surfacePath.lineTo(center.dx - (gridSize * tileW * 0.5), center.dy + (gridSize * tileH * 0.5));
    surfacePath.close();
    canvas.drawPath(surfacePath, surfacePaint);

    // 5. Grid Tiles Lines
    final gridLinePaint = Paint()
      ..color = season.islandGridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < gridSize; i++) {
      // Lines from top-right to bottom-left
      final p1 = Offset(center.dx + i * (tileW / 2), center.dy + i * (tileH / 2));
      final p2 = Offset(p1.dx - gridSize * (tileW / 2), p1.dy + gridSize * (tileH / 2));
      canvas.drawLine(p1, p2, gridLinePaint);

      // Lines from top-left to bottom-right
      final q1 = Offset(center.dx - i * (tileW / 2), center.dy + i * (tileH / 2));
      final q2 = Offset(q1.dx + gridSize * (tileW / 2), q1.dy + gridSize * (tileH / 2));
      canvas.drawLine(q1, q2, gridLinePaint);
    }

    // 6. Draw Flora & Trees in Isometric Depth Order (Back to Front: gx + gy)
    final List<Map<String, dynamic>> items = [];
    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        final index = gy * gridSize + gx;
        final isoPos = Offset(
          center.dx + (gx - gy) * (tileW / 2),
          center.dy + (gx + gy) * (tileH / 2) + (tileH / 2),
        );

        items.add({
          'depth': gx + gy,
          'gx': gx,
          'gy': gy,
          'index': index,
          'pos': isoPos,
        });
      }
    }

    // Sort strictly by depth so foreground trees occlude background trees correctly
    items.sort((a, b) => (a['depth'] as int).compareTo(b['depth'] as int));

    for (final item in items) {
      final int index = item['index'] as int;
      final Offset pos = item['pos'] as Offset;
      final int gx = item['gx'] as int;
      final int gy = item['gy'] as int;

      PlantModel? userPlant;
      if (index < userPlants.length) {
        userPlant = userPlants[index];
      }

      // Draw flora / user plant / empty soil plot based on user input
      _drawBotanicalFlora(canvas, pos, gx, gy, index, userPlant, tileW, tileH);

      // Selected Tile Highlight
      if (selectedTileIndex == index) {
        _drawTileHighlight(canvas, pos, tileW, tileH);
      }
    }

    // 7. Floating Musical Notes near trees (Dancing red notes from reference image)
    _drawMusicalNotes(canvas, center);
  }

  void _drawTileHighlight(Canvas canvas, Offset pos, double tileW, double tileH) {
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - tileH / 2);
    path.lineTo(pos.dx + tileW / 2, pos.dy);
    path.lineTo(pos.dx, pos.dy + tileH / 2);
    path.lineTo(pos.dx - tileW / 2, pos.dy);
    path.close();

    canvas.drawPath(path, highlightPaint);
  }

  /// Renders botanical flora based on user's real plant, species, growth stage, and season
  void _drawBotanicalFlora(
    Canvas canvas,
    Offset pos,
    int gx,
    int gy,
    int index,
    PlantModel? userPlant,
    double tileW,
    double tileH,
  ) {
    final int depth = gx + gy;

    if (userPlant != null) {
      // ──────── REAL USER PLANT ────────
      final speciesLower = userPlant.speciesName.toLowerCase();
      final nameLower = userPlant.plantName.toLowerCase();
      final double progress = userPlant.growthProgress; // 0.0 to 1.0
      final double healthMultiplier = (0.55 + 0.45 * (userPlant.health / 100.0)).clamp(0.5, 1.0);
      
      // Growth scale from seedling (0.35) up to majestic mature (1.25)
      final double growthScale = (0.35 + progress * 0.9) * healthMultiplier;
      final bool isMature = progress >= 0.85;
      final bool isSeedling = progress < 0.20;
      final bool isSprout = progress >= 0.20 && progress < 0.50;

      if (isSeedling) {
        // Emerging Seedling / Seed Stage for any species
        _drawSeedlingPlot(canvas, pos, growthScale: growthScale);
      } else if (isSprout) {
        // Young 4-leaf Sprout Stage
        _drawSproutPlant(canvas, pos, growthScale: growthScale, species: speciesLower);
      } else {
        // Species-specific full vegetative / mature rendering
        if (speciesLower.contains('tulsi') ||
            speciesLower.contains('basil') ||
            speciesLower.contains('mint') ||
            speciesLower.contains('herb') ||
            speciesLower.contains('rosemary') ||
            speciesLower.contains('coriander') ||
            nameLower.contains('tulsi') ||
            nameLower.contains('basil')) {
          _drawHerbPlant(canvas, pos, growthScale: growthScale, isMature: isMature);
        } else if (speciesLower.contains('rose') ||
            speciesLower.contains('flower') ||
            speciesLower.contains('hibiscus') ||
            speciesLower.contains('marigold') ||
            speciesLower.contains('jasmine') ||
            speciesLower.contains('sunflower') ||
            speciesLower.contains('orchid') ||
            speciesLower.contains('lily') ||
            speciesLower.contains('lavender')) {
          _drawFloweringPlant(
            canvas,
            pos,
            growthScale: growthScale,
            isMature: isMature,
            speciesName: userPlant.speciesName,
          );
        } else if (speciesLower.contains('aloe') ||
            speciesLower.contains('cactus') ||
            speciesLower.contains('succulent') ||
            speciesLower.contains('snake') ||
            speciesLower.contains('jade') ||
            speciesLower.contains('saguaro')) {
          _drawSucculentPlant(canvas, pos, growthScale: growthScale, isMature: isMature);
        } else if (speciesLower.contains('money') ||
            speciesLower.contains('pothos') ||
            speciesLower.contains('monstera') ||
            speciesLower.contains('ivy') ||
            speciesLower.contains('vine') ||
            speciesLower.contains('philodendron') ||
            speciesLower.contains('zz')) {
          _drawVinePlant(canvas, pos, growthScale: growthScale, isMature: isMature);
        } else if (speciesLower.contains('fern') ||
            speciesLower.contains('palm') ||
            speciesLower.contains('bamboo') ||
            speciesLower.contains('peace lily')) {
          _drawFernPlant(canvas, pos, growthScale: growthScale, isMature: isMature);
        } else {
          // General botanical deciduous canopy tree / shrub
          _drawTreePlant(canvas, pos, growthScale: growthScale, isMature: isMature);
        }
      }

      // Thriving plants (health >= 70%) get floating heart bubbles
      if (userPlant.health >= 70) {
        _drawHeartBubble(canvas, Offset(pos.dx, pos.dy - (32 * growthScale) - 10));
      }

      // Status indicator badges (Hydration / Water Due)
      if (userPlant.isWateringDue) {
        // Water droplet alert badge (needs water)
        _drawWaterDueBadge(canvas, Offset(pos.dx + 12, pos.dy - 6));
      } else {
        // Hydrated green leaf dot
        _drawHydratedBadge(canvas, Offset(pos.dx + 10, pos.dy + 4));
      }
    } else {
      // ──────── EMPTY TILE / SANCTUARY PLOT ────────
      if (userPlants.isEmpty && (depth == 0 || (gx == 0 && gy == 4) || (gx == 4 && gy == 0))) {
        // When user has 0 plants, show a few serene sanctuary landmark trees around perimeter
        if (gx == gy && gx == 0) {
          _drawPineTree(canvas, pos, height: 42, color: season.pineColor);
        } else if (gx > gy) {
          _drawRoundCanopyTree(
            canvas,
            pos,
            radius: 14,
            trunkH: 14,
            color: season.primaryCanopyColor,
          );
        } else {
          _drawRoundCanopyTree(
            canvas,
            pos,
            radius: 13,
            trunkH: 13,
            color: season.secondaryCanopyColor,
          );
        }
      } else {
        // Interactive fertile garden soil bed / planting spot
        _drawEmptyGardenPlot(canvas, pos, tileW, tileH);
      }
    }
  }

  /// Empty Garden Soil Plot with interactive "+" planting marker
  void _drawEmptyGardenPlot(Canvas canvas, Offset pos, double tileW, double tileH) {
    // Soil mound patch
    final soilBedPaint = Paint()
      ..color = season.islandSoilColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final soilPath = Path();
    soilPath.moveTo(pos.dx, pos.dy - tileH * 0.32);
    soilPath.lineTo(pos.dx + tileW * 0.34, pos.dy);
    soilPath.lineTo(pos.dx, pos.dy + tileH * 0.32);
    soilPath.lineTo(pos.dx - tileW * 0.34, pos.dy);
    soilPath.close();
    canvas.drawPath(soilPath, soilBedPaint);

    // Stone / wooden border rim
    final rimPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(soilPath, rimPaint);

    // Subtle interactive "+" planting indicator
    final plusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pos.dx - 3.5, pos.dy), Offset(pos.dx + 3.5, pos.dy), plusPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 3.5), Offset(pos.dx, pos.dy + 3.5), plusPaint);
  }

  /// Seedling Stage (< 20% growth): Earthen mound with twin baby cotyledon leaves
  void _drawSeedlingPlot(Canvas canvas, Offset pos, {required double growthScale}) {
    // Dark fertile soil mound
    final moundPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy), width: 14 * growthScale, height: 8 * growthScale),
      moundPaint,
    );

    // Baby Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..strokeWidth = 2.0;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 10 * growthScale), stemPaint);

    // Twin Cotyledon Leaves
    final leafPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx - 4 * growthScale, pos.dy - 11 * growthScale), width: 6 * growthScale, height: 4 * growthScale),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx + 4 * growthScale, pos.dy - 11 * growthScale), width: 6 * growthScale, height: 4 * growthScale),
      leafPaint,
    );
  }

  /// Sprout Stage (20% - 50% growth): 4-leaf vibrant green shoot
  void _drawSproutPlant(Canvas canvas, Offset pos, {required double growthScale, required String species}) {
    final stemPaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 16 * growthScale), stemPaint);

    final leafPaint = Paint()..color = const Color(0xFF689F38);
    // Lower left & right leaves
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx - 6 * growthScale, pos.dy - 8 * growthScale), width: 8 * growthScale, height: 5 * growthScale),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx + 6 * growthScale, pos.dy - 8 * growthScale), width: 8 * growthScale, height: 5 * growthScale),
      leafPaint,
    );
    // Upper leaves
    final topLeafPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx - 5 * growthScale, pos.dy - 16 * growthScale), width: 7 * growthScale, height: 5 * growthScale),
      topLeafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx + 5 * growthScale, pos.dy - 16 * growthScale), width: 7 * growthScale, height: 5 * growthScale),
      topLeafPaint,
    );
  }

  /// Herb Plant (Tulsi, Basil, Mint, etc.)
  void _drawHerbPlant(Canvas canvas, Offset pos, {required double growthScale, required bool isMature}) {
    // Earthen Pot / Bed
    final potPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 16 * growthScale, height: 6 * growthScale),
        const Radius.circular(3),
      ),
      potPaint,
    );

    // Bushy Stems
    final stemPaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 2.2;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 22 * growthScale), stemPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 6 * growthScale), Offset(pos.dx - 9 * growthScale, pos.dy - 16 * growthScale), stemPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 8 * growthScale), Offset(pos.dx + 9 * growthScale, pos.dy - 17 * growthScale), stemPaint);

    // Herb Leaf Clusters
    final leafPaint = Paint()..color = const Color(0xFF43A047);
    final lightLeafPaint = Paint()..color = const Color(0xFF66BB6A);

    for (final offset in [
      Offset(pos.dx - 9 * growthScale, pos.dy - 16 * growthScale),
      Offset(pos.dx + 9 * growthScale, pos.dy - 17 * growthScale),
      Offset(pos.dx - 4 * growthScale, pos.dy - 20 * growthScale),
      Offset(pos.dx + 4 * growthScale, pos.dy - 21 * growthScale),
      Offset(pos.dx, pos.dy - 24 * growthScale),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: offset, width: 8 * growthScale, height: 6 * growthScale),
        leafPaint,
      );
      canvas.drawCircle(Offset(offset.dx - 1, offset.dy - 1), 2 * growthScale, lightLeafPaint);
    }

    // Herbal Floral Spikes at Top when Mature (Tulsi purple/white inflorescence)
    if (isMature) {
      final spikePaint = Paint()..color = const Color(0xFFAB47BC);
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(pos.dx, pos.dy - (26 + i * 3.5) * growthScale), 1.8 * growthScale, spikePaint);
      }
    }
  }

  /// Flowering Plant (Rose, Marigold, Hibiscus, Jasmine, Sunflower, etc.)
  void _drawFloweringPlant(
    Canvas canvas,
    Offset pos, {
    required double growthScale,
    required bool isMature,
    required String speciesName,
  }) {
    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 24 * growthScale), stemPaint);

    // Serrated Foliage Leaves
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx - 8 * growthScale, pos.dy - 12 * growthScale), width: 8 * growthScale, height: 5 * growthScale),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx + 8 * growthScale, pos.dy - 14 * growthScale), width: 8 * growthScale, height: 5 * growthScale),
      leafPaint,
    );

    // Blossom Flower Color
    Color flowerColor = const Color(0xFFE53935); // Crimson Rose default
    final s = speciesName.toLowerCase();
    if (s.contains('marigold') || s.contains('sunflower')) {
      flowerColor = const Color(0xFFFFB300); // Golden Amber
    } else if (s.contains('jasmine') || s.contains('lily')) {
      flowerColor = const Color(0xFFFFF9C4); // Cream White
    } else if (s.contains('lavender') || s.contains('orchid')) {
      flowerColor = const Color(0xFFBA68C8); // Lavender Purple
    }

    final flowerCenter = Offset(pos.dx, pos.dy - 25 * growthScale);
    final flowerRadius = isMature ? 8.5 * growthScale : 5.5 * growthScale;

    // Petals
    final petalPaint = Paint()..color = flowerColor;
    for (int i = 0; i < 5; i++) {
      final angle = i * (math.pi * 2 / 5);
      final petalCenter = Offset(
        flowerCenter.dx + math.cos(angle) * (flowerRadius * 0.6),
        flowerCenter.dy + math.sin(angle) * (flowerRadius * 0.6),
      );
      canvas.drawCircle(petalCenter, flowerRadius * 0.55, petalPaint);
    }

    // Flower Center Core
    final corePaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(flowerCenter, flowerRadius * 0.35, corePaint);
  }

  /// Succulent Plant (Aloe Vera, Cactus, Snake Plant)
  void _drawSucculentPlant(Canvas canvas, Offset pos, {required double growthScale, required bool isMature}) {
    final succulentPaint = Paint()..color = season.cactusColor;
    final highlightPaint = Paint()..color = const Color(0xFF81C784);

    // Clustered fleshy spear leaves
    for (int i = -2; i <= 2; i++) {
      final angle = i * 0.28;
      final leafH = (20 - (i.abs() * 4)) * growthScale;

      final path = Path();
      path.moveTo(pos.dx - 2, pos.dy);
      path.lineTo(pos.dx + math.sin(angle) * leafH, pos.dy - math.cos(angle) * leafH);
      path.lineTo(pos.dx + 2, pos.dy);
      path.close();

      canvas.drawPath(path, succulentPaint);
    }

    // Top tip highlight
    canvas.drawCircle(Offset(pos.dx, pos.dy - 20 * growthScale), 2.5 * growthScale, highlightPaint);
  }

  /// Vine / Foliage Plant (Money Plant, Pothos, Monstera, Ivy)
  void _drawVinePlant(Canvas canvas, Offset pos, {required double growthScale, required bool isMature}) {
    // Support Garden Stake
    final stakePaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2.5;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 26 * growthScale), stakePaint);

    // Heart-shaped cascading leaves
    final leafPaint = Paint()..color = const Color(0xFF388E3C);
    final variegatedPaint = Paint()..color = const Color(0xFFC8E6C9);

    final leafOffsets = [
      Offset(pos.dx - 6 * growthScale, pos.dy - 8 * growthScale),
      Offset(pos.dx + 7 * growthScale, pos.dy - 14 * growthScale),
      Offset(pos.dx - 7 * growthScale, pos.dy - 19 * growthScale),
      Offset(pos.dx + 6 * growthScale, pos.dy - 24 * growthScale),
      Offset(pos.dx, pos.dy - 28 * growthScale),
    ];

    for (final off in leafOffsets) {
      // Heart leaf polygon
      final path = Path();
      path.moveTo(off.dx, off.dy - 4 * growthScale);
      path.quadraticBezierTo(off.dx + 5 * growthScale, off.dy - 3 * growthScale, off.dx + 3 * growthScale, off.dy + 4 * growthScale);
      path.lineTo(off.dx, off.dy + 6 * growthScale);
      path.lineTo(off.dx - 3 * growthScale, off.dy + 4 * growthScale);
      path.quadraticBezierTo(off.dx - 5 * growthScale, off.dy - 3 * growthScale, off.dx, off.dy - 4 * growthScale);
      path.close();
      canvas.drawPath(path, leafPaint);
      canvas.drawCircle(off, 1.5 * growthScale, variegatedPaint);
    }
  }

  /// Fern / Palm Plant
  void _drawFernPlant(Canvas canvas, Offset pos, {required double growthScale, required bool isMature}) {
    final frondPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()..color = const Color(0xFF43A047);

    for (int i = -3; i <= 3; i++) {
      if (i == 0) continue;
      final angle = (i * math.pi / 7) - (math.pi / 2);
      final len = 20 * growthScale;
      final end = Offset(pos.dx + math.cos(angle) * len, pos.dy + math.sin(angle) * len);
      canvas.drawLine(pos, end, frondPaint);
      canvas.drawCircle(end, 2.5 * growthScale, leafFill);
    }
  }

  /// Deciduous Canopy Shrub / Tree
  void _drawTreePlant(Canvas canvas, Offset pos, {required double growthScale, required bool isMature}) {
    _drawRoundCanopyTree(
      canvas,
      pos,
      radius: 14 * growthScale,
      trunkH: 14 * growthScale,
      color: season.primaryCanopyColor,
    );
  }

  /// Hydrated green status badge
  void _drawHydratedBadge(Canvas canvas, Offset pos) {
    final badgePaint = Paint()..color = const Color(0xFF03A9F4);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(pos, 3.8, badgePaint);
    canvas.drawCircle(pos, 3.8, borderPaint);
  }

  /// Water due red droplet badge
  void _drawWaterDueBadge(Canvas canvas, Offset pos) {
    final badgePaint = Paint()..color = const Color(0xFFE53935);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(pos, 5.0, badgePaint);
    canvas.drawCircle(pos, 5.0, borderPaint);

    // Droplet symbol in center
    final dropPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(pos.dx, pos.dy + 0.5), 2.0, dropPaint);
  }

  /// Tiered Evergreen Pine Tree
  void _drawPineTree(Canvas canvas, Offset pos, {required double height, required Color color}) {
    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 6), width: 4, height: 14), trunkPaint);

    final pinePaint = Paint()..color = color;
    final lighterPine = Paint()..color = color.withValues(alpha: 0.85);

    // 3 Triangles from bottom to top
    for (int tier = 0; tier < 3; tier++) {
      final baseY = pos.dy - 12 - (tier * 11);
      final width = 24.0 - (tier * 5);
      final h = 16.0;

      final path = Path();
      path.moveTo(pos.dx, baseY - h);
      path.lineTo(pos.dx + width / 2, baseY);
      path.lineTo(pos.dx - width / 2, baseY);
      path.close();

      canvas.drawPath(path, tier == 2 ? lighterPine : pinePaint);
    }
  }

  /// Round Deciduous Canopy Tree (Terracotta orange or lush green)
  void _drawRoundCanopyTree(
    Canvas canvas,
    Offset pos, {
    required double radius,
    required double trunkH,
    required Color color,
  }) {
    // Wooden Trunk
    final trunkPaint = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH / 2), width: 4.5, height: trunkH),
      trunkPaint,
    );

    // Spherical / Pill Canopy
    final canopyCenter = Offset(pos.dx, pos.dy - trunkH - (radius * 0.7));
    final canopyPaint = Paint()..color = color;

    // Draw pill or rounded oval
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: canopyCenter, width: radius * 1.7, height: radius * 2.1),
        Radius.circular(radius),
      ),
      canopyPaint,
    );

    // Inner highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(canopyCenter.dx - radius * 0.3, canopyCenter.dy - radius * 0.3), radius * 0.4, highlightPaint);
  }

  /// Floating White Speech Bubble with Red Heart (❤️)
  void _drawHeartBubble(Canvas canvas, Offset pos) {
    // Gentle sine-wave bobbing
    final bobY = math.sin(floatProgress * math.pi * 2) * 3.0;
    final bubblePos = Offset(pos.dx, pos.dy + bobY);

    // Bubble Background
    final bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bubblePos, width: 15, height: 13),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect.shift(const Offset(0, 1)), shadowPaint);
    canvas.drawRRect(rrect, bubblePaint);

    // Tiny Triangle Tail below bubble
    final tailPath = Path();
    tailPath.moveTo(bubblePos.dx - 2, bubblePos.dy + 6.5);
    tailPath.lineTo(bubblePos.dx, bubblePos.dy + 9.5);
    tailPath.lineTo(bubblePos.dx + 2, bubblePos.dy + 6.5);
    tailPath.close();
    canvas.drawPath(tailPath, bubblePaint);

    // Red Heart Shape inside bubble
    final heartPaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(bubblePos.dx - 2.2, bubblePos.dy - 1.2), 1.9, heartPaint);
    canvas.drawCircle(Offset(bubblePos.dx + 2.2, bubblePos.dy - 1.2), 1.9, heartPaint);

    final heartPath = Path();
    heartPath.moveTo(bubblePos.dx - 4, bubblePos.dy - 0.5);
    heartPath.lineTo(bubblePos.dx, bubblePos.dy + 3.2);
    heartPath.lineTo(bubblePos.dx + 4, bubblePos.dy - 0.5);
    heartPath.close();
    canvas.drawPath(heartPath, heartPaint);
  }

  /// Floating Dancing Musical Notes (from reference image)
  void _drawMusicalNotes(Canvas canvas, Offset center) {
    final notePaint = Paint()
      ..color = const Color(0xFFE64A19).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Upward floating sine drift
    final driftY = -((notesProgress * 24) % 24);
    final noteX = center.dx + 68 + math.sin(notesProgress * math.pi * 2) * 5;
    final noteY = center.dy - 65 + driftY;

    // First Note (♪)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(noteX, noteY), width: 5.5, height: 4),
      notePaint,
    );
    canvas.drawLine(
      Offset(noteX + 2, noteY),
      Offset(noteX + 2, noteY - 10),
      Paint()..color = notePaint.color..strokeWidth = 1.8,
    );
    canvas.drawCircle(Offset(noteX + 4.5, noteY - 10), 1.5, notePaint);

    // Second Note (♫) slightly higher
    final note2X = noteX - 12;
    final note2Y = noteY - 8;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(note2X, note2Y), width: 4.5, height: 3.5),
      notePaint,
    );
    canvas.drawLine(
      Offset(note2X + 1.8, note2Y),
      Offset(note2X + 1.8, note2Y - 8),
      Paint()..color = notePaint.color..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricIslandPainter oldDelegate) => true;
}
