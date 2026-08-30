import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spryflora_app/widgets/skeuo_button.dart';
import 'package:spryflora_app/widgets/skeuo_card.dart';
import 'package:spryflora_app/widgets/skeuo_text_field.dart';
import 'package:spryflora_app/widgets/skeuo_status_badge.dart';
import 'package:spryflora_app/widgets/skeuo_segmented_control.dart';
import 'package:spryflora_app/widgets/fun_bouncy_button.dart';
import 'package:spryflora_app/widgets/bottom_nav_bar.dart';

void main() {
  group('Skeuomorphic & Custom Components Widget Tests', () {
    testWidgets('SkeuoButton triggers onPressed callback on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuoButton(
              text: 'Save Plant',
              icon: Icons.check,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Plant'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(SkeuoButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('SkeuoButton shows loading spinner and disables click when isLoading is true', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuoButton(
              text: 'Save Plant',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Plant'), findsNothing);

      await tester.tap(find.byType(SkeuoButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('SkeuoCard renders content and handles tap if provided', (tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuoCard(
              onTap: () => cardTapped = true,
              child: const Text('Plant Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Plant Card Content'), findsOneWidget);
      await tester.tap(find.text('Plant Card Content'));
      await tester.pumpAndSettle();

      expect(cardTapped, isTrue);
    });

    testWidgets('SkeuoTextField allows user text entry via controller', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuoTextField(
              controller: controller,
              hintText: 'Enter Plant Name',
              prefixIcon: Icons.local_florist,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_florist), findsOneWidget);
      
      await tester.enterText(find.byType(TextFormField), 'Fiddle Leaf Fig');
      await tester.pump();

      expect(controller.text, 'Fiddle Leaf Fig');
    });

    testWidgets('SkeuoStatusBadge displays label and icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeuoStatusBadge(
              label: 'Thriving • 15 Days',
              icon: Icons.eco,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Thriving • 15 Days'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('SkeuoSegmentedControl toggles between YES and NO', (tester) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SkeuoSegmentedControl(
                  value: selectedValue,
                  onChanged: (val) => setState(() => selectedValue = val),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('YES'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);

      // Tap YES
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      expect(selectedValue, isTrue);

      // Tap NO
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();
      expect(selectedValue, isFalse);
    });

    testWidgets('FunBouncyButton triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FunBouncyButton(
              text: 'Bouncy Action',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Bouncy Action'), findsOneWidget);
      await tester.tap(find.text('Bouncy Action'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('BottomNavBar renders navigation items and notifies index on tap', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: BottomNavBar(
                  currentIndex: selectedTab,
                  onTap: (index) => setState(() => selectedTab = index),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Plants'), findsOneWidget);
      expect(find.text('Garden'), findsOneWidget);

      // Tap on Garden tab (index 3)
      await tester.tap(find.text('Garden'));
      await tester.pumpAndSettle();

      expect(selectedTab, 3);
    });
  });
}
