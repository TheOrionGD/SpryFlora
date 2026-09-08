import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/screens/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RegisterScreen renders username, nickname, DOB, age, favorite plant, and password fields without email', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Form header
    expect(find.text('Join SpryFlora! 🌱'), findsOneWidget);

    // Fields present: Username, Nickname, Date of Birth, Age, Favorite Plant, Password, Confirm Password
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Nickname / Child Name'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Favorite Plant'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    // Email field must NOT be present
    expect(find.text('Email Address'), findsNothing);

    // Submit Button
    expect(find.text('Create My Account 🌿'), findsOneWidget);
  });
}
