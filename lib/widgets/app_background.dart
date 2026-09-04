import 'package:flutter/material.dart';

/// Centralized SpryFlora App Background Wrapper
/// Features assets/sprites/pg.png backdrop image layered over
/// linear-gradient(180deg, #D8EEF8 0%, #F6F7EB 45%, #FCFBF4 100%)
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  static const LinearGradient defaultGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
    colors: [
      Color(0xFFD8EEF8),
      Color(0xFFF6F7EB),
      Color(0xFFFCFBF4),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fallback Gradient (180deg: #d8eef8 0%, #f6f7eb 45%, #fcfbf4 100%)
        Container(
          decoration: const BoxDecoration(
            gradient: defaultGradient,
          ),
        ),

        // 2. Primary Page Background Asset (assets/sprites/pg.png)
        Image.asset(
          'assets/sprites/pg.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),

        // 3. Screen Body Content
        child,
      ],
    );
  }
}
