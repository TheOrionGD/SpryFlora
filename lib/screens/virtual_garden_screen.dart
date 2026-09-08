import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_season.dart';
import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/isometric_garden_island.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'plant_details_screen.dart';
import 'realtime_plant_scanner_screen.dart';

/// Interactive Virtual Garden Screen — Upgraded with Seasonal Isometric Island
/// Full-screen interactive isometric garden world with pinch-to-zoom, seasonal
/// theme detection, dynamic sky gradients, quick-water actions, and a botanical
/// plots list below for users who prefer the traditional layout.
class VirtualGardenScreen extends StatefulWidget {
  const VirtualGardenScreen({super.key});

  @override
  State<VirtualGardenScreen> createState() => _VirtualGardenScreenState();
}

class _VirtualGardenScreenState extends State<VirtualGardenScreen>
    with TickerProviderStateMixin {
  final PlantRepository _plantRepo = PlantRepository();
  final UserService _userService = UserService();

  late AnimationController _breezeCtrl;

  late GardenSeason _currentSeason;
  bool _isAutoSeason = true;
  bool _showPlotsGrid = false;

  @override
  void initState() {
    super.initState();
    _currentSeason = GardenSeason.currentForDate(DateTime.now());
    _plantRepo.addListener(_onRepoUpdate);
    _plantRepo.loadLocalData();
    _userService.loadUserData();

    _breezeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _onRepoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _plantRepo.removeListener(_onRepoUpdate);
    _breezeCtrl.dispose();
    super.dispose();
  }

  // Sort plants chronologically by planting date
  List<PlantModel> get _sortedPlants {
    final list = List<PlantModel>.from(_plantRepo.plants);
    list.sort((a, b) => a.plantingDate.compareTo(b.plantingDate));
    return list;
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

  @override
  Widget build(BuildContext context) {
    final plants = _sortedPlants;

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
          maxThroughput: false,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _plantRepo,
              builder: (context, _) {
                return Column(
                  children: [
                    // ── Top Bar ───────────────────────────────────────────
                    _buildTopBar(plants.length),

                    // ── Season Selector Chips ─────────────────────────────
                    _buildSeasonSelectorBar(),
                    const SizedBox(height: 8),

                    // ── View Toggle ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildViewToggle(),
                          Text(
                            _currentSeason.tagLine,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E4032).withValues(alpha: 0.75),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Main Content ──────────────────────────────────────
                    Expanded(
                      child: plants.isEmpty
                          ? _buildEmptyState()
                          : _buildContent(plants),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(int plantCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
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
                  '🏝️ Virtual Garden',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  'Seasonal isometric sanctuary • Pinch to zoom',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          // Plant count badge
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
                  '$plantCount Plants',
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

  // ── Season Selector Bar ──────────────────────────────────────────────────

  Widget _buildSeasonSelectorBar() {
    final autoSeason = GardenSeason.currentForDate(DateTime.now());
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        children: [
          // Auto chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Text(_isAutoSeason ? '✨' : '📅',
                  style: const TextStyle(fontSize: 12)),
              label: Text(
                'Auto (${autoSeason.emoji} ${autoSeason.displayName})',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _isAutoSeason ? Colors.white : const Color(0xFF2E4032),
                ),
              ),
              selected: _isAutoSeason,
              selectedColor: const Color(0xFF2E7D32),
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _isAutoSeason = true;
                    _currentSeason = autoSeason;
                  });
                }
              },
            ),
          ),
          // Season chips
          ...GardenSeason.values.map((season) {
            final isSelected = !_isAutoSeason && _currentSeason == season;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Text(season.emoji, style: const TextStyle(fontSize: 12)),
                label: Text(
                  season.displayName,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF2E4032),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF2E7D32),
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (selected) {
                  setState(() {
                    _isAutoSeason = false;
                    _currentSeason = season;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── View Toggle ──────────────────────────────────────────────────────────

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewChip(label: '🏝️ Island', active: !_showPlotsGrid,
              onTap: () => setState(() => _showPlotsGrid = false)),
          _viewChip(label: '📋 Plots', active: _showPlotsGrid,
              onTap: () => setState(() => _showPlotsGrid = true)),
        ],
      ),
    );
  }

  Widget _viewChip({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF424242),
          ),
        ),
      ),
    );
  }

  // ── Main Content ─────────────────────────────────────────────────────────

  Widget _buildContent(List<PlantModel> plants) {
    if (_showPlotsGrid) {
      return _buildPlotsGridView(plants);
    }
    return _buildIsometricView(plants);
  }

  /// Full-screen isometric island with InteractiveViewer for pinch-zoom & pan
  Widget _buildIsometricView(List<PlantModel> plants) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // InteractiveViewer allows pinch-to-zoom and pan on the island
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: InteractiveViewer(
              minScale: 0.75,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: IsometricGardenIsland(
                userPlants: plants,
                season: _currentSeason,
                onWaterPlant: _quickWaterPlant,
                onAddPlant: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => const RealtimePlantScannerScreen()),
                  );
                  if (added == true) _plantRepo.loadLocalData();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Usage hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👆', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Text(
                  'Tap a plant tile · Pinch to zoom · Drag to pan',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E4032),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Optional collapsible "My Plots" list below the island
          _buildCollapsiblePlotsSection(plants),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCollapsiblePlotsSection(List<PlantModel> plants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'My Botanical Plots',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${plants.length}',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) =>
              _buildPlotCard(plants[index], index),
        ),
      ],
    );
  }

  /// Botanical Plots Grid view (visible when "Plots" toggle is selected)
  Widget _buildPlotsGridView(List<PlantModel> plants) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: plants.length + 1,
            itemBuilder: (context, index) {
              if (index < plants.length) {
                return _buildPlotCard(plants[index], index);
              }
              return _buildAddPlotCard();
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPlotCard(PlantModel plant, int index) {
    final isWaterDue = plant.isWateringDue;
    final age = plant.ageInDays;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlantDetailsScreen(plantId: plant.id)),
        );
      },
      child: AnimatedBuilder(
        animation: _breezeCtrl,
        builder: (context, child) {
          final sway =
              math.sin(_breezeCtrl.value * math.pi * 2 + index) * 0.025;
          return Transform.rotate(
            angle: sway,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isWaterDue
                      ? const Color(0xFF64B5F6)
                      : const Color(0xFFA5D6A7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isWaterDue
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF2E7D32))
                        .withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Soil base
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 52,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF6D4C41),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(20)),
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

                  // Plant content
                  Positioned.fill(
                    bottom: 52,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          const SizedBox(height: 6),
                          // Quick water button
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isWaterDue
                                    ? const Color(0xFF0288D1)
                                    : const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              onPressed: () => _quickWaterPlant(plant),
                              icon: const Icon(Icons.water_drop_rounded, size: 13),
                              label: Text(
                                isWaterDue ? 'Water Now 💧' : 'Water 💧',
                                style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
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

  Widget _buildAddPlotCard() {
    return GestureDetector(
      onTap: () async {
        final added = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
        );
        if (added == true) _plantRepo.loadLocalData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
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
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Plant',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
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
                'No plants added yet. Scan any real plant using the AI recognition scanner to add it to your virtual garden island!',
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
}
