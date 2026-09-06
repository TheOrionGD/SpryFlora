import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/leaves_particle_overlay.dart';

/// Full-Screen Analysis Loader Page
/// Displays "SpryFlora analyzing your plant species..." with laser scanning reticle,
/// particle overlay, and real-time botanical database cross-checking progress.
class PlantAnalysisLoaderScreen extends StatefulWidget {
  final String photoPath;

  const PlantAnalysisLoaderScreen({
    super.key,
    required this.photoPath,
  });

  @override
  State<PlantAnalysisLoaderScreen> createState() =>
      _PlantAnalysisLoaderScreenState();
}

class _PlantAnalysisLoaderScreenState extends State<PlantAnalysisLoaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserCtrl;
  late Animation<double> _laserAnimation;

  int _currentStepIndex = 0;
  Timer? _stepTimer;

  final List<String> _analysisSteps = [
    'Scanning leaf geometry & foliage structure...',
    'Cross-referencing SpryFlora botanical dataset...',
    'Matching tree & species characteristics...',
    'Building kid-friendly care guide & water targets...',
  ];

  @override
  void initState() {
    super.initState();
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserCtrl, curve: Curves.easeInOut),
    );

    _startStepProgressTimer();
    _executeAnalysis();
  }

  void _startStepProgressTimer() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() {
        if (_currentStepIndex < _analysisSteps.length - 1) {
          _currentStepIndex++;
        }
      });
    });
  }

  Future<void> _executeAnalysis() async {
    final tempPlant = PlantModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      plantName: 'New Plant',
      speciesName: 'Rose',
      plantingDate: DateTime.now(),
      lifespanDays: 120,
      wateringIntervalDays: 3,
    );

    final result = await AIService().analyzePlantPhoto(
      plant: tempPlant,
      photoPath: widget.photoPath,
    );

    // Wait a brief moment for smooth visual feedback
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Top Header
                Text(
                  'SpryFlora AI Scanner',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SpryFlora analyzing your plant species...',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SkeuoTheme.primaryGreen,
                  ),
                ),

                const Spacer(),

                // Center Image Viewfinder with Laser Scanner Line
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: SkeuoTheme.primaryGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: SkeuoTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppPhotoView(
                            imagePath: widget.photoPath,
                            fit: BoxFit.cover,
                            fallback: const Center(
                              child: Icon(Icons.eco_rounded,
                                  size: 64, color: SkeuoTheme.primaryGreen),
                            ),
                          ),

                          // Moving Scanning Laser Line
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 260 * _laserAnimation.value,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FF66),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00FF66)
                                            .withValues(alpha: 0.9),
                                        blurRadius: 10,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Progress Status Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFFE5EBD8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: SkeuoTheme.primaryGreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'SpryFlora analyzing your plant species...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _analysisSteps[_currentStepIndex],
                          key: ValueKey<int>(_currentStepIndex),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: SkeuoTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
