import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/milestone_stage.dart';

/// Floating Step Path Map Widget.
/// Renders winding step tiles over the background video, displaying icons
/// for each milestone stage cleanly without any background image overlays.
class LandDiscoveryMap extends StatelessWidget {
  final MilestoneStage stage;
  final int totalStages;
  final List<MilestoneStage>? stages;
  final int activeIndex;
  final ValueChanged<int>? onStageSelected;

  const LandDiscoveryMap({
    super.key,
    required this.stage,
    required this.totalStages,
    this.stages,
    this.activeIndex = 0,
    this.onStageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final stageList = stages ?? [stage];
    final int displayCount = math.min(7, stageList.length);

    // Calculate start index for visible 7 tiles window centered around activeIndex
    int startIdx = 0;
    if (stageList.length > 7) {
      startIdx = (activeIndex - 3).clamp(0, stageList.length - 7);
    }

    return Container(
      color: Colors.transparent, // Completely transparent so background video displays continuously
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),

            // Winding Step Tiles Path
            SizedBox(
              width: screenWidth * 0.90,
              height: 330,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // S-Curve path line connecting tiles
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _IslandPathPainter(),
                    ),
                  ),

                  // Stage Step Tiles with Proper Stage Icons
                  ...List.generate(displayCount, (i) {
                    final int stageIdx = startIdx + i;
                    if (stageIdx >= stageList.length) return const SizedBox.shrink();

                    final currentStage = stageList[stageIdx];
                    final bool isActiveStep = (stageIdx == activeIndex);

                    final double factor = (i % 2 == 0) ? 0.20 : 0.65;
                    final double x = (screenWidth * 0.82) * factor;
                    final double y = i * 42.0;

                    return Positioned(
                      left: x,
                      top: y,
                      child: GestureDetector(
                        onTap: () => onStageSelected?.call(stageIdx),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Hexagon Tile Shape & Glow
                            ClipPath(
                              clipper: _HexTileClipper(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isActiveStep ? 58 : 50,
                                height: isActiveStep ? 52 : 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isActiveStep
                                        ? [
                                            const Color(0xFFF9E79F),
                                            const Color(0xFFF1C40F),
                                            const Color(0xFFD4AC0D),
                                          ]
                                        : [
                                            const Color(0xFFE5D5C0),
                                            const Color(0xFFA6947D),
                                          ],
                                  ),
                                  boxShadow: [
                                    if (isActiveStep)
                                      const BoxShadow(
                                        color: Color(0xFFF1C40F),
                                        blurRadius: 16,
                                        spreadRadius: 3,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    currentStage.assetPath,
                                    width: isActiveStep ? 32 : 26,
                                    height: isActiveStep ? 32 : 26,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      currentStage.fallbackIcon,
                                      size: isActiveStep ? 24 : 20,
                                      color: const Color(0xFF382A1C),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Stage Number Badge Pill on top-right
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isActiveStep
                                      ? const Color(0xFF2ECC71)
                                      : (currentStage.isUnlocked
                                          ? const Color(0xFF27AE60)
                                          : Colors.grey.shade700),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  '${currentStage.stageNumber}',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),

                            // Mascot Boy Character Sprite standing on Active Step Tile
                            if (isActiveStep)
                              Positioned(
                                top: -42,
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Image.asset(
                                    'assets/sprites/avatar_boy_hero.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/logo/mascot_transparent.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_pin,
                                        color: Color(0xFFF1C40F),
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5B041).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.25, 20);
    path.quadraticBezierTo(size.width * 0.8, 80, size.width * 0.25, 140);
    path.quadraticBezierTo(size.width * 0.8, 200, size.width * 0.25, 260);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IslandPathPainter oldDelegate) => false;
}

class _HexTileClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

