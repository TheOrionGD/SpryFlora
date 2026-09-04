import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../models/milestone_stage.dart';
import '../widgets/cloud_transition_overlay.dart';
import '../widgets/stage_pedestal_card.dart';
import '../widgets/journey_bottom_dock.dart';
import '../widgets/land_discovery_map.dart';
import '../widgets/journey_path_painter.dart';
import '../widgets/milestone_card.dart';

enum MascotJourneyViewMode {
  singleStage,  // Single Stage Pedestal & Island Map (Image 1)
  gridOverview, // 16-Stage Grid Overview Matrix (Image 2)
  verticalMap,  // S-Curve Full Vertical Map
}

/// Main Controller Screen for SpryFlora 16-Stage Mascot Journey Flow.
/// Features Clash of Clans (CoC) Cloud Transitions, Video Player Background Loop,
/// Central Stone Hexagonal Stage Pedestal, Land Discovery Map, and Bottom Carved Dock.
class MascotJourneyScreen extends StatefulWidget {
  final int initialActiveIndex;

  const MascotJourneyScreen({
    super.key,
    this.initialActiveIndex = 0, // Default starts at Stage 1 (index 0)
  });

  @override
  State<MascotJourneyScreen> createState() => _MascotJourneyScreenState();
}

class _MascotJourneyScreenState extends State<MascotJourneyScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  late List<MilestoneStage> _stages;
  late int _currentStageIndex;
  MascotJourneyViewMode _viewMode = MascotJourneyViewMode.singleStage;

  // Floating mascot bounce animation
  late final AnimationController _bounceCtrl;
  late final ScrollController _scrollController;

  static const double _cardWidth = 130.0;
  static const double _verticalSpacing = 210.0;
  static const double _topPadding = 120.0;
  static const double _bottomPadding = 160.0;

  @override
  void initState() {
    super.initState();
    _currentStageIndex = widget.initialActiveIndex;
    _stages = MilestoneStage.getDummyStages(activeIndex: _currentStageIndex);
    _scrollController = ScrollController();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _initVideoBackground();
  }

  /// Initializes Video Background Loop for assets/sprites/bg.mp4
  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/sprites/bg.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true); // Loop video continuously
      _videoController!.setVolume(0.0);   // Muted background loop
      await _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video Player loop notice: $e. Falling back to organic nature backdrop.');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _bounceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers Clash of Clans style Cloud Sweep and advances stage at 50% occlusion
  void _onNextStagePressed(CloudTransitionOverlayState? cloudOverlay) {
    if (cloudOverlay == null) {
      _advanceStageIndex();
      return;
    }

    cloudOverlay.triggerTransition(
      onCovered: () {
        if (mounted) {
          setState(() {
            _advanceStageIndex();
          });
        }
      },
    );
  }

  void _advanceStageIndex() {
    _currentStageIndex = (_currentStageIndex + 1) % _stages.length;
    _stages = MilestoneStage.getDummyStages(activeIndex: _currentStageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final activeStage = _stages[_currentStageIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildTopAppBar(activeStage),
      body: CloudTransitionOverlay(
        child: Builder(
          builder: (innerContext) {
            final cloudOverlay = CloudTransitionOverlay.of(innerContext);

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Video Player Background or Organic Nature Fallback Backdrop
                Positioned.fill(
                  child: _buildBackgroundBackdrop(),
                ),

                // Translucent gradient overlay for high contrast readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.40),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Active Screen Content based on _viewMode
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _buildMainContent(activeStage, cloudOverlay),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(MilestoneStage activeStage) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.park, color: Color(0xFF2ECC71), size: 18),
            const SizedBox(width: 6),
            Text(
              'Mascot Journey',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1C40F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Stage ${_currentStageIndex + 1}/${_stages.length}',
                style: GoogleFonts.nunito(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        // Grid Overview / Map Toggle Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _viewMode == MascotJourneyViewMode.gridOverview
                  ? Icons.view_day_rounded
                  : Icons.map_rounded,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            setState(() {
              if (_viewMode == MascotJourneyViewMode.singleStage) {
                _viewMode = MascotJourneyViewMode.gridOverview;
              } else if (_viewMode == MascotJourneyViewMode.gridOverview) {
                _viewMode = MascotJourneyViewMode.verticalMap;
              } else {
                _viewMode = MascotJourneyViewMode.singleStage;
              }
            });
          },
          tooltip: 'Toggle View Mode',
        ),

        // Floating Seedling Boy Mascot Avatar Tag
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: AnimatedBuilder(
            animation: _bounceCtrl,
            builder: (context, child) {
              final floatY = math.sin(_bounceCtrl.value * math.pi) * 4;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2ECC71),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 6),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/sprites/avatar_boy_hero.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    MilestoneStage activeStage,
    CloudTransitionOverlayState? cloudOverlay,
  ) {
    switch (_viewMode) {
      case MascotJourneyViewMode.singleStage:
        return _buildSingleStageView(activeStage, cloudOverlay);
      case MascotJourneyViewMode.gridOverview:
        return _build16StageGridOverview(cloudOverlay);
      case MascotJourneyViewMode.verticalMap:
        return _buildVerticalPathMapView();
    }
  }

  /// Single Stage Screen: Central Floating Mascot Display + Transparent Step Path Map + Bottom Console Dock
  Widget _buildSingleStageView(
    MilestoneStage activeStage,
    CloudTransitionOverlayState? cloudOverlay,
  ) {
    return SafeArea(
      child: Stack(
        children: [
          // 1. Background Step Path Map (Transparent over video background)
          Positioned.fill(
            child: LandDiscoveryMap(
              stage: activeStage,
              totalStages: _stages.length,
              stages: _stages,
              activeIndex: _currentStageIndex,
              onStageSelected: (index) {
                if (cloudOverlay != null) {
                  cloudOverlay.triggerTransition(
                    onCovered: () {
                      if (mounted) {
                        setState(() {
                          _currentStageIndex = index;
                          _stages = MilestoneStage.getDummyStages(
                            activeIndex: _currentStageIndex,
                          );
                        });
                      }
                    },
                  );
                } else {
                  setState(() {
                    _currentStageIndex = index;
                    _stages = MilestoneStage.getDummyStages(
                      activeIndex: _currentStageIndex,
                    );
                  });
                }
              },
            ),
          ),

          // 2. Containerless Floating Stage Mascot Display (No diamond stone box container)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: StagePedestalCard(
                stage: activeStage,
                size: 210,
                isGlowing: true,
              ),
            ),
          ),

          // 3. Bottom Carved Stone Console Dock with EXPLORE button
          Align(
            alignment: Alignment.bottomCenter,
            child: JourneyBottomDock(
              stage: activeStage,
              totalStages: _stages.length,
              onNextStage: () => _onNextStagePressed(cloudOverlay),
            ),
          ),
        ],
      ),
    );
  }

  /// 16-Stage Grid Overview Matrix (Image 2)
  Widget _build16StageGridOverview(CloudTransitionOverlayState? cloudOverlay) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.58,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _stages.length,
              itemBuilder: (context, index) {
                final stage = _stages[index];
                final isCurrent = (index == _currentStageIndex);

                return GestureDetector(
                  onTap: () {
                    if (cloudOverlay != null) {
                      cloudOverlay.triggerTransition(
                        onCovered: () {
                          setState(() {
                            _currentStageIndex = index;
                            _stages = MilestoneStage.getDummyStages(
                              activeIndex: _currentStageIndex,
                            );
                            _viewMode = MascotJourneyViewMode.singleStage;
                          });
                        },
                      );
                    } else {
                      setState(() {
                        _currentStageIndex = index;
                        _stages = MilestoneStage.getDummyStages(
                          activeIndex: _currentStageIndex,
                        );
                        _viewMode = MascotJourneyViewMode.singleStage;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFF1C40F).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFF1C40F)
                            : Colors.white24,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Small Stage Badge Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: StagePedestalCard(
                              stage: stage,
                              size: 90,
                              isGlowing: isCurrent,
                            ),
                          ),
                        ),

                        // Mini Land Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7355),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            stage.landName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Overall Progress Footer Bar
          Container(
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.85),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              'Overall Progress: ${_currentStageIndex + 1} Completed, Stage ${_currentStageIndex + 1} Current. '
              'Total Stages: ${_stages.length} / Chapter Progress: ${((_currentStageIndex + 1) / _stages.length * 100).round()}% / GROWING STRONG!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// S-Curve Full Vertical Map View
  Widget _buildVerticalPathMapView() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double totalHeight =
        _topPadding + (_stages.length * _verticalSpacing) + _bottomPadding;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: JourneyPathPainter(
                  totalCount: _stages.length,
                  activeIndex: _currentStageIndex,
                  verticalSpacing: _verticalSpacing,
                  topPadding: _topPadding,
                ),
              ),
            ),

            ...List.generate(_stages.length, (index) {
              final stage = _stages[index];
              final cardOffset = _getCardOffset(index, screenWidth);

              return Positioned(
                left: cardOffset.dx,
                top: cardOffset.dy,
                child: MilestoneCard(
                  stage: stage,
                  onTap: () {
                    setState(() {
                      _currentStageIndex = index;
                      _stages = MilestoneStage.getDummyStages(
                        activeIndex: _currentStageIndex,
                      );
                      _viewMode = MascotJourneyViewMode.singleStage;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBackdrop() {
    if (_isVideoInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // Organic Nature Sky/Forest Backdrop Fallback (Gradient without opaque static image overlay)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B4F72),
            Color(0xFF2E86C1),
            Color(0xFF1E8449),
            Color(0xFF114B27),
          ],
        ),
      ),
    );
  }

  Offset _getCardOffset(int index, double screenWidth) {
    const double padding = 28.0;
    final double usableW = screenWidth - (padding * 2) - _cardWidth;

    final double factor = (index % 4 == 0)
        ? 0.5
        : (index % 4 == 1)
            ? 0.88
            : (index % 4 == 2)
                ? 0.5
                : 0.12;

    final double x = padding + (usableW * factor);
    final double y = _topPadding + (index * _verticalSpacing);

    return Offset(x, y);
  }
}
