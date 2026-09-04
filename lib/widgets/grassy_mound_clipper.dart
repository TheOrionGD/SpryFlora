import 'package:flutter/material.dart';

/// CustomClipper that creates an organic, smooth grassy hill mound
/// at the bottom portion of each milestone scenic card.
class GrassyMoundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left of the hill area (approx 55% of card height)
    final startY = size.height * 0.52;

    path.moveTo(0, startY);

    // Organic double-curved hill using cubic Bézier curves
    final controlPoint1 = Offset(size.width * 0.28, size.height * 0.42);
    final controlPoint2 = Offset(size.width * 0.68, size.height * 0.58);
    final endPoint = Offset(size.width, size.height * 0.48);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    // Complete the bottom rectangle shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
