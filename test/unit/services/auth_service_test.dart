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

    test('User registration with username and login with username or email', () async {
      final authService = AuthService();
      await authService.logout();

      final registered = await authService.register(
        email: 'littlegreen@spryflora.com',
        password: 'SproutPassword456',
        name: 'Little Green Sprout',
        username: 'green_sprout',
        dob: '2016-05-12',
        favoritePlant: 'Monstera',
      );

      expect(registered.email, 'littlegreen@spryflora.com');
      await authService.logout();
      expect(authService.isAuthenticated, isFalse);

      // Login using username
      final loginWithUsername = await authService.login(
        email: 'green_sprout',
        password: 'SproutPassword456',
      );
      expect(loginWithUsername.email, 'littlegreen@spryflora.com');
      expect(authService.isAuthenticated, isTrue);

      await authService.logout();

      // Login using email
      final loginWithEmail = await authService.login(
        email: 'littlegreen@spryflora.com',
        password: 'SproutPassword456',
      );
      expect(loginWithEmail.name, 'Little Green Sprout');
      expect(authService.isAuthenticated, isTrue);
    });

    test('User data is preserved in local database across simulated app restarts', () async {
      final authService = AuthService();
      await authService.logout();

      await authService.register(
        email: 'persisted@spryflora.com',
        password: 'PersistentPassword99',
        name: 'Persisted Gardener',
        username: 'persisted_user',
      );

      // Simulate app kill & reopen with stored session
      final newAuthInstance = AuthService();
      await newAuthInstance.restoreSession();
      expect(newAuthInstance.isAuthenticated, isTrue);
      expect(newAuthInstance.currentUser?.email, 'persisted@spryflora.com');

      // Logout and re-login using username
      await newAuthInstance.logout();
      expect(newAuthInstance.isAuthenticated, isFalse);

      final loggedIn = await newAuthInstance.login(
        email: 'persisted_user',
        password: 'PersistentPassword99',
      );
      expect(loggedIn.email, 'persisted@spryflora.com');
    });

    test('Auto-login automatically restores existing user on app restart without re-login', () async {
      final authService = AuthService();
      await authService.logout();

      // User creates an account and uses the app
      await authService.register(
        username: 'autologin_user',
        password: 'AutoPassword123',
        name: 'Auto Login Hero',
        favoritePlant: 'Rose',
      );

      expect(authService.isAuthenticated, isTrue);

      // Simulate app closure (creating a fresh auth session instance and restoring)
      final restoredService = AuthService();
      await restoredService.restoreSession();

      expect(restoredService.isAuthenticated, isTrue);
      expect(restoredService.currentUser?.name, 'Auto Login Hero');
    });

    test('Auto-login recovers existing user profile when session key was empty', () async {
      final authService = AuthService();
      await authService.logout();

      // Register user
      await authService.register(
        username: 'recovered_user',
        password: 'Password999',
        name: 'Recovered Explorer',
      );

      // Simulate session string cleared but user data preserved in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('spryflora_auth_session');
      await prefs.setBool('spryflora_explicit_logout', false);

      final freshService = AuthService();
      await freshService.restoreSession();

      expect(freshService.isAuthenticated, isTrue);
      expect(freshService.currentUser?.name, 'Recovered Explorer');
    });
  });
}
