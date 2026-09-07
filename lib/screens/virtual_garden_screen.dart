import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'daily_checkin_screen.dart';
import 'plant_details_screen.dart';
import 'realtime_plant_scanner_screen.dart';

/// Interactive Virtual Garden Screen
/// Displays user's real plants in an animated garden landscape, arranged by planting age and days.
/// Plants are interactive: tapping opens detailed diagnostics, water status, and instant camera watering.
class VirtualGardenScreen extends StatefulWidget {
  const VirtualGardenScreen({super.key});

  @override
  State<VirtualGardenScreen> createState() => _VirtualGardenScreenState();
}

class _VirtualGardenScreenState extends State<VirtualGardenScreen>
    with TickerProviderStateMixin {
  final PlantRepository _plantRepo = PlantRepository();

  late AnimationController _breezeCtrl;
  late AnimationController _sunCtrl;
  PlantModel? _selectedPlant;

  @override
  void initState() {
    super.initState();
    _plantRepo.addListener(_onRepoUpdate);
    _plantRepo.loadLocalData();

    _breezeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _sunCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  void _onRepoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _plantRepo.removeListener(_onRepoUpdate);
    _breezeCtrl.dispose();
    _sunCtrl.dispose();
    super.dispose();
  }

  // Group plants by age progression
  List<PlantModel> get _sortedPlants {
    final list = List<PlantModel>.from(_plantRepo.plants);
    // Sort chronologically by plantingDate
    list.sort((a, b) => a.plantingDate.compareTo(b.plantingDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final plants = _sortedPlants;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          // 1. Sky & Sun Backdrop
          Positioned.fill(
            child: _buildSkyAndSun(),
          ),

          // 2. Floating Leaves & Sunbeams
          const Positioned.fill(
            child: LeavesParticleOverlay(particleCount: 16),
          ),

          // 3. Garden Plots & Interactive Plants Canvas
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _buildGardenTopBar(),
                  Expanded(
                    child: plants.isEmpty
                        ? _buildEmptyGardenState()
                        : _buildInteractiveGardenMeadow(plants),
                  ),
                ],
              ),
            ),
          ),

          // 4. Plant Detail Modal Bottom Sheet if selected
          if (_selectedPlant != null)
            _buildPlantInspectionModal(_selectedPlant!),
        ],
      ),
    );
  }

  Widget _buildSkyAndSun() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF81D4FA), // Soft blue sky
            Color(0xFFB2EBF2),
            Color(0xFFC8E6C9), // Horizon blending into meadow
            Color(0xFFA5D6A7),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated Sun
          Positioned(
            top: 40,
            right: 30,
            child: RotationTransition(
              turns: _sunCtrl,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.8),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.wb_sunny_rounded,
                    color: Color(0xFFFFA000), size: 48),
              ),
            ),
          ),
          // Distant hills
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: CustomPaint(
              painter: _HillsPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF2E7D32), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌱 Virtual Garden',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  'Interactive botanical world ordered by plant age',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.park_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_plantRepo.plants.length} Plants',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGardenState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_florist_rounded,
                    size: 48, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Garden Is Ready!',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No plants added yet. Scan any real plant using the AI recognition scanner to add it to your virtual garden plots!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SkeuoTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              FunBouncyButton(
                text: '🌱 Scan & Add Plant',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RealtimePlantScannerScreen(),
                    ),
                  );
                },
                color: const Color(0xFF2E7D32),
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveGardenMeadow(List<PlantModel> plants) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Garden Soil Plots Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return _buildPlantPlotCard(plant, index);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPlantPlotCard(PlantModel plant, int index) {
    final isWaterDue = plant.isWateringDue;
    final age = plant.ageInDays;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlant = plant);
      },
      child: AnimatedBuilder(
        animation: _breezeCtrl,
        builder: (context, child) {
          final sway = math.sin(_breezeCtrl.value * math.pi * 2 + index) * 0.03;

          return Transform.rotate(
            angle: sway,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isWaterDue ? const Color(0xFF64B5F6) : const Color(0xFFA5D6A7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isWaterDue ? const Color(0xFF2196F3) : const Color(0xFF2E7D32))
                        .withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Plot Soil Base
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF6D4C41),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                      ),
                      child: Center(
                        child: Text(
                          '🌱 Plot #${index + 1} • Day $age',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFECB3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Plant Content
                  Positioned.fill(
                    bottom: 48,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Plant Visual / Photo Avatar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE8F5E9),
                                  border: Border.all(
                                    color: const Color(0xFF81C784),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: plant.initialPhotoPath != null
                                      ? AppPhotoView(
                                          imagePath: plant.initialPhotoPath!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.local_florist_rounded,
                                          color: Color(0xFF2E7D32), size: 38),
                                ),
                              ),

                              // Water Alert Badge
                              if (isWaterDue)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E88E5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.water_drop_rounded,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plant.plantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                          Text(
                            plant.speciesName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF388E3C),
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
      ),
    );
  }

  Widget _buildPlantInspectionModal(PlantModel plant) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // consume
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: plant.initialPhotoPath != null
                            ? AppPhotoView(
                                imagePath: plant.initialPhotoPath!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.local_florist,
                                color: Color(0xFF2E7D32), size: 32),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.plantName,
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${plant.speciesName} • Day ${plant.ageInDays}',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 14, color: Color(0xFF43A047)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  plant.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: SkeuoTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => setState(() => _selectedPlant = null),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Health & Watering Status Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Health', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '${plant.health}%',
                            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Watering', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            plant.isWateringDue ? 'Needs Water' : 'Hydrated',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: plant.isWateringDue ? SkeuoTheme.alertRed : SkeuoTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Interval', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '${plant.wateringIntervalDays} days',
                            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: SkeuoTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: Color(0xFF81C784), width: 1.5),
                        ),
                        onPressed: () {
                          final p = _selectedPlant!;
                          setState(() => _selectedPlant = null);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlantDetailsScreen(plantId: p.id),
                            ),
                          );
                        },
                        child: Text(
                          'Plant Details',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.water_drop_rounded, size: 18),
                        label: Text(
                          'Water Now',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                        ),
                        onPressed: () async {
                          final p = _selectedPlant!;
                          setState(() => _selectedPlant = null);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DailyCheckinScreen(plant: p),
                            ),
                          );
                          _plantRepo.loadLocalData();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.7, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.75, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
