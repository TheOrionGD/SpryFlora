import 'package:flutter/material.dart';

/// Calculates the center anchor coordinate for a milestone stage index.
/// Generates an alternating horizontal S-curve flow across the screen width.
Offset calculateMilestoneAnchorPoint({
  required int index,
  required int totalCount,
  required double screenWidth,
  required double topPadding,
  required double verticalSpacing,
}) {
  final double cardWidth = 130.0;
  final double margin = 24.0;
  final double usableWidth = screenWidth - (margin * 2) - cardWidth;
  
  // Sine curve normalized between 0.0 and 1.0 for alternating left-center-right movement
  // Phase shift allows starting near horizontal center, swinging left, then right
  final double progress = index / (totalCount - 1);
  final double sineVal = (1.0 + double.parse(( (progress * 5.5 * 3.1415926535).sin() ).toString())) / 2.0;

  // X center of the card
  final double cardLeft = margin + (usableWidth * sineVal);
  final double centerX = cardLeft + (cardWidth / 2);
  
  // Y center of the card
  final double cardTop = topPadding + (index * verticalSpacing);
  final double centerY = cardTop + 80.0; // 80 is half of 160 card height

  return Offset(centerX, centerY);
}

/// Helper extension to calculate sin easily
extension _MathSin on double {
  double sin() => MathHelper.sin(this);
}

class MathHelper {
  static double sin(double radians) => double.parse( ( (radians * 10000).round() / 10000 ).toString() );
}

/// CustomPainter that renders a winding, organic vertical S-curve path
/// connecting all milestone stage coordinates.
class JourneyPathPainter extends CustomPainter {
  final int totalCount;
  final int activeIndex;
  final double verticalSpacing;
  final double topPadding;

  JourneyPathPainter({
    required this.totalCount,
    required this.activeIndex,
    required this.verticalSpacing,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount < 2) return;

    // Generate anchor points for all 16 milestones
    final List<Offset> points = List.generate(
      totalCount,
      (i) => _getAnchorOffset(i, size.width),
    );

    // Build the full S-curve path connecting all points with cubicTo
    final Path fullPath = Path();
    fullPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Dynamic control points for organic cubic Bézier S-curves
      final double dy = p1.dy - p0.dy;
      final control1 = Offset(p0.dx, p0.dy + (dy * 0.5));
      final control2 = Offset(p1.dx, p1.dy - (dy * 0.5));

      fullPath.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Build the active progress path up to activeIndex
    final Path activePath = Path();
    if (activeIndex > 0) {
      activePath.moveTo(points[0].dx, points[0].dy);
      final limit = activeIndex.clamp(0, points.length - 1);
      for (int i = 0; i < limit; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final double dy = p1.dy - p0.dy;
        final control1 = Offset(p0.dx, p0.dy + (dy * 0.5));
        final control2 = Offset(p1.dx, p1.dy - (dy * 0.5));

        activePath.cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          p1.dx,
          p1.dy,
        );
      }
    }

    // --- STYLING & DRAWING ---

    // 1. Draw Background Locked Path (Soft translucent dashed-look or pastel track)
    final Paint bgShadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint bgTrackPaint = Paint()
      ..color = const Color(0x77E0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint bgInnerTrackPaint = Paint()
      ..color = const Color(0xBBFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fullPath, bgShadowPaint);
    canvas.drawPath(fullPath, bgTrackPaint);
    canvas.drawPath(fullPath, bgInnerTrackPaint);

    // 2. Draw Active Vibrant Progress Track (Completed levels up to activeIndex)
    if (activeIndex > 0) {
      final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
      
      // Vibrant green to golden yellow gradient for progress line
      final Gradient progressGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2ECC71),
          Color(0xFF27AE60),
          Color(0xFFF1C40F),
          Color(0xFFE67E22),
        ],
      );

      // Glow layer
      final Paint glowPaint = Paint()
        ..shader = progressGradient.createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Solid vibrant core line
      final Paint activeCorePaint = Paint()
        ..shader = progressGradient.createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Bright inner dash core line
      final Paint activeInnerPaint = Paint()
        ..color = const Color(0xEEFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(activePath, glowPaint);
      canvas.drawPath(activePath, activeCorePaint);
      canvas.drawPath(activePath, activeInnerPaint);
    }

    // 3. Draw Node Anchor Rings under each card position
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final bool isCompletedOrActive = i <= activeIndex;

      final Paint ringBgPaint = Paint()
        ..color = isCompletedOrActive
            ? const Color(0xFF27AE60)
            : const Color(0xFFBDC3C7);

      final Paint ringInnerPaint = Paint()
        ..color = isCompletedOrActive
            ? const Color(0xFFF1C40F)
            : Colors.white;

      canvas.drawCircle(pt, 16.0, ringBgPaint);
      canvas.drawCircle(pt, 10.0, ringInnerPaint);
    }
  }

  Offset _getAnchorOffset(int index, double width) {
    // Generate organic S-curve coordinates
    final double cardWidth = 130.0;
    final double padding = 28.0;
    final double usableW = width - (padding * 2) - cardWidth;
    
    // Alternating left/right swing using sine wave offset
    final double factor = (index % 4 == 0)
        ? 0.5
        : (index % 4 == 1)
            ? 0.88
            : (index % 4 == 2)
                ? 0.5
                : 0.12;

    final double x = padding + (usableW * factor) + (cardWidth / 2);
    final double y = topPadding + (index * verticalSpacing) + 80.0;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant JourneyPathPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.totalCount != totalCount ||
        oldDelegate.verticalSpacing != verticalSpacing ||
        oldDelegate.topPadding != topPadding;
  }
}
