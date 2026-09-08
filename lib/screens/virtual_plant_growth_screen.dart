import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/smooth_stage_growth_viewer.dart';
import 'plant_creation_tutorial_screen.dart';

/// Virtual Plant Growth Screen
/// Visualizes the 4-stage AI growth lifecycle for a plant with cloud and leaf particle effects,
/// smooth cross-fade stage transitions, and plant selector drawer/switcher.
class VirtualPlantGrowthScreen extends StatefulWidget {
  final PlantModel plant;
  final bool showWelcomeCelebration;

  const VirtualPlantGrowthScreen({
    super.key,
    required this.plant,
    this.showWelcomeCelebration = false,
  });

  @override
  State<VirtualPlantGrowthScreen> createState() => _VirtualPlantGrowthScreenState();
}

class _VirtualPlantGrowthScreenState extends State<VirtualPlantGrowthScreen> {
  late PlantModel _currentPlant;
  int _activeStageIndex = 0;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _currentPlant = widget.plant;
    _activeStageIndex = _calculateInitialStage();
    _showConfetti = widget.showWelcomeCelebration;
  }

  int _calculateInitialStage() {
    final progress = _currentPlant.growthProgress;
    if (progress < 0.25) return 0;
    if (progress < 0.55) return 1;
    if (progress < 0.85) return 2;
    return 3;
  }

  void _switchPlant(PlantModel newPlant) {
    setState(() {
      _currentPlant = newPlant;
      _activeStageIndex = _calculateInitialStage();
    });
  }

  void _relaunchTutorial() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantCreationTutorialScreen(plant: _currentPlant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plants = PlantRepository().plants;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Ambient Gradient Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFC8E6C9),
                  Color(0xFF81C784),
                ],
              ),
            ),
          ),

          // ── Leaf Particles Simulation Overlay ──
          const LeavesParticleOverlay(maxThroughput: false),

          // ── Main Scrollable Content ──
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(plants),

                // Body Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Plant Selector Chip Carousel (if multiple plants exist)
                        if (plants.length > 1) ...[
                          _buildPlantSelectorBar(plants),
                          const SizedBox(height: 12),
                        ],

                        // Overview Header Info Card
                        _buildPlantOverviewHeader(),

                        const SizedBox(height: 16),

                        // ── Smooth Stage Growth Visualizer ──
                        SmoothStageGrowthViewer(
                          plant: _currentPlant,
                          stageFilePaths: _currentPlant.stageImagePaths,
                          initialStageIndex: _activeStageIndex,
                          onStageChanged: (newIndex) {
                            setState(() => _activeStageIndex = newIndex);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons (Tutorial Replay, Growth Metrics)
                        _buildActionToolbar(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Confetti Celebration on First Arrival ──
          Positioned.fill(
            child: IgnorePointer(
              child: FunConfettiOverlay(
                isActive: _showConfetti,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<PlantModel> plants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
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
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌱 Virtual Plant Growth',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  '4-Stage Morphing Lifecycle & Milestones',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          // Tutorial Replay Button
          IconButton(
            onPressed: _relaunchTutorial,
            tooltip: 'Tutorial Cards',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF2E7D32), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelectorBar(List<PlantModel> plants) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: plants.length,
        itemBuilder: (context, idx) {
          final p = plants[idx];
          final isSelected = p.id == _currentPlant.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: const Text('🪴', style: TextStyle(fontSize: 12)),
              label: Text(
                p.plantName,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF2E4032),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF2E7D32),
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val) _switchPlant(p);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantOverviewHeader() {
    final progress = (_currentPlant.growthProgress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPlant.plantName,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  '${_currentPlant.speciesName} • Day ${_currentPlant.ageInDays} of ${_currentPlant.lifespanDays}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF2E7D32), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$progress% Grown',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _relaunchTutorial,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
            label: Text(
              '6-Card Tutorial',
              style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🌱 ${_currentPlant.plantName} is currently on Stage $_activeStageIndex!'),
                  backgroundColor: SkeuoTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFFA5D6A7), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.eco_rounded, size: 18),
            label: Text(
              'Stage Details',
              style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
