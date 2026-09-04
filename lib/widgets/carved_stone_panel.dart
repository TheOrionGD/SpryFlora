import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/milestone_stage.dart';

/// Carved Stone Fantasy Panel Container (matching Image 2 & Image 3).
/// Displays stage title, description/land discovery, GO TO NEXT STAGE button,
/// progress bar with diamond caps, and bottom chapter stats.
class CarvedStonePanel extends StatelessWidget {
  final MilestoneStage stage;
  final int totalStages;
  final VoidCallback onNextStage;
  final bool isLandDiscoveryMode;

  const CarvedStonePanel({
    super.key,
    required this.stage,
    required this.totalStages,
    required this.onNextStage,
    this.isLandDiscoveryMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final double chapterProgress =
        (stage.stageNumber / totalStages).clamp(0.0, 1.0);
    final int progressPercent = (chapterProgress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Carved Stone Container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDED0BC),
                Color(0xFFC4B39C),
                Color(0xFFA6947D),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B7355), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative Top Swirl Header Title
              Text(
                isLandDiscoveryMode
                    ? 'Mascot Boy'
                    : 'Stage ${stage.stageNumber}: ${stage.title.toUpperCase()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF382A1C),
                  shadows: const [
                    Shadow(color: Colors.white70, offset: Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Description or Land Discovered Banner
              if (isLandDiscoveryMode) ...[
                Text(
                  'New Land Discovered:',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A4936),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.landName,
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C1E10),
                  ),
                ),
              ] else ...[
                Text(
                  stage.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A3B2C),
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // "GO TO NEXT STAGE" / "EXPLORE" Green Pill Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 8,
                    shadowColor: const Color(0xFF2ECC71).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: const BorderSide(color: Color(0xFF82E0AA), width: 2),
                    ),
                  ),
                  onPressed: onNextStage,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF52BE80),
                          Color(0xFF27AE60),
                          Color(0xFF1E8449),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF1C40F), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isLandDiscoveryMode
                                ? 'EXPLORE'
                                : 'GO TO NEXT STAGE',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Milestone Progress Bar with Diamond Caps
              _buildMilestoneProgressBar(stage.stageNumber, totalStages),
            ],
          ),
        ),

        // Subtitle Stats Bar at Very Bottom
        Container(
          width: double.infinity,
          color: Colors.black.withValues(alpha: 0.75),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            'Total Stages: ${stage.stageNumber} / $totalStages / Chapter Progress: $progressPercent% / '
            '${isLandDiscoveryMode ? "EXPLORATION BEGUN!" : "GROWING STRONG!"}',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneProgressBar(int current, int total) {
    final double fraction = (current / total).clamp(0.0, 1.0);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5842),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A3A2A), width: 1.5),
      ),
      child: Row(
        children: [
          // Left Diamond Cap
          Transform.rotate(
            angle: 0.785, // 45 deg
            child: Container(
              width: 10,
              height: 10,
              color: const Color(0xFFF1C40F),
            ),
          ),
          const SizedBox(width: 6),

          // Progress Bar Track & Fill
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 12,
                    backgroundColor: const Color(0xFF4A3A2A),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF1C40F),
                    ),
                  ),
                ),
                Text(
                  'Milestone: $current / $total',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),
          // Right Diamond Cap
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 10,
              height: 10,
              color: const Color(0xFF9B59B6),
            ),
          ),
        ],
      ),
    );
  }
}
