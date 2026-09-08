import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';

/// Smooth Growth Stage Visualizer Component
/// Renders 4 growth stages with zero jitter, fixed bounding boxes (220x260),
/// bottom-anchored cross-fade scaling transitions, and an interactive timeline stepper.
class SmoothStageGrowthViewer extends StatefulWidget {
  final PlantModel plant;
  final List<String>? stageFilePaths;
  final int initialStageIndex;
  final ValueChanged<int>? onStageChanged;

  const SmoothStageGrowthViewer({
    super.key,
    required this.plant,
    this.stageFilePaths,
    this.initialStageIndex = 0,
    this.onStageChanged,
  });

  @override
  State<SmoothStageGrowthViewer> createState() => _SmoothStageGrowthViewerState();
}

class _SmoothStageGrowthViewerState extends State<SmoothStageGrowthViewer>
    with SingleTickerProviderStateMixin {
  late int _currentStageIndex;

  static const List<Map<String, dynamic>> _stagesMeta = [
    {
      'name': 'Seed',
      'icon': '🌱',
      'fraction': 0.15,
      'title': 'Stage 0: Germination & Seed',
      'desc': 'Seed shell cracks open in rich soil, sending the primary taproot downward and first tender root tip upward.',
      'care': 'Keep soil moist. Gentle warmth without direct intense scorching sun.',
      'tag': 'Days 1 - 7',
    },
    {
      'name': 'Sprout',
      'icon': '🌿',
      'fraction': 0.40,
      'title': 'Stage 1: Baby Sprout (Cotyledon)',
      'desc': 'Two tender baby leaves unfurl to initiate initial photosynthesis and stem elongation.',
      'care': 'Moderate indirect sunlight. Light misting every 2-3 days.',
      'tag': 'Days 8 - 25',
    },
    {
      'name': 'Growing',
      'icon': '🪴',
      'fraction': 0.80,
      'title': 'Stage 2: Vegetative Growth',
      'desc': 'Rapid stem branching, true foliage development, and strong root network stabilization.',
      'care': 'Consistent watering routine. 4-6 hours of daily sunlight.',
      'tag': 'Days 26 - 60',
    },
    {
      'name': 'Mature',
      'icon': '🌸',
      'fraction': 1.0,
      'title': 'Stage 3: Full Maturity & Blooming',
      'desc': 'Flourishing adult foliage with signature species blossoms, ready for diploma certification.',
      'care': 'Maintain optimal hydration score and log sunlight daily.',
      'tag': 'Full Lifespan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStageIndex = widget.initialStageIndex.clamp(0, 3);
  }

  void _selectStage(int index) {
    if (_currentStageIndex == index) return;
    setState(() {
      _currentStageIndex = index;
    });
    widget.onStageChanged?.call(index);
  }

  List<String> get _paths {
    if (widget.stageFilePaths != null && widget.stageFilePaths!.isNotEmpty) {
      return widget.stageFilePaths!;
    }
    if (widget.plant.stageImagePaths != null && widget.plant.stageImagePaths!.isNotEmpty) {
      return widget.plant.stageImagePaths!;
    }
    return [];
  }

  Widget _buildStageImageWidget(int index) {
    final paths = _paths;
    if (index < paths.length && paths[index].isNotEmpty) {
      final path = paths[index];
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return Image.network(
          path,
          key: ValueKey<String>('net_${index}_$path'),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, __, ___) => _buildFallbackPlantAsset(index),
        );
      } else if (kIsWeb) {
        return Image.network(
          path,
          key: ValueKey<String>('web_${index}_$path'),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, __, ___) => _buildFallbackPlantAsset(index),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: ValueKey<String>('file_${index}_$path'),
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          );
        }
      }
    }

    // Default Fallback
    return _buildFallbackPlantAsset(index);
  }

  Widget _buildFallbackPlantAsset(int index) {
    // Elegant botanical fallback with potted vector illustration
    final emojis = ['🌱', '🌿', '🪴', '🌸'];
    final heights = [50.0, 90.0, 130.0, 160.0];

    return Column(
      key: ValueKey<int>(index),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          height: heights[index],
          child: Center(
            child: Text(
              emojis[index],
              style: TextStyle(fontSize: 34.0 + (index * 14.0)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Terracotta pot representation
        Container(
          width: 80,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE67E48), Color(0xFFC85A27)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: const Color(0xFF8D3B1B), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 70,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _stagesMeta[_currentStageIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Stage Pedestal & Plant Image Viewer Container ──
        Container(
          width: 280,
          height: 310,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFA5D6A7),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background pedestal aura
              Positioned(
                bottom: 16,
                child: Container(
                  width: 190,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF81C784).withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed Size Stage Container (Width: 220, Height: 260) with Padding and Zero-Jitter AnimatedSwitcher
              SizedBox(
                width: 220,
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      );
                    },
                    child: _buildStageImageWidget(_currentStageIndex),
                  ),
                ),
              ),

              // Stage Tag Badge (Top Left)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meta['tag'] as String,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // AI Generated 4-Stage Badge (Top Right)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF2E7D32), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'AI 4-Stage',
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Interactive 4-Stage Connected Timeline Stepper ──
        _buildTimelineStepper(),

        const SizedBox(height: 16),

        // ── Stage Detail Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Text(meta['icon'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta['title'] as String,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                meta['desc'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF424242),
                  height: 1.35,
                ),
              ),
              const Divider(height: 18, color: Color(0xFFE0E0E0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFFA000), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meta['care'] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isSelected = _currentStageIndex == index;
          final isCompleted = _currentStageIndex > index;
          final meta = _stagesMeta[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectStage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : (isCompleted ? const Color(0xFFE8F5E9) : Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meta['icon'] as String,
                      style: TextStyle(fontSize: isSelected ? 18 : 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isCompleted ? const Color(0xFF1B5E20) : const Color(0xFF757575)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
