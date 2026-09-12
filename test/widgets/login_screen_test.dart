import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all title, text fields and login button elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Login to continue your plant adventure!'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Shows validation errors when email or password is cleared and login is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Clear both text fields
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '');
      await tester.enterText(textFields.at(1), '');
      await tester.pump();

      // Tap Login button
      await tester.tap(find.text('Sign In'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Enter your email or username'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('Toggles password visibility when eye icon is clicked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
