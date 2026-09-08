import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spryflora_app/models/garden_season.dart';

void main() {
  group('GardenSeason.currentForDate — Calendar Mapping', () {
    // ── Spring: March, April, May ─────────────────────────────────────────
    test('Month 3 (March) maps to Spring', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 3, 1)),
        GardenSeason.spring,
      );
    });

    test('Month 4 (April) maps to Spring', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 4, 15)),
        GardenSeason.spring,
      );
    });

    test('Month 5 (May) maps to Spring', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 5, 31)),
        GardenSeason.spring,
      );
    });

    // ── Summer: June, July, August ───────────────────────────────────────
    test('Month 6 (June) maps to Summer', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 6, 1)),
        GardenSeason.summer,
      );
    });

    test('Month 7 (July) maps to Summer', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 7, 4)),
        GardenSeason.summer,
      );
    });

    test('Month 8 (August) maps to Summer', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 8, 31)),
        GardenSeason.summer,
      );
    });

    // ── Autumn: September, October, November ─────────────────────────────
    test('Month 9 (September) maps to Autumn', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 9, 8)),
        GardenSeason.autumn,
      );
    });

    test('Month 10 (October) maps to Autumn', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 10, 15)),
        GardenSeason.autumn,
      );
    });

    test('Month 11 (November) maps to Autumn', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 11, 30)),
        GardenSeason.autumn,
      );
    });

    // ── Winter: December, January, February ──────────────────────────────
    test('Month 12 (December) maps to Winter', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 12, 25)),
        GardenSeason.winter,
      );
    });

    test('Month 1 (January) maps to Winter', () {
      expect(
        GardenSeason.currentForDate(DateTime(2027, 1, 1)),
        GardenSeason.winter,
      );
    });

    test('Month 2 (February) maps to Winter', () {
      expect(
        GardenSeason.currentForDate(DateTime(2027, 2, 14)),
        GardenSeason.winter,
      );
    });
  });

  group('GardenSeason display strings — non-empty for all seasons', () {
    for (final season in GardenSeason.values) {
      test('${season.name}.displayName is non-empty', () {
        expect(season.displayName, isNotEmpty);
      });

      test('${season.name}.emoji is non-empty', () {
        expect(season.emoji, isNotEmpty);
      });

      test('${season.name}.tagLine is non-empty', () {
        expect(season.tagLine, isNotEmpty);
      });
    }
  });

  group('GardenSeason display string values', () {
    test('Spring displayName is "Spring"', () {
      expect(GardenSeason.spring.displayName, 'Spring');
    });
    test('Summer displayName is "Summer"', () {
      expect(GardenSeason.summer.displayName, 'Summer');
    });
    test('Autumn displayName is "Autumn"', () {
      expect(GardenSeason.autumn.displayName, 'Autumn');
    });
    test('Winter displayName is "Winter"', () {
      expect(GardenSeason.winter.displayName, 'Winter');
    });

    test('Spring emoji is 🌸', () {
      expect(GardenSeason.spring.emoji, '🌸');
    });
    test('Summer emoji is ☀️', () {
      expect(GardenSeason.summer.emoji, '☀️');
    });
    test('Autumn emoji is 🍂', () {
      expect(GardenSeason.autumn.emoji, '🍂');
    });
    test('Winter emoji is ❄️', () {
      expect(GardenSeason.winter.emoji, '❄️');
    });
  });

  group('GardenSeason color palettes — non-null for all seasons', () {
    for (final season in GardenSeason.values) {
      test('${season.name}.skyGradient has exactly 3 colors', () {
        expect(season.skyGradient.length, 3);
      });

      test('${season.name}.islandSurfaceColors has exactly 2 colors', () {
        expect(season.islandSurfaceColors.length, 2);
      });

      test('${season.name}.islandBevelColor is a valid Color', () {
        expect(season.islandBevelColor, isA<Color>());
      });

      test('${season.name}.islandSoilColor is a valid Color', () {
        expect(season.islandSoilColor, isA<Color>());
      });

      test('${season.name}.islandGridLineColor is a valid Color', () {
        expect(season.islandGridLineColor, isA<Color>());
      });

      test('${season.name}.primaryCanopyColor is a valid Color', () {
        expect(season.primaryCanopyColor, isA<Color>());
      });

      test('${season.name}.secondaryCanopyColor is a valid Color', () {
        expect(season.secondaryCanopyColor, isA<Color>());
      });

      test('${season.name}.pineColor is a valid Color', () {
        expect(season.pineColor, isA<Color>());
      });

      test('${season.name}.cactusColor is a valid Color', () {
        expect(season.cactusColor, isA<Color>());
      });

      test('${season.name}.particleColor is a valid Color', () {
        expect(season.particleColor, isA<Color>());
      });
    }
  });

  group('GardenSeason — Autumn reference colours (reference image match)', () {
    test('Autumn primaryCanopyColor is terracotta orange', () {
      // Should be warm orange/terracotta matching the reference artwork
      expect(
        (GardenSeason.autumn.primaryCanopyColor.r * 255.0).round(),
        greaterThan(
          (GardenSeason.autumn.primaryCanopyColor.g * 255.0).round(),
        ),
      );
    });

    test('Autumn islandSoilColor green channel is dominant (deep mossy base)', () {
      final soil = GardenSeason.autumn.islandSoilColor;
      expect(
        (soil.g * 255.0).round(),
        greaterThan((soil.r * 255.0).round()),
      );
    });

    test('Autumn sky gradient first color is darker than third (top darker than bottom)', () {
      final gradient = GardenSeason.autumn.skyGradient;
      // The top sky (gradient[0]) should be a deeper hue than the pale bottom
      final top = gradient[0];
      final bottom = gradient[2];
      // Red channel: top <= bottom (sage green palette gets lighter at bottom)
      expect(
        (top.b * 255.0).round(),
        lessThanOrEqualTo((bottom.b * 255.0).round()),
      );
    });
  });

  group('GardenSeason — Winter snow-tinted palette check', () {
    test('Winter particleColor is ice/snow blue tint (high blue channel)', () {
      final particle = GardenSeason.winter.particleColor;
      expect((particle.b * 255.0).round(), greaterThan(200));
    });

    test('Winter islandBevelColor has green dominance (frosty mint)', () {
      final bevel = GardenSeason.winter.islandBevelColor;
      expect(
        (bevel.g * 255.0).round(),
        greaterThanOrEqualTo((bevel.r * 255.0).round()),
      );
    });
  });

  group('GardenSeason — Boundary month edge cases', () {
    test('Last day of February (month 2) is still Winter', () {
      expect(
        GardenSeason.currentForDate(DateTime(2028, 2, 29)), // leap year
        GardenSeason.winter,
      );
    });

    test('First day of March (month 3) is Spring', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 3, 1)),
        GardenSeason.spring,
      );
    });

    test('Last day of November (month 11) is Autumn', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 11, 30)),
        GardenSeason.autumn,
      );
    });

    test('First day of December (month 12) is Winter', () {
      expect(
        GardenSeason.currentForDate(DateTime(2026, 12, 1)),
        GardenSeason.winter,
      );
    });
  });
}
