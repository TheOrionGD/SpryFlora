import 'package:flutter/material.dart';

/// The 4 Botanical Garden Seasons
enum GardenSeason {
  spring,
  summer,
  autumn,
  winter;

  String get displayName {
    switch (this) {
      case GardenSeason.spring:
        return 'Spring';
      case GardenSeason.summer:
        return 'Summer';
      case GardenSeason.autumn:
        return 'Autumn';
      case GardenSeason.winter:
        return 'Winter';
    }
  }

  String get emoji {
    switch (this) {
      case GardenSeason.spring:
        return '🌸';
      case GardenSeason.summer:
        return '☀️';
      case GardenSeason.autumn:
        return '🍂';
      case GardenSeason.winter:
        return '❄️';
    }
  }

  String get tagLine {
    switch (this) {
      case GardenSeason.spring:
        return 'Fresh blooms & tender green shoots';
      case GardenSeason.summer:
        return 'Lush sunlit canopy & golden warmth';
      case GardenSeason.autumn:
        return 'Terracotta foliage & crisp amber breeze';
      case GardenSeason.winter:
        return 'Serene frost, evergreen pines & quiet rest';
    }
  }

  /// Automatically derives current botanical season from calendar date
  static GardenSeason currentForDate(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) {
      return GardenSeason.spring;
    } else if (month >= 6 && month <= 8) {
      return GardenSeason.summer;
    } else if (month >= 9 && month <= 11) {
      return GardenSeason.autumn;
    } else {
      return GardenSeason.winter;
    }
  }

  /// Sky Gradient Colors
  List<Color> get skyGradient {
    switch (this) {
      case GardenSeason.spring:
        return const [
          Color(0xFFCEEBD9),
          Color(0xFFE4F6E9),
          Color(0xFFF2FBF4),
        ];
      case GardenSeason.summer:
        return const [
          Color(0xFF98D8AA),
          Color(0xFFBFE7C4),
          Color(0xFFE3F7D9),
        ];
      case GardenSeason.autumn:
        // Soft sage green into warm amber/olive — exactly matches the reference image
        return const [
          Color(0xFF9CB8A0),
          Color(0xFFB9CCA8),
          Color(0xFFCFDCBF),
        ];
      case GardenSeason.winter:
        return const [
          Color(0xFFADC8CC),
          Color(0xFFC7DEE2),
          Color(0xFFE4F1F4),
        ];
    }
  }

  /// Island Surface Grass Gradient
  List<Color> get islandSurfaceColors {
    switch (this) {
      case GardenSeason.spring:
        return const [Color(0xFFBCE3C5), Color(0xFFA5D6AF)];
      case GardenSeason.summer:
        return const [Color(0xFFA8DE9C), Color(0xFF8CCF80)];
      case GardenSeason.autumn:
        // Minty sage top surface from reference image
        return const [Color(0xFFC2D9C5), Color(0xFFA8C4AC)];
      case GardenSeason.winter:
        return const [Color(0xFFD3E7DE), Color(0xFFB9D6CB)];
    }
  }

  /// Island Bevel Rim Color (middle depth tier)
  Color get islandBevelColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF85C294);
      case GardenSeason.summer:
        return const Color(0xFF6EBE60);
      case GardenSeason.autumn:
        return const Color(0xFF7FA387);
      case GardenSeason.winter:
        return const Color(0xFF90B5A8);
    }
  }

  /// Island Soil Base Color (bottom depth tier)
  Color get islandSoilColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF4A7D58);
      case GardenSeason.summer:
        return const Color(0xFF3F7034);
      case GardenSeason.autumn:
        // Deep moss forest base from reference image
        return const Color(0xFF48634F);
      case GardenSeason.winter:
        return const Color(0xFF4E6B6E);
    }
  }

  /// Island Grid Line Color
  Color get islandGridLineColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF99CCA4).withValues(alpha: 0.4);
      case GardenSeason.summer:
        return const Color(0xFF7CB870).withValues(alpha: 0.4);
      case GardenSeason.autumn:
        return const Color(0xFF92B297).withValues(alpha: 0.35);
      case GardenSeason.winter:
        return const Color(0xFFA5C5B9).withValues(alpha: 0.4);
    }
  }

  /// Primary foliage tone for deciduous trees
  Color get primaryCanopyColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF81C784);
      case GardenSeason.summer:
        return const Color(0xFF4CAF50);
      case GardenSeason.autumn:
        // Warm orange terracotta from reference image
        return const Color(0xFFE27D44);
      case GardenSeason.winter:
        return const Color(0xFF6B9B8A);
    }
  }

  /// Secondary foliage tone
  Color get secondaryCanopyColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFFAED581);
      case GardenSeason.summer:
        return const Color(0xFF66BB6A);
      case GardenSeason.autumn:
        return const Color(0xFFEE9E42);
      case GardenSeason.winter:
        return const Color(0xFF88AFA0);
    }
  }

  /// Evergreen Pine Tone
  Color get pineColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF388E3C);
      case GardenSeason.summer:
        return const Color(0xFF2E7D32);
      case GardenSeason.autumn:
        return const Color(0xFF3B6E4A);
      case GardenSeason.winter:
        return const Color(0xFF41645B);
    }
  }

  /// Cactus / Succulent Tone
  Color get cactusColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFF66BB6A);
      case GardenSeason.summer:
        return const Color(0xFF43A047);
      case GardenSeason.autumn:
        return const Color(0xFF6CA378);
      case GardenSeason.winter:
        return const Color(0xFF7FA396);
    }
  }

  /// Particle Color Tint
  Color get particleColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFFFFB7B2); // Cherry petal pink
      case GardenSeason.summer:
        return const Color(0xFFFFE082); // Golden sunbeams
      case GardenSeason.autumn:
        return const Color(0xFFE67E22); // Amber autumn leaves
      case GardenSeason.winter:
        return const Color(0xFFE0F7FA); // Ice crystal / snow
    }
  }
}
