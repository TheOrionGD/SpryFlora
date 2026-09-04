import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/milestone_stage.dart';
import '../widgets/journey_path_painter.dart';
import '../widgets/milestone_card.dart';
import '../widgets/current_mascot_marker.dart';

/// Main screen displaying the Gamified Vertical Mascot Journey Map for SpryFlora.
/// Features looping MP4 background video, S-curve path painter, 16 milestone cards,
/// floating animated mascot marker, auto-scroll centering, and stage detail bottom sheet.
class MascotJourneyScreen extends StatefulWidget {
  final int initialActiveIndex;

  const MascotJourneyScreen({
    super.key,
    this.initialActiveIndex = 4, // Default active stage (5th milestone index 4)
  });

  @override
  State<MascotJourneyScreen> createState() => _MascotJourneyScreenState();
}

class _MascotJourneyScreenState extends State<MascotJourneyScreen> {
  late final ScrollController _scrollController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  late List<MilestoneStage> _stages;
  late int _activeMilestoneIndex;

  static const double _cardWidth = 130.0;
  static const double _cardHeight = 160.0;
  static const double _verticalSpacing = 210.0;
  static const double _topPadding = 120.0;
  static const double _bottomPadding = 160.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _activeMilestoneIndex = widget.initialActiveIndex;
    _stages = MilestoneStage.getDummyStages(activeIndex: _activeMilestoneIndex);

    _initVideoBackground();

    // Auto-scroll to center on activeMilestoneIndex after layout build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveMilestone(animate: true);
    });
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/sprites/bg.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0); // Muted background video playback
      _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint(
          'Video Player initialization notice: $e. Falling back to scenic image backdrop.');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _scrollToActiveMilestone({bool animate = false}) {
    if (!_scrollController.hasClients) return;

    final targetY = _topPadding + (_activeMilestoneIndex * _verticalSpacing);
    final screenHeight = MediaQuery.of(context).size.height;
    final scrollOffset = (targetY - (screenHeight / 2) + (_cardHeight / 2))
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animate) {
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(scrollOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double totalHeight =
        _topPadding + (_stages.length * _verticalSpacing) + _bottomPadding;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.park, color: Color(0xFF2ECC71), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Mascot Journey',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  'Stage ${_activeMilestoneIndex + 1}/16',
                  style: const TextStyle(
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
            onPressed: () => _scrollToActiveMilestone(animate: true),
            tooltip: 'Center on Active Level',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND VIDEO / IMAGE BACKDROP
          Positioned.fill(
            child: _buildBackgroundBackdrop(),
          ),

          // Dark translucent overlay gradient to ensure high contrast map readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),

          // 2. SCROLLABLE JOURNEY MAP STACK
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: screenWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  // A. CustomPainter winding S-curve track
                  Positioned.fill(
                    child: CustomPaint(
                      painter: JourneyPathPainter(
                        totalCount: _stages.length,
                        activeIndex: _activeMilestoneIndex,
                        verticalSpacing: _verticalSpacing,
                        topPadding: _topPadding,
                      ),
                    ),
                  ),

                  // B. Milestone Cards placed along the calculated S-curve anchors
                  ...List.generate(_stages.length, (index) {
                    final stage = _stages[index];
                    final cardOffset = _getCardOffset(index, screenWidth);

                    return Positioned(
                      left: cardOffset.dx,
                      top: cardOffset.dy,
                      child: MilestoneCard(
                        stage: stage,
                        onTap: () => _onStageSelected(stage),
                      ),
                    );
                  }),

                  // C. Floating Animated Current Mascot Marker over active level card
                  _buildPositionedMascotMarker(screenWidth),
                ],
              ),
            ),
          ),
        ],
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

    // Fallback: Scenic Image backdrop or lush gradient
    return Image.asset(
      'assets/sprites/image.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A362B),
                Color(0xFF0E231B),
                Color(0xFF05100B),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _getCardOffset(int index, double screenWidth) {
    final double padding = 28.0;
    final double usableW = screenWidth - (padding * 2) - _cardWidth;

    // S-curve alternating pattern matching JourneyPathPainter
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

  Widget _buildPositionedMascotMarker(double screenWidth) {
    if (_activeMilestoneIndex < 0 || _activeMilestoneIndex >= _stages.length) {
      return const SizedBox.shrink();
    }

    final activeStage = _stages[_activeMilestoneIndex];
    final cardOffset = _getCardOffset(_activeMilestoneIndex, screenWidth);
    final markerLeft = cardOffset.dx + (_cardWidth / 2) - 60.0;
    final markerTop = cardOffset.dy - 48.0;

    return Positioned(
      left: markerLeft,
      top: markerTop,
      child: CurrentMascotMarker(
        stageTitle: activeStage.title,
        onTap: () => _onStageSelected(activeStage),
      ),
    );
  }

  /// Triggers onStageSelected(int stageId) and shows stage detail Modal Bottom Sheet
  void _onStageSelected(MilestoneStage stage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E272E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag indicator bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Stage Header & Sprite display
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3A47),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: stage.isCurrent
                            ? const Color(0xFFF1C40F)
                            : const Color(0xFF2ECC71),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      stage.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        stage.fallbackIcon,
                        size: 36,
                        color: const Color(0xFF2ECC71),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'STAGE #${stage.stageNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stage.topic,
                              style: const TextStyle(
                                color: Color(0xFFBDC3C7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stage.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Description
              Text(
                stage.description,
                style: const TextStyle(
                  color: Color(0xFFDCDDE1),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // XP Reward Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3A47),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF1C40F), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completion Reward',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '+${stage.xpReward} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (stage.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF27AE60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF27AE60), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'COMPLETED',
                              style: TextStyle(
                                color: Color(0xFF27AE60),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Start / Replay Stage Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stage.isCurrent
                        ? const Color(0xFFF1C40F)
                        : const Color(0xFF2ECC71),
                    foregroundColor:
                        stage.isCurrent ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (stage.isCurrent) {
                      // Demo: Advance stage to next milestone
                      setState(() {
                        if (_activeMilestoneIndex < _stages.length - 1) {
                          _activeMilestoneIndex++;
                          _stages = MilestoneStage.getDummyStages(
                            activeIndex: _activeMilestoneIndex,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🎉 Stage #${stage.stageNumber} completed! Advanced to Stage #${_activeMilestoneIndex + 1}.',
                          ),
                          backgroundColor: const Color(0xFF27AE60),
                        ),
                      );
                      _scrollToActiveMilestone(animate: true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Replaying ${stage.title}...'),
                          backgroundColor: const Color(0xFF2ECC71),
                        ),
                      );
                    }
                  },
                  child: Text(
                    stage.isCurrent
                        ? 'START STAGE #${stage.stageNumber}'
                        : 'REPLAY STAGE',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
