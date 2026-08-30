import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Plant Growth Animation & Stage Visualizer
///
/// Mathematical rules strictly enforced:
/// A = Plant Age
/// L = Lifespan
/// F = Total Frames (default 150)
/// Growth Progress = A / L (clamped 0.0 -> 1.0)
/// Frame Index = floor(Growth Progress * (F - 1))
///
/// If user closes and returns tomorrow, actual age dictates the frame.
/// Shorter lifespan plants progress faster for the same chronological age.
class PlantGrowthAnimation extends StatelessWidget {
  final int plantAge;
  final int lifespanDays;
  final String speciesName;
  final double height;
  final int totalFrames;

  const PlantGrowthAnimation({
    super.key,
    required this.plantAge,
    required this.lifespanDays,
    required this.speciesName,
    this.height = 240,
    this.totalFrames = 150,
  });

  /// Frame Index calculation
  int get frameIndex {
    if (lifespanDays <= 0) return totalFrames - 1;
    final double progress = (plantAge / lifespanDays).clamp(0.0, 1.0);
    return (progress * (totalFrames - 1)).floor();
  }

  double get growthProgress {
    if (lifespanDays <= 0) return 1.0;
    return (plantAge / lifespanDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = growthProgress;
    final frame = frameIndex;
    final speciesKey = speciesName.toLowerCase().replaceAll(' ', '_');
    final String frameNumber = (frame + 1).toString().padLeft(3, '0');
    final String imagePath = 'assets/animations/$speciesKey/frame_$frameNumber.png';

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: SkeuoTheme.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFBDCDBD),
          width: 1.5,
        ),
        boxShadow: [
          // Deep physical viewport inset shadow
          BoxShadow(
            color: const Color(0xFF6B7C6E).withValues(alpha: 0.45),
            offset: const Offset(3, 4),
            blurRadius: 8,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background biological grid/environment glow
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    const Color(0xFFC8E6C9).withValues(alpha: 0.5),
                    const Color(0xFFE8F5E9).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Plant growth frame renderer (Image frame with offline animated procedural canvas fallback)
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    painter: ProceduralPlantGrowthPainter(
                      progress: progress,
                      speciesName: speciesName,
                    ),
                  );
                },
              ),
            ),

            // Physical glass shine overlay across the viewport
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.04),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom Tactile Progress Plate
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: SkeuoTheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse_rounded,
                          size: 16,
                          color: SkeuoTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Stage: Frame ${frame + 1}/$totalFrames',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Maturity',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: SkeuoTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-left Species Lifespan Badge
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SkeuoTheme.surfaceDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${plantAge}d / ${lifespanDays}d Lifespan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SkeuoTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offline procedural growth painter that renders accurate morphological plant stages
/// corresponding strictly to progress (0.0 to 1.0)
class ProceduralPlantGrowthPainter extends CustomPainter {
  final double progress;
  final String speciesName;
  final bool showPot;

