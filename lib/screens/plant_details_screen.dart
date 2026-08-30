import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import '../services/ai_service.dart';
import '../services/plant_repository.dart';
import '../services/watering_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/flora_ai_sheet.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/plant_growth_animation.dart';
import '../widgets/skeuo_card.dart';
import '../widgets/skeuo_status_badge.dart';
import 'ai_analysis_screen.dart';
import 'daily_checkin_screen.dart';
import 'certificate_screen.dart';

/// Screen 11: Plant Details
/// Features:
/// - Plant Growth Animation (Age / Lifespan frame index)
/// - Multi-Factor Plant Health Diagnostic Card (Hydration, Sunlight, Consistency, Status)
/// - Flora AI Personalized Guidance Card & Interactive Q&A
/// - Quick Care Action Buttons (Daily Check-in, Quick Log Sunlight)
/// - Milestone Certificate Generator
class PlantDetailsScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailsScreen({
    super.key,
    required this.plantId,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  final PlantRepository _plantRepository = PlantRepository();
  final WateringService _wateringService = WateringService();
  final AIService _aiService = AIService();

  late PlantModel _plant;
  List<DailyCheckinModel> _checkins = [];
  bool _isNotFound = false;
  String _aiGuidance = 'Loading Flora AI guidance...';
  bool _isLoadingAI = true;

  @override
  void initState() {
    super.initState();
    _fetchPlant();
    _loadAIGuidance();
  }

  void _fetchPlant() {
    final p = _plantRepository.getPlantById(widget.plantId);
    if (p != null) {
      _plant = p;
      _checkins = _plantRepository.getCheckinsForPlant(widget.plantId);
    } else {
      _isNotFound = true;
    }
  }

  Future<void> _loadAIGuidance() async {
    if (_isNotFound) return;
    setState(() => _isLoadingAI = true);
    final tip = await _aiService.getStageCareGuidance(_plant);
    if (mounted) {
      setState(() {
        _aiGuidance = tip;
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _openDailyCheckin() async {
    final result = await Navigator.of(context).push<PlantModel>(
      MaterialPageRoute(
        builder: (context) => DailyCheckinScreen(plant: _plant),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _plant = result;
        _checkins = _plantRepository.getCheckinsForPlant(widget.plantId);
      });
      _loadAIGuidance();
    } else {
      _fetchPlant();
      if (mounted) setState(() {});
    }
  }

  void _openFloraAIModal() {
    FloraAISheet.show(
      context,
      plant: _plant,
      history: _checkins,
    ).then((_) {
      _fetchPlant();
      if (mounted) setState(() {});
    });
  }

  void _openQuickSunlightDialog() {
    int selectedHours = _plant.sunlightHoursToday > 0
        ? _plant.sunlightHoursToday
        : _plant.targetSunlightHours;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFA000)),
              const SizedBox(width: 8),
              Text(
                'Log Sunlight Exposure',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many hours of sunlight did ${_plant.plantName} receive today? (Target: ${_plant.targetSunlightHours}h)',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0, 2, 4, 6, 8].map((hrs) {
                  final isSel = selectedHours == hrs;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedHours = hrs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFFA000) : SkeuoTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFFE65100) : const Color(0xFFD6E4DB),
                        ),
                      ),
                      child: Text(
                        hrs == 8 ? '8h+' : '${hrs}h',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = await _wateringService.logSunlight(
                  plant: _plant,
                  hours: selectedHours,
                );
                if (mounted) {
                  setState(() => _plant = updated);
                  _loadAIGuidance();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('☀️ Logged $selectedHours hrs of sunlight for ${_plant.plantName}!'),
                      backgroundColor: const Color(0xFFFFA000),
                    ),
                  );
                }
              },
              child: const Text('Save Sunlight'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isNotFound) {
      return Scaffold(
        backgroundColor: SkeuoTheme.background,
        body: Center(
          child: Text('Plant not found (${widget.plantId})'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SkeuoTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: < Plant Details
            _buildAppBar(),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Photo / Growth Card (Screen 11)
                    _buildPlantPhotoCard(),
                    const SizedBox(height: 16),

                    // 3 Stats Boxes: Age | Health | Disease (Screen 11)
                    _buildThreeStatsRow(),
                    const SizedBox(height: 16),

                    // Info List Card (Watered Today, Last Uploaded, Sunlight)
                    _buildPlantInfoCard(),
                    const SizedBox(height: 20),

                    // Dual Action Buttons (Upload Today | AI Analysis) (Screen 11)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openDailyCheckin,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: SkeuoTheme.primaryGreen, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Upload Today',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: SkeuoTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FunBouncyButton(
                            text: 'AI Analysis',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AIAnalysisScreen(plant: _plant),
                                ),
                              );
                            },
                            color: SkeuoTheme.primaryGreen,
                            height: 50,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Botanical Growth Stage Timeline & Photo Journey ──
                    _buildGrowthStageTimelineCard(),
                    const SizedBox(height: 20),

                    // Comprehensive Vital Metrics Grid
                    _buildMetricsGrid(),
                    const SizedBox(height: 20),

                    // Flora AI Guidance / Additional details
                    _buildAIGuidanceCard(),
                    const SizedBox(height: 14),

                    // Claim certificate if completed
                    if (_plant.isCompleted) ...[
                      FunBouncyButton(
                        text: 'Claim Certificate 📜',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CertificateScreen(plant: _plant),
                            ),
                          );
                        },
                        color: const Color(0xFFFF8F00),
                        height: 52,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: SkeuoTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Plant Details',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: SkeuoTheme.alertRed, size: 22),
            onPressed: _confirmDelete,
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined,
                color: SkeuoTheme.sunYellow, size: 22),
            onPressed: _openQuickSunlightDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantPhotoCard() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppPhotoView(
              imagePath: _plant.initialPhotoPath,
              fit: BoxFit.cover,
              fallback: Container(
                color: const Color(0xFFF1F8EE),
                child: Center(
                  child: PlantGrowthAnimation(
                    plantAge: _plant.ageInDays,
                    lifespanDays: _plant.lifespanDays,
                    speciesName: _plant.speciesName,
                    height: 160,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _plant.plantName,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: SkeuoTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _plant.speciesName,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SkeuoTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SkeuoStatusBadge(
                label: _plant.healthStatus,
                icon: Icons.spa_rounded,
                color: _getStatusColor(_plant.healthStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeStatsRow() {
    final age = _plant.ageInDays;
    final health = _plant.health;

    return Row(
      children: [
        Expanded(
          child: _statBox(
            label: 'Age',
            value: '$age ${age == 1 ? 'Day' : 'Days'}',
            color: SkeuoTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            label: 'Health',
            value: '$health%',
            color: _getStatusColor(_plant.healthStatus),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            label: 'Disease',
            value: health >= 80 ? 'None' : 'Detected',
            color: health >= 80 ? SkeuoTheme.primaryGreen : SkeuoTheme.alertRed,
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfoCard() {
    final isWatered =
        DateTime.now().difference(_plant.lastWateredDate).inHours < 24;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF03A9F4),
            label: 'Watered Today',
            valueWidget: isWatered
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: SkeuoTheme.primaryGreen, size: 18),
                      SizedBox(width: 4),
                      Text('Yes',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: SkeuoTheme.primaryGreen)),
                    ],
                  )
                : Text(_plant.isWateringDue ? 'Needs Water' : 'Pending',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _plant.isWateringDue
                            ? SkeuoTheme.alertRed
                            : SkeuoTheme.warningOrange)),
          ),
          const Divider(height: 20, color: Color(0xFFF1F8EE)),
          _infoRow(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFFFA000),
            label: 'Last Uploaded',
            valueWidget: Text(
              _plant.daysUntilWatering == 0 ? 'Today' : 'Recently',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF1F8EE)),
          _infoRow(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFFB300),
            label: 'Sunlight',
            valueWidget: Text(
              'Moderate (${_plant.sunlightHoursToday}h)',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SkeuoTheme.textSecondary,
          ),
        ),
        const Spacer(),
        valueWidget,
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Thriving':
        return Colors.teal;
      case 'Optimal':
        return Colors.green;
      case 'Needs Sunlight':
        return Colors.orange;
      case 'Under-watered':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  // ── Botanical Growth Stage Timeline & Photo Journey Card ─────────────
  Widget _buildGrowthStageTimelineCard() {
    final progress = _plant.growthProgress;
    final progressPercent = (progress * 100).toInt();
    final stages = [
      {'name': 'Seed', 'emoji': '🌱', 'threshold': 0.0},
      {'name': 'Sprout', 'emoji': '🌿', 'threshold': 0.15},
      {'name': 'Growing', 'emoji': '🪴', 'threshold': 0.40},
      {'name': 'Mature', 'emoji': '🌸', 'threshold': 0.85},
    ];

    // Collect all growth photos (Initial planting photo + checkins with photo)
    final List<Map<String, String>> photoTimeline = [];
    if (_plant.initialPhotoPath != null &&
        _plant.initialPhotoPath!.isNotEmpty) {
      photoTimeline.add({
        'day': 'Day 0',
        'title': 'Planting',
        'path': _plant.initialPhotoPath!,
      });
    }

    for (int i = 0; i < _checkins.length; i++) {
      final c = _checkins[i];
      if (c.photoPath != null && c.photoPath!.isNotEmpty) {
        photoTimeline.add({
          'day': 'Check-in #${_checkins.length - i}',
          'title': c.watered ? '💧 Watered' : '☀️ Sunlit',
          'path': c.photoPath!,
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: SkeuoTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Growth Progression',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SkeuoTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_plant.growthStageName} • $progressPercent%',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Growth Stage Stepper Line
          Row(
            children: List.generate(stages.length, (index) {
              final s = stages[index];
              final isReached = progress >= (s['threshold'] as double);
              final isCurrent = index == stages.length - 1
                  ? progress >= (s['threshold'] as double)
                  : progress >= (s['threshold'] as double) &&
                      progress < (stages[index + 1]['threshold'] as double);

              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (index > 0)
                          Positioned(
                            left: 0,
                            right: 50,
                            top: 14,
                            child: Container(
                              height: 3,
                              color: isReached
                                  ? SkeuoTheme.primaryGreen
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isReached
                                ? (isCurrent
                                    ? SkeuoTheme.primaryGreen
                                    : const Color(0xFFE8F5E9))
                                : Colors.white,
                            border: Border.all(
                              color: isReached
                                  ? SkeuoTheme.primaryGreen
                                  : const Color(0xFFE0E0E0),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              s['emoji'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['name'] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight:
                            isReached ? FontWeight.w800 : FontWeight.w600,
                        color: isReached
                            ? SkeuoTheme.textPrimary
                            : SkeuoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Uploaded Photos Growth Timeline Gallery
          Text(
            '📸 Uploaded Growth Photos (${photoTimeline.length})',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (photoTimeline.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBD8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: SkeuoTheme.primaryGreen, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload daily check-in photos to build a visual growth journey!',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SkeuoTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: photoTimeline.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, idx) {
                  final item = photoTimeline[idx];
                  return Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFC8E6C9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Column(
                        children: [
                          Expanded(
                            child: AppPhotoView(
                              imagePath: item['path'],
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: const Color(0xFFE8F5E9),
                                child: const Center(
                                  child: Icon(Icons.spa_rounded,
                                      color: SkeuoTheme.primaryGreen, size: 28),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 3),
                            color: Colors.white,
                            width: double.infinity,
                            child: Column(
                              children: [
                                Text(
                                  item['day']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: SkeuoTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  item['title']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: SkeuoTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIGuidanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  'Flora AI Care Guidance',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B4D3E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openFloraAIModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Ask Doctor',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoadingAI
                ? Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generating personalized advice for ${_plant.growthStageName} stage...',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  )
                : Text(
                    _aiGuidance,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2C4A3A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ],
        ),
      ),
    );
  }


  Widget _buildMetricsGrid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWateredClean = DateTime(
      _plant.lastWateredDate.year,
      _plant.lastWateredDate.month,
      _plant.lastWateredDate.day,
    );
    final bool wateredToday = today.isAtSameMomentAs(lastWateredClean);

    return Column(
      children: [
        // Row 1: Plant Age & Overall Multi-Factor Health
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.timelapse_rounded,
                iconColor: SkeuoTheme.primaryGreen,
                label: 'Growth Stage',
                value: _plant.growthStageName,
                subtitle: 'Day ${_plant.ageInDays} of ${_plant.lifespanDays}d',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE91E63),
                label: 'Botanical Health',
                value: '${_plant.health}%',
                subtitle: _plant.healthStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Hydration Index & Sunlight Score
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.water_drop_rounded,
                iconColor: SkeuoTheme.waterBlue,
                label: 'Hydration Score',
                value: '${_plant.hydrationScore}%',
                subtitle: wateredToday ? 'Watered Today' : _plant.wateringStatusText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.wb_sunny_rounded,
                iconColor: SkeuoTheme.sunYellow,
                label: 'Sunlight Score',
                value: '${_plant.sunlightScore}%',
                subtitle: _plant.sunlightStatusText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Next Watering & Consistency Streak
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.alarm_rounded,
                iconColor: _plant.isWateringDue ? SkeuoTheme.alertRed : SkeuoTheme.primaryGreen,
                label: 'Next Watering',
                value: DateFormat('MMM dd').format(_plant.nextWateringDate),
                subtitle: _plant.wateringStatusText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.verified_rounded,
                iconColor: Colors.purple,
                label: 'Care Consistency',
                value: '${_plant.consistencyScore}%',
                subtitle: '${_checkins.length} Total Check-ins',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return SkeuoCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SkeuoTheme.surfaceDark,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SkeuoTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Remove Plant?',
            style: TextStyle(fontWeight: FontWeight.bold, color: SkeuoTheme.textPrimary),
          ),
          content: Text('Are you sure you want to remove "${_plant.plantName}" from your garden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: SkeuoTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await _plantRepository.deletePlant(_plant.id);
                if (mounted) {
                  nav.pop();
                  nav.pop();
                }
              },
              child: const Text('Remove', style: TextStyle(color: SkeuoTheme.alertRed)),
            ),
          ],
        );
      },
    );
  }
}
