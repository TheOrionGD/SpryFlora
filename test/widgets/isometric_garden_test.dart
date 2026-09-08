import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/models/garden_season.dart';
import 'package:spryflora_app/models/plant_model.dart';
import 'package:spryflora_app/screens/virtual_garden_screen.dart';
import 'package:spryflora_app/widgets/isometric_garden_island.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PlantModel _makePlant({
  String id = 'test_plant_1',
  String name = 'Golden Orchid',
  String species = 'Orchidaceae',
  bool wateringDue = false,
}) {
  final now = DateTime.now();
  return PlantModel(
    id: id,
    plantName: name,
    speciesName: species,
    plantingDate: now.subtract(const Duration(days: 14)),
    lifespanDays: 120,
    wateringIntervalDays: 4,
    lastWateredDate:
        wateringDue ? now.subtract(const Duration(days: 5)) : now,
    nextWateringDate:
        wateringDue ? now.subtract(const Duration(days: 1)) : now.add(const Duration(days: 3)),
  );
}

/// Wraps a widget in a minimal MaterialApp with BouncingScrollPhysics.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── IsometricGardenIsland renders across all 4 seasons ──────────────────

  group('IsometricGardenIsland — renders without error for all seasons', () {
    for (final season in GardenSeason.values) {
      testWidgets('Renders with season=${season.name} and no plants',
          (tester) async {
        await tester.pumpWidget(_wrap(
          IsometricGardenIsland(
            userPlants: const [],
            season: season,
          ),
        ));
        // Allow animation frame
        await tester.pump(const Duration(milliseconds: 100));

        // Should not throw; widget tree should contain a CustomPaint
        expect(find.byType(IsometricGardenIsland), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('Renders with season=${season.name} and 3 plants',
          (tester) async {
        final plants = [
          _makePlant(id: 'p1', name: 'Rose'),
          _makePlant(id: 'p2', name: 'Cactus', wateringDue: true),
          _makePlant(id: 'p3', name: 'Fern'),
        ];

        await tester.pumpWidget(_wrap(
          IsometricGardenIsland(
            userPlants: plants,
            season: season,
          ),
        ));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(IsometricGardenIsland), findsOneWidget);
      });
    }
  });

  // ── Season badge text ────────────────────────────────────────────────────

  group('IsometricGardenIsland — season badge text', () {
    testWidgets('Shows "Autumn Sanctuary" badge for autumn season',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IsometricGardenIsland(
          userPlants: const [],
          season: GardenSeason.autumn,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Autumn Sanctuary'), findsOneWidget);
    });

    testWidgets('Shows "Spring Sanctuary" badge for spring season',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IsometricGardenIsland(
          userPlants: const [],
          season: GardenSeason.spring,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Spring Sanctuary'), findsOneWidget);
    });

    testWidgets('Shows "Summer Sanctuary" badge for summer season',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IsometricGardenIsland(
          userPlants: const [],
          season: GardenSeason.summer,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Summer Sanctuary'), findsOneWidget);
    });

    testWidgets('Shows "Winter Sanctuary" badge for winter season',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IsometricGardenIsland(
          userPlants: const [],
          season: GardenSeason.winter,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Winter Sanctuary'), findsOneWidget);
    });
  });

  // ── Animation controllers ────────────────────────────────────────────────

  testWidgets(
      'IsometricGardenIsland disposes animation controllers without error',
      (tester) async {
    await tester.pumpWidget(_wrap(
      IsometricGardenIsland(
        userPlants: const [],
        season: GardenSeason.spring,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    // Pumping with done should dispose cleanly
    await tester.pumpWidget(const SizedBox.shrink());
    // No assertion needed — the test passes if no exception is thrown
  });

  // ── VirtualGardenScreen integration — season selector chips ─────────────

  group('VirtualGardenScreen — seasonal selector chip bar', () {
    testWidgets('Season selector bar renders all 4 season chips',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Spring'), findsOneWidget);
      expect(find.text('Summer'), findsOneWidget);
      expect(find.text('Autumn'), findsOneWidget);
      expect(find.text('Winter'), findsOneWidget);
    });

    testWidgets('Tapping "Spring" chip changes island season badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap the Spring chip
      await tester.tap(find.text('Spring'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Spring Sanctuary'), findsOneWidget);
    });

    testWidgets('Tapping "Winter" chip shows Winter Sanctuary badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Winter'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Winter Sanctuary'), findsOneWidget);
    });

    testWidgets('Tapping "Summer" chip shows Summer Sanctuary badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Summer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Summer Sanctuary'), findsOneWidget);
    });
  });

  // ── VirtualGardenScreen — view mode toggle ──────────────────────────────

  group('VirtualGardenScreen — view mode toggle', () {
    testWidgets('3D Island and Plot Cards toggle buttons are present',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('🏝️ 3D Island'), findsOneWidget);
      expect(find.text('📋 Plot Cards'), findsOneWidget);
    });

    testWidgets('By default, IsometricGardenIsland is shown (3D Island mode)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // IsometricGardenIsland should be in the tree
      expect(find.byType(IsometricGardenIsland), findsOneWidget);
    });

    testWidgets('Tapping "Plot Cards" hides IsometricGardenIsland',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('📋 Plot Cards'));
      await tester.pump(const Duration(milliseconds: 300));

      // IsometricGardenIsland should no longer be rendered
      expect(find.byType(IsometricGardenIsland), findsNothing);
    });

    testWidgets('Tapping back to "3D Island" restores IsometricGardenIsland',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VirtualGardenScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to plot cards
      await tester.tap(find.text('📋 Plot Cards'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(IsometricGardenIsland), findsNothing);

      // Switch back to 3D Island
      await tester.tap(find.text('🏝️ 3D Island'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(IsometricGardenIsland), findsOneWidget);
    });
  });
}
