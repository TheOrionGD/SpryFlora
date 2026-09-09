import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';

/// Smooth Growth Stage Visualizer Component
/// Renders 4 growth stages with zero jitter, fixed bounding boxes (220x260),
/// bottom-anchored cross-fade scaling transitions, interactive timeline stepper,
/// dynamic day range auto-calculations based on plant lifespan, and an interactive Lifecycle Playback Controller.
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
    with TickerProviderStateMixin {
  late int _currentStageIndex;

  // Lifecycle Playback State
  bool _isPlaying = false;
  bool _isLooping = true;
  double _playbackSpeed = 1.0; // 0.5x, 1.0x, 2.0x
  Timer? _playbackTimer;
  late AnimationController _progressController;
  late AnimationController _pulseGlowController;

  static const List<Map<String, dynamic>> _stagesMeta = [
    {
      'name': 'Seed',
      'icon': '🌱',
      'fraction': 0.15,
      'title': 'Stage 0: Germination & Seed',
      'desc':
          'Seed shell cracks open in rich soil, sending the primary taproot downward and first tender root tip upward.',
      'care':
          'Keep soil moist. Gentle warmth without direct intense scorching sun.',
    },
    {
      'name': 'Sprout',
      'icon': '🌿',
      'fraction': 0.40,
      'title': 'Stage 1: Baby Sprout (Cotyledon)',
      'desc':
          'Two tender baby leaves unfurl to initiate initial photosynthesis and stem elongation.',
      'care': 'Moderate indirect sunlight. Light misting every 2-3 days.',
    },
    {
      'name': 'Growing',
      'icon': '🪴',
      'fraction': 0.80,
      'title': 'Stage 2: Vegetative Growth',
      'desc':
          'Rapid stem branching, true foliage development, and strong root network stabilization.',
      'care': 'Consistent watering routine. 4-6 hours of daily sunlight.',
    },
    {
      'name': 'Mature',
      'icon': '🌸',
      'fraction': 1.0,
      'title': 'Stage 3: Full Maturity & Blooming',
      'desc':
          'Flourishing adult foliage with signature species blossoms, ready for diploma certification.',
      'care': 'Maintain optimal hydration score and log sunlight daily.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStageIndex = widget.initialStageIndex.clamp(0, 3);

    _progressController = AnimationController(
      vsync: this,
      duration: _stageDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _pulseGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SmoothStageGrowthViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plant.id != widget.plant.id) {
      _stopPlayback();
      setState(() {
        _currentStageIndex = widget.initialStageIndex.clamp(0, 3);
      });
      _progressController.reset();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _progressController.dispose();
    _pulseGlowController.dispose();
    super.dispose();
  }

  Duration get _stageDuration {
    final baseMs = (2400 / _playbackSpeed).round();
    return Duration(milliseconds: baseMs);
  }

  /// Auto-calculates stage day ranges dynamically based on the plant's lifespan in days
  String getStageDayRange(int stageIndex) {
    final lifespan = widget.plant.lifespanDays > 0 ? widget.plant.lifespanDays : 180;

    // Stage 0: 0% to 15% of lifespan
    final s0End = (lifespan * 0.15).round().clamp(1, lifespan);
    // Stage 1: 15% to 40% of lifespan
    final s1Start = (s0End + 1).clamp(1, lifespan);
    final s1End = (lifespan * 0.40).round().clamp(s1Start, lifespan);
    // Stage 2: 40% to 80% of lifespan
    final s2Start = (s1End + 1).clamp(1, lifespan);
    final s2End = (lifespan * 0.80).round().clamp(s2Start, lifespan);
    // Stage 3: 80% to 100% of lifespan
    final s3Start = (s2End + 1).clamp(1, lifespan);
    final s3End = lifespan;

    switch (stageIndex) {
      case 0:
        return 'Days 1 - $s0End';
      case 1:
        return 'Days $s1Start - $s1End';
      case 2:
        return 'Days $s2Start - $s2End';
      case 3:
      default:
        return 'Days $s3Start - $s3End';
    }
  }

  /// Calculates the simulated day of growth for the current stage transition
  int _calculateSimulatedDay(int stageIdx) {
    final lifespan = widget.plant.lifespanDays > 0 ? widget.plant.lifespanDays : 180;
    switch (stageIdx) {
      case 0:
        return 1;
      case 1:
        return (lifespan * 0.25).round().clamp(1, lifespan);
      case 2:
        return (lifespan * 0.60).round().clamp(1, lifespan);
      case 3:
      default:
        return lifespan;
    }
  }

  void _selectStage(int index, {bool fromPlayer = false}) {
    if (_currentStageIndex == index && !fromPlayer) return;
    setState(() {
      _currentStageIndex = index.clamp(0, 3);
    });
    widget.onStageChanged?.call(_currentStageIndex);
  }

  // ── Playback Controls ──

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    setState(() {
      _isPlaying = true;
    });
    _runStageCycle();
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _progressController.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _progressController.reset();
    setState(() {
      _isPlaying = false;
    });
  }

  void _runStageCycle() {
    if (!_isPlaying) return;

    _progressController.duration = _stageDuration;
    _progressController.forward(from: 0.0).then((_) {
      if (!_isPlaying || !mounted) return;

      if (_currentStageIndex < 3) {
        _selectStage(_currentStageIndex + 1, fromPlayer: true);
        _runStageCycle();
      } else {
        // Reached end stage (Stage 3)
        if (_isLooping) {
          _selectStage(0, fromPlayer: true);
          _runStageCycle();
        } else {
          _pausePlayback();
        }
      }
    });
  }

  void _nextStage() {
    _pausePlayback();
    final next = (_currentStageIndex + 1) % 4;
    _selectStage(next);
  }

  void _prevStage() {
    _pausePlayback();
    final prev = (_currentStageIndex - 1 + 4) % 4;
    _selectStage(prev);
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 0.5) {
        _playbackSpeed = 1.0;
      } else if (_playbackSpeed == 1.0) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 0.5;
      }
      _progressController.duration = _stageDuration;
    });
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  List<String> get _paths {
    if (widget.stageFilePaths != null && widget.stageFilePaths!.isNotEmpty) {
      return widget.stageFilePaths!;
    }
    if (widget.plant.stageImagePaths != null &&
        widget.plant.stageImagePaths!.isNotEmpty) {
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

    // Default Botanical Fallback
    return _buildFallbackPlantAsset(index);
  }

  Widget _buildFallbackPlantAsset(int index) {
    final emojis = ['🌱', '🌿', '🪴', '🌸'];
    final heights = [55.0, 95.0, 135.0, 165.0];

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
              style: TextStyle(fontSize: 36.0 + (index * 13.0)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Terracotta pot representation
        Container(
          width: 82,
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
              width: 72,
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

  void _showAIPromptModal() {
    final prompt = AIService().getEnhancedPlantStagePrompt(
      speciesName: widget.plant.speciesName,
      stageIndex: _currentStageIndex,
      plant: widget.plant,
    );
    final meta = _stagesMeta[_currentStageIndex];
    final dayRange = getStageDayRange(_currentStageIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF2E7D32), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgraded AI Image Prompt',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          '${widget.plant.plantName} (${widget.plant.speciesName}) • ${meta['name']} ($dayRange)',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: SelectableText(
                  prompt,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF2E4032),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: prompt));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✨ Copied prompt for ${widget.plant.speciesName} (${meta['name']} • $dayRange)!'),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        'Copy AI Prompt',
                        style: GoogleFonts.fredoka(
                            fontSize: 14, fontWeight: FontWeight.w700),
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
    final meta = _stagesMeta[_currentStageIndex];
    final dayRange = getStageDayRange(_currentStageIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Stage Pedestal & Plant Image Viewer Container ──
        Container(
          width: 280,
          height: 310,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isPlaying
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFA5D6A7),
              width: _isPlaying ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPlaying
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
                    : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                blurRadius: _isPlaying ? 24 : 18,
                spreadRadius: _isPlaying ? 2 : 0,
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

              // Fixed Size Stage Container (Width: 220, Height: 260) with Zero-Jitter AnimatedSwitcher
              SizedBox(
                width: 220,
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 650),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    layoutBuilder: (Widget? currentChild,
                        List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.90, end: 1.0)
                              .animate(animation),
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      );
                    },
                    child: _buildStageImageWidget(_currentStageIndex),
                  ),
                ),
              ),

              // Auto-calculated Stage Day Range Tag Badge (Top Left)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dayRange,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // AI Prompt Inspector Button (Top Right)
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: _showAIPromptModal,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF2E7D32), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Prompt',
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
              ),

              // Live Playing Indicator Ribbon (Bottom Center)
              if (_isPlaying)
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GROWTH TIMELAPSE PLAYING',
                          style: GoogleFonts.fredoka(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
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

        // ── Interactive Lifecycle Playback Transition Controller (Below 4 Stages) ──
        _buildLifecyclePlaybackController(),

        const SizedBox(height: 16),

        // ── Stage Detail Card ──
        _buildStageDetailCard(meta, dayRange),
      ],
    );
  }

  Widget _buildTimelineStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isSelected = _currentStageIndex == index;
          final isCompleted = _currentStageIndex > index;
          final meta = _stagesMeta[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                _pausePlayback();
                _selectStage(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : (isCompleted
                          ? const Color(0xFFE8F5E9)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32)
                                .withValues(alpha: 0.35),
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
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isCompleted
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF757575)),
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

  /// Interactive Lifecycle Transition Player below the 4 stages uniquely tailored for the selected plant
  Widget _buildLifecyclePlaybackController() {
    final simulatedDay = _calculateSimulatedDay(_currentStageIndex);
    final lifespan = widget.plant.lifespanDays > 0 ? widget.plant.lifespanDays : 180;
    final stageName = _stagesMeta[_currentStageIndex]['name'] as String;
    final stageDayRange = getStageDayRange(_currentStageIndex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.98),
            const Color(0xFFF1F8E9).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isPlaying ? const Color(0xFF81C784) : const Color(0xFFC8E6C9),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: _isPlaying
                ? const Color(0xFF4CAF50).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Plant & Stage Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: const Icon(Icons.motion_photos_auto_rounded,
                        color: Color(0xFF2E7D32), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth Transition Player',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        '${widget.plant.plantName} • Simulated Day $simulatedDay of $lifespan ($stageDayRange)',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Current Stage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Stage $_currentStageIndex: $stageName',
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Animated Transition Timeline Bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  final baseFraction = _currentStageIndex / 3.0;
                  final nextFraction = (_currentStageIndex + 1) / 3.0;
                  final animatedProgress = _isPlaying
                      ? (baseFraction +
                              (nextFraction - baseFraction) *
                                  _progressController.value)
                          .clamp(0.0, 1.0)
                      : (_currentStageIndex / 3.0).clamp(0.0, 1.0);

                  return FractionallySizedBox(
                    widthFactor: animatedProgress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2E7D32).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Playback Controls Row (Prev, Big Play/Pause, Next, Speed, Loop, Prompt) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Stage
              IconButton(
                onPressed: _prevStage,
                tooltip: 'Previous Stage',
                icon: const Icon(Icons.skip_previous_rounded,
                    color: Color(0xFF2E7D32), size: 24),
              ),

              // ── Big Play / Pause Button ──
              GestureDetector(
                onTap: _togglePlayback,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlaying
                          ? [const Color(0xFFD32F2F), const Color(0xFFC62828)]
                          : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _isPlaying
                            ? const Color(0xFFD32F2F).withValues(alpha: 0.4)
                            : const Color(0xFF2E7D32).withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPlaying ? 'PAUSE' : 'PLAY 4-STAGES',
                        style: GoogleFonts.fredoka(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Next Stage
              IconButton(
                onPressed: _nextStage,
                tooltip: 'Next Stage',
                icon: const Icon(Icons.skip_next_rounded,
                    color: Color(0xFF2E7D32), size: 24),
              ),

              // Speed Switcher Chip
              GestureDetector(
                onTap: _cycleSpeed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ),

              // Loop Toggle Button
              IconButton(
                onPressed: _toggleLoop,
                tooltip: _isLooping ? 'Looping Enabled' : 'Play Once',
                icon: Icon(
                  _isLooping ? Icons.repeat_rounded : Icons.repeat_one_rounded,
                  color: _isLooping
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9E9E9E),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageDetailCard(Map<String, dynamic> meta, String dayRange) {
    final lifespan = widget.plant.lifespanDays > 0 ? widget.plant.lifespanDays : 180;

    return Container(
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
              Text(meta['icon'] as String,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${meta['title']}',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Text(
                  dayRange,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
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
          const SizedBox(height: 6),
          Text(
            'Plant Lifespan: $lifespan days total for ${widget.plant.speciesName}',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF388E3C),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFE0E0E0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: Color(0xFFFFA000), size: 16),
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
    );
  }
}
