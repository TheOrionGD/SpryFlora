import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/milestone_stage.dart';

/// Hexagonal Carved Stone Stage Badge Widget (matching Image 2 & 3).
/// Displays stage number in top corner, central botanical emblem, badge symbol title,
/// and warm ambient golden glow.
class HexagonalStageBadge extends StatelessWidget {
  final MilestoneStage stage;
  final double size;
  final bool isGlowing;

  const HexagonalStageBadge({
    super.key,
    required this.stage,
    this.size = 220.0,
    this.isGlowing = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Golden Glowing Background Aura
          if (isGlowing)
            Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF39C12).withValues(alpha: 0.45),
                    const Color(0xFFF1C40F).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

          // 2. Custom Hexagon Stone Container
          ClipPath(
            clipper: _HexagonClipper(),
            child: Container(
              width: size * 0.88,
              height: size * 1.05,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD5C3A5),
                    Color(0xFFB8A281),
                    Color(0xFF8C765C),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Beveled Inner Stone Border
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipPath(
                        clipper: _HexagonClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFEDE1CF),
                                Color(0xFFC7B496),
                                Color(0xFF9E8B72),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFF1C40F).withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content (Stage Number + Center Emblem + Symbol Title)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Row: Stage Number in top left
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              '${stage.stageNumber}',
                              style: GoogleFonts.cinzel(
                                fontSize: size * 0.16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4A3B2C),
                                shadows: const [
                                  Shadow(
                                    color: Colors.white60,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center Botanical Emblem / Asset
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: size * 0.45,
                              height: size * 0.45,
                              child: Image.asset(
                                stage.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  stage.fallbackIcon,
                                  size: size * 0.40,
                                  color: const Color(0xFF4A3A2A),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Title Text
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            stage.badgeSymbol.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: size * 0.10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: const Color(0xFF382A1C),
                              shadows: const [
                                Shadow(
                                  color: Colors.white70,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
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
