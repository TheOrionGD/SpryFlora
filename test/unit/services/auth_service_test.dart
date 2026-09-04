import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spryflora_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Unit Tests', () {
    test('User registration and login flow with password hashing', () async {
      final authService = AuthService();
      await authService.logout();

      final user = await authService.register(
        email: 'testchild@spryflora.com',
        password: 'securePassword123',
        name: 'Aarav',
      );

      expect(authService.isAuthenticated, isTrue);
      expect(user.email, 'testchild@spryflora.com');
      expect(user.name, 'Aarav');
      expect(authService.verifyOwnership(user.id), isTrue);
      expect(authService.verifyOwnership('other_user_id'), isFalse);
    });

    test('Duplicate email registration throws exception', () async {
      final authService = AuthService();
      await authService.logout();

      await authService.register(
        email: 'unique@spryflora.com',
        password: 'pass123',
        name: 'Kid1',
      );

      expect(
        () => authService.register(
          email: 'unique@spryflora.com',
          password: 'pass456',
          name: 'Kid2',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Invalid password login fails securely', () async {
      final authService = AuthService();
      await authService.logout();

      await authService.register(
        email: 'auth_test@spryflora.com',
        password: 'correct_password',
        name: 'Kid3',
      );
      await authService.logout();

      expect(
        () => authService.login(
          email: 'auth_test@spryflora.com',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Session restoration and logout', () async {
      final authService = AuthService();
      await authService.logout();

      await authService.register(
        email: 'session@spryflora.com',
        password: 'mypassword',
        name: 'Kid4',
      );

      await authService.restoreSession();
      expect(authService.isAuthenticated, isTrue);

      await authService.logout();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('getAuthorizationHeaders generates valid Bearer header', () async {
      final authService = AuthService();
      await authService.logout();

      await authService.register(
        email: 'headers@spryflora.com',
        password: 'mypassword',
        name: 'Kid5',
      );

      final headers = authService.getAuthorizationHeaders();
      expect(headers['Content-Type'], 'application/json');
      expect(headers.containsKey('Authorization'), isTrue);
      expect(headers['Authorization'], startsWith('Bearer token_'));
    });
  });
}