  ProceduralPlantGrowthPainter({
    required this.progress,
    required this.speciesName,
    this.showPot = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * (showPot ? 0.82 : 0.88));
    final potTopY = center.dy;
    final potWidth = size.width * 0.42;

    if (showPot) {
      // 1. Draw Terracotta / Skeuomorphic Physical Pot
      final potHeight = size.height * 0.22;

      final potPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD35400),
            const Color(0xFFE67E22),
            const Color(0xFFBA4A00),
          ],
        ).createShader(Rect.fromLTWH(center.dx - potWidth / 2, potTopY, potWidth, potHeight));

      final potPath = Path()
        ..moveTo(center.dx - potWidth * 0.5, potTopY)
        ..lineTo(center.dx + potWidth * 0.5, potTopY)
        ..lineTo(center.dx + potWidth * 0.38, potTopY + potHeight)
        ..lineTo(center.dx - potWidth * 0.38, potTopY + potHeight)
        ..close();

      // Pot Shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, potTopY + potHeight + 4),
          width: potWidth * 0.9,
          height: 12,
        ),
        Paint()..color = const Color(0xFF1B3820).withValues(alpha: 0.2),
      );

      // Pot Body
      canvas.drawPath(potPath, potPaint);

      // Pot Rim
      final rimPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFCA6F1E)],
        ).createShader(Rect.fromLTWH(center.dx - potWidth * 0.54, potTopY - 8, potWidth * 1.08, 12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, potTopY), width: potWidth * 1.08, height: 12),
          const Radius.circular(6),
        ),
        rimPaint,
      );

      // Rich Soil Surface inside pot
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, potTopY + 2), width: potWidth * 0.88, height: 10),
        Paint()..color = const Color(0xFF422415),
      );
    } else {
      // Direct Garden Ground: Lush rich earth mound with grass tufts
      final moundPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3E2723), Color(0xFF4E342E), Color(0xFF5D4037)],
        ).createShader(Rect.fromCircle(center: Offset(center.dx, potTopY), radius: potWidth * 0.6));

      // Earth mound base
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, potTopY + 4), width: potWidth * 1.2, height: 20),
        moundPaint,
      );
      // Top soil patch
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, potTopY), width: potWidth * 0.85, height: 12),
        Paint()..color = const Color(0xFF2E1A11),
      );

      // Grass tufts sprouting around root
      final grassPaint = Paint()
        ..color = const Color(0xFF43A047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      for (int g = -3; g <= 3; g++) {
        if (g == 0) continue;
        final gx = center.dx + g * 8.0;
        final gy = potTopY + 2;
        final grassPath = Path()
          ..moveTo(gx, gy)
          ..quadraticBezierTo(gx + (g > 0 ? 4 : -4), gy - 8, gx + (g > 0 ? 7 : -7), gy - 12);
        canvas.drawPath(grassPath, grassPaint);
      }
    }

    // 2. Strict Lifespan Stages based strictly on progress (0.0 -> 1.0)
    // Stage 0: Planted Seed in Soil (progress < 0.04) — Day 0 / first few days
    if (progress < 0.04) {
      // Draw cute planted seed in the center of the soil
      final seedCenter = Offset(center.dx, potTopY - 2);
      
      // Little seed mound depression
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, potTopY), width: 18, height: 6),
        Paint()..color = const Color(0xFF1B0E07),
      );

      // Planted Seed Body
      final seedPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
        ).createShader(Rect.fromCircle(center: seedCenter, radius: 5));

      canvas.drawOval(
        Rect.fromCenter(center: seedCenter, width: 8, height: 11),
        seedPaint,
      );

      // Tiny green sprout tip peeking out of the seed
      final sproutPaint = Paint()
        ..color = const Color(0xFF81C784)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final sproutPath = Path()
        ..moveTo(center.dx, potTopY - 6)
        ..quadraticBezierTo(center.dx + 2, potTopY - 9, center.dx + 4, potTopY - 11);
      canvas.drawPath(sproutPath, sproutPaint);
      canvas.drawCircle(Offset(center.dx + 4, potTopY - 11), 1.5, Paint()..color = const Color(0xFFA5D6A7));
      return;
    }

    // Stage 1 to 4: Sprout -> Young -> Branching -> Blooming
    final double stemMaxHeight = size.height * (showPot ? 0.58 : 0.65);
    // Smooth biological height curve: starts at 15% at progress=0.05, reaches 100% at progress=1.0
    final double normalizedGrowth = ((progress - 0.04) / 0.96).clamp(0.0, 1.0);
    final double currentStemHeight = stemMaxHeight * (0.12 + normalizedGrowth * 0.88);
    final double stemThickness = 2.5 + normalizedGrowth * 4.5;

    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemThickness
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()..moveTo(center.dx, potTopY);

    final tipX = center.dx + math.sin(progress * math.pi) * 6;
    final tipY = potTopY - currentStemHeight;

    stemPath.quadraticBezierTo(
      center.dx - (normalizedGrowth > 0.3 ? 5 : 1),
      potTopY - currentStemHeight * 0.5,
      tipX,
      tipY,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Dynamic Side Branches for mature plants (progress >= 0.55)
    if (progress >= 0.55) {
      final branchPaint = Paint()
        ..color = const Color(0xFF388E3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stemThickness * 0.6
        ..strokeCap = StrokeCap.round;

      final branchScale = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

      // Left branch
      final b1Y = potTopY - currentStemHeight * 0.45;
      final b1Path = Path()
        ..moveTo(center.dx - 2, b1Y)
        ..quadraticBezierTo(center.dx - (14 * branchScale), b1Y - (6 * branchScale), center.dx - (22 * branchScale), b1Y - (14 * branchScale));
      canvas.drawPath(b1Path, branchPaint);

      // Right branch
      final b2Y = potTopY - currentStemHeight * 0.65;
      final b2Path = Path()
        ..moveTo(center.dx + 2, b2Y)
        ..quadraticBezierTo(center.dx + (14 * branchScale), b2Y - (6 * branchScale), center.dx + (20 * branchScale), b2Y - (12 * branchScale));
      canvas.drawPath(b2Path, branchPaint);
    }

    // Leaves growth calculation: 2 baby leaves for young sprout (progress < 0.2), multiplying to 10 at maturity
    final int leafCount = progress < 0.20 ? 2 : (2 + ((progress - 0.20) / 0.80 * 8).floor());
    for (int i = 0; i < leafCount; i++) {
      final double leafProgress = (i + 1) / (leafCount + 1);
      final double nodeY = potTopY - (currentStemHeight * leafProgress);
      final bool isLeft = i.isEven;
      final double angle = isLeft ? -0.55 - (normalizedGrowth * 0.15) : 0.55 + (normalizedGrowth * 0.15);
      
      // Small leaves at seedling stage (8-14px), scaling up to full size (28px)
      final double leafSize = (8.0 + (normalizedGrowth * 22.0)) * (0.6 + leafProgress * 0.4);

      final leafCenter = Offset(
        center.dx + (isLeft ? -5 : 5) * leafProgress,
        nodeY,
      );

      canvas.save();
      canvas.translate(leafCenter.dx, leafCenter.dy);
      canvas.rotate(angle);

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(leafSize * 0.5, -leafSize * 0.4, leafSize, 0)
        ..quadraticBezierTo(leafSize * 0.5, leafSize * 0.4, 0, 0);

      final leafPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF81C784),
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
          ],
        ).createShader(Rect.fromLTWH(0, -leafSize * 0.4, leafSize, leafSize * 0.8));

      canvas.drawPath(leafPath, leafPaint);

      // Leaf central vein on developed leaves
      if (progress >= 0.30) {
        final veinPaint = Paint()
          ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset.zero, Offset(leafSize * 0.8, 0), veinPaint);
      }

      canvas.restore();
    }

    // Top Flower / Blossom or Herbal Buds — ONLY appears as plant matures (progress >= 0.75)
    final isTulsi = speciesName.toLowerCase().contains('tulsi') || speciesName.toLowerCase().contains('basil');
    final isRose = speciesName.toLowerCase().contains('rose');
    final isSunflower = speciesName.toLowerCase().contains('sunflower');

    if (progress >= 0.75) {
      final maturityScale = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);

      if (isTulsi) {
        // Tulsi top purple/green herbal floral spikes
        final spikePaint = Paint()..color = const Color(0xFF7B1FA2).withValues(alpha: 0.85 * maturityScale);
        final budPaint = Paint()..color = const Color(0xFF81C784);
        final count = (2 + 3 * maturityScale).floor();
        for (int s = 0; s < count; s++) {
          final sy = tipY - s * 5.0;
          canvas.drawCircle(Offset(tipX, sy), 3.0 * maturityScale, spikePaint);
          canvas.drawCircle(Offset(tipX - 3, sy + 2), 2.0 * maturityScale, budPaint);
          canvas.drawCircle(Offset(tipX + 3, sy + 2), 2.0 * maturityScale, budPaint);
        }
      } else {
        final flowerRadius = (16.0 * maturityScale).clamp(4.0, 16.0);
        final flowerColor = isRose
            ? const Color(0xFFE91E63)
            : isSunflower
                ? const Color(0xFFFFC107)
                : const Color(0xFFFF7043);

        final petalCount = isSunflower ? 8 : 6;
        for (int i = 0; i < petalCount; i++) {
          final petalAngle = (i * math.pi * 2 / petalCount);
          final petalX = tipX + math.cos(petalAngle) * (flowerRadius * 0.6);
          final petalY = tipY + math.sin(petalAngle) * (flowerRadius * 0.6);

          canvas.drawCircle(
            Offset(petalX, petalY),
            flowerRadius * 0.48,
            Paint()..color = flowerColor.withValues(alpha: 0.92),
          );
        }

        // Flower Center
        canvas.drawCircle(
          Offset(tipX, tipY),
          flowerRadius * (isSunflower ? 0.5 : 0.38),
          Paint()..color = isSunflower ? const Color(0xFF5D4037) : (isRose ? const Color(0xFF880E4F) : const Color(0xFFFFB300)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProceduralPlantGrowthPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.speciesName != speciesName || oldDelegate.showPot != showPot;
  }
}
