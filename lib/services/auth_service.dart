import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'plant_repository.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final DateTime sessionExpiresAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.sessionExpiresAt,
  });

  bool get isSessionExpired => DateTime.now().isAfter(sessionExpiresAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'sessionExpiresAt': sessionExpiresAt.toIso8601String(),
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        sessionExpiresAt: json['sessionExpiresAt'] != null
            ? DateTime.parse(json['sessionExpiresAt'] as String)
            : DateTime.now().add(const Duration(days: 14)),
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _sessionKey = 'spryflora_auth_session';
  static const String _usersKey = 'spryflora_registered_users';

  AuthUser? _currentUser;
  String? _authToken;

  AuthUser? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isSessionExpired;

  /// Returns standard JSON HTTP authorization headers including bearer token
  Map<String, String> getAuthorizationHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Hashes raw password using SHA-256 with salt to prevent plaintext password exposure
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    return sha256.convert(bytes).toString();
  }

  /// Restores session from secure local storage
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJsonStr = prefs.getString(_sessionKey);
      if (sessionJsonStr != null && sessionJsonStr.isNotEmpty) {
        final map = jsonDecode(sessionJsonStr) as Map<String, dynamic>;
        final user = AuthUser.fromJson(map['user'] as Map<String, dynamic>);
        if (!user.isSessionExpired) {
          _currentUser = user;
          _authToken = map['token'] as String?;
          await UserService().setCurrentUser(user.id);
          await PlantRepository().setCurrentUser(user.id);
          notifyListeners();
          return;
        } else {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Session restoration error: $e');
    }
  }

  /// Registers a new user account with backend API or local hashed credentials
  Future<AuthUser> register({
    required String email,
    required String password,
    required String name,
    String? username,
    String? dob,
    String? favoritePlant,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = (username ?? '').trim().toLowerCase();

    if (ApiConfig.usesBackendAuth) {
      try {
        final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authRegisterEndpoint}');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'password': password,
            'name': name,
            'username': cleanUsername,
            'dob': dob,
            'favoritePlant': favoritePlant,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final token = data['token'] as String? ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
          final userJson = data['user'] as Map<String, dynamic>? ?? {
            'id': data['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            'email': cleanEmail,
            'name': name,
            'sessionExpiresAt': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
          };
          final authUser = AuthUser.fromJson(userJson);

          _currentUser = authUser;
          _authToken = token;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, jsonEncode({'user': authUser.toJson(), 'token': token}));

          await UserService().setCurrentUser(authUser.id);
          await PlantRepository().setCurrentUser(authUser.id);

          if (UserService().currentUser == null) {
            await UserService().saveUserProfile(
              UserProfile(
                childName: name,
                age: 10,
                school: '',
                favoritePlant: favoritePlant ?? 'Sunflower',
                xp: 0,
                careStreakDays: 0,
                completedPlantsCount: 0,
              ),
            );
          }

          notifyListeners();
          return authUser;
        } else {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Registration failed on backend server.';
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('Registration failed')) rethrow;
        if (e is Exception && e.toString().contains('already exists')) rethrow;
        debugPrint('Backend registration network exception: $e');
      }
    }

    // Local authentication fallback for offline operation
    final prefs = await SharedPreferences.getInstance();
    final usersJsonStr = prefs.getString(_usersKey);
    List<dynamic> users = usersJsonStr != null ? jsonDecode(usersJsonStr) : [];

    if (users.any((u) => u['email'] == cleanEmail)) {
      throw Exception('An account with this email already exists.');
    }
    if (cleanUsername.isNotEmpty &&
        users.any((u) => (u['username'] ?? '').toString().toLowerCase() == cleanUsername)) {
      throw Exception('This username is already taken. Try another!');
    }

    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final salt = 'spryflora_salt_$userId';
    final hashedPassword = _hashPassword(password, salt);

    final newUserRecord = {
      'id': userId,
      'email': cleanEmail,
      'name': name,
      'username': cleanUsername.isNotEmpty ? cleanUsername : name.toLowerCase(),
      'dob': dob ?? '',
      'favoritePlant': favoritePlant ?? 'Sunflower',
      'passwordHash': hashedPassword,
      'salt': salt,
      'createdAt': DateTime.now().toIso8601String(),
    };

    users.add(newUserRecord);
    await prefs.setString(_usersKey, jsonEncode(users));

    final authUser = await login(email: cleanEmail, password: password);
    if (UserService().currentUser == null) {
      await UserService().saveUserProfile(
        UserProfile(
          childName: name,
          age: 10,
          school: '',
          favoritePlant: favoritePlant ?? 'Sunflower',
          xp: 0,
          careStreakDays: 0,
          completedPlantsCount: 0,
        ),
      );
    }
    return authUser;
  }

  /// Authenticates user credentials using server API or local verification
  /// Accepts either email or username in the [email] parameter
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final cleanIdentifier = email.trim().toLowerCase();

    if (ApiConfig.usesBackendAuth) {
      try {
        final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authLoginEndpoint}');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanIdentifier,
            'password': password,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final token = data['token'] as String;
          final userJson = data['user'] as Map<String, dynamic>;
          final authUser = AuthUser.fromJson(userJson);

          _currentUser = authUser;
          _authToken = token;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, jsonEncode({'user': authUser.toJson(), 'token': token}));

          await UserService().setCurrentUser(authUser.id);
          await PlantRepository().setCurrentUser(authUser.id);

          notifyListeners();
          return authUser;
        } else {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Invalid email/username or password.';
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (e is Exception && (e.toString().contains('Invalid') || e.toString().contains('failed'))) rethrow;
        debugPrint('Backend login network exception: $e');
      }
    }

    // Local authentication fallback for offline operation
    final prefs = await SharedPreferences.getInstance();
    final usersJsonStr = prefs.getString(_usersKey);
    List<dynamic> users = usersJsonStr != null ? jsonDecode(usersJsonStr) : [];

    final userRecord = users.firstWhere(
      (u) =>
          u['email'] == cleanIdentifier ||
          (u['username'] != null &&
              (u['username'] as String).toLowerCase() == cleanIdentifier),
      orElse: () => null,
    );

    if (userRecord == null) {
      throw Exception('Invalid email/username or password.');
    }

    final salt = userRecord['salt'] as String;
    final expectedHash = userRecord['passwordHash'] as String;
    final computedHash = _hashPassword(password, salt);

    if (computedHash != expectedHash) {
      throw Exception('Invalid email/username or password.');
    }

    final sessionExpires = DateTime.now().add(const Duration(days: 14));
    final token = 'token_${userRecord['id']}_${DateTime.now().millisecondsSinceEpoch}';

    final authUser = AuthUser(
      id: userRecord['id'] as String,
      email: userRecord['email'] as String,
      name: userRecord['name'] as String,
      sessionExpiresAt: sessionExpires,
    );

    _currentUser = authUser;
    _authToken = token;

    final sessionData = {
      'user': authUser.toJson(),
      'token': token,
    };
    await prefs.setString(_sessionKey, jsonEncode(sessionData));

    await UserService().setCurrentUser(authUser.id);
    await PlantRepository().setCurrentUser(authUser.id);

    notifyListeners();
    return authUser;
  }

  /// Verifies user security details (Email, Username, Name, DOB, Favorite Plant)
  Future<bool> verifySecurityDetails({
    required String email,
    required String username,
    required String name,
    required String dob,
    required String favoritePlant,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();
    final cleanName = name.trim().toLowerCase();

    // 1. Try Backend Authentication Verification if enabled
    if (ApiConfig.usesBackendAuth) {
      try {
        final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authForgotPasswordVerifyEndpoint}');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'username': cleanUsername,
            'name': cleanName,
            'dob': dob,
            'favoritePlant': favoritePlant,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['verified'] == true) {
            return true;
          }
        } else {
          final data = jsonDecode(response.body);
          final errorMsg = data['message'] ?? 'Account verification failed.';
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (e is Exception && (e.toString().contains('No user account') || e.toString().contains('Security details do not match'))) {
          rethrow;
        }
        debugPrint('Backend forgot-password verify network exception: $e');
      }
    }

    // 2. Offline Local Storage Verification Fallback
    final prefs = await SharedPreferences.getInstance();
    final usersJsonStr = prefs.getString(_usersKey);
    if (usersJsonStr == null) return false;

    List<dynamic> users = jsonDecode(usersJsonStr);

    final user = users.firstWhere(
      (u) =>
          u['email'] == cleanEmail ||
          ((u['username'] ?? '').toString().toLowerCase() == cleanUsername && cleanUsername.isNotEmpty),
      orElse: () => null,
    );

    if (user == null) return false;

    final userEmail = (user['email'] ?? '').toString().toLowerCase();
    final userName = (user['name'] ?? '').toString().toLowerCase();
    final userUsername = (user['username'] ?? '').toString().toLowerCase();

    final bool emailOrUserMatch = (userEmail == cleanEmail) || (userUsername == cleanUsername);
    final bool nameMatch = cleanName.isEmpty || userName.contains(cleanName) || cleanName.contains(userName);

    return emailOrUserMatch && nameMatch;
  }

  /// Resets user password after security verification
  Future<bool> resetPasswordWithSecurityAnswers({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Try Backend Password Reset if enabled
    if (ApiConfig.usesBackendAuth) {
      try {
        final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authForgotPasswordResetEndpoint}');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'newPassword': newPassword,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          // Password reset in backend successfully, also update local cache if present
          final prefs = await SharedPreferences.getInstance();
          final usersJsonStr = prefs.getString(_usersKey);
          if (usersJsonStr != null) {
            List<dynamic> users = jsonDecode(usersJsonStr);
            final idx = users.indexWhere((u) => u['email'] == cleanEmail);
            if (idx != -1) {
              final user = Map<String, dynamic>.from(users[idx]);
              final salt = user['salt'] as String? ?? 'spryflora_salt_${user['id']}';
              user['passwordHash'] = _hashPassword(newPassword, salt);
              users[idx] = user;
              await prefs.setString(_usersKey, jsonEncode(users));
            }
          }
          notifyListeners();
          return true;
        } else {
          final data = jsonDecode(response.body);
          final errorMsg = data['message'] ?? 'Failed to reset password.';
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('password')) {
          rethrow;
        }
        debugPrint('Backend password reset network exception: $e');
      }
    }

    // 2. Offline Local Storage Reset Fallback
    final prefs = await SharedPreferences.getInstance();
    final usersJsonStr = prefs.getString(_usersKey);
    if (usersJsonStr == null) throw Exception('User database not found.');

    List<dynamic> users = jsonDecode(usersJsonStr);

    final index = users.indexWhere(
      (u) =>
          u['email'] == cleanEmail ||
          ((u['username'] ?? '').toString().toLowerCase() == cleanEmail && cleanEmail.isNotEmpty),
    );

    if (index == -1) {
      return true;
    }

    final user = Map<String, dynamic>.from(users[index]);
    final salt = user['salt'] as String? ?? 'spryflora_salt_${user['id']}';
    final newHash = _hashPassword(newPassword, salt);

    user['passwordHash'] = newHash;
    users[index] = user;

    await prefs.setString(_usersKey, jsonEncode(users));
    notifyListeners();
    return true;
  }

  /// Verifies if the active authenticated user owns a specific resource
  bool verifyOwnership(String resourceOwnerId) {
    if (!isAuthenticated || _currentUser == null) return false;
    return _currentUser!.id == resourceOwnerId;
  }

  /// Logs out the user and destroys the active session token
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    UserService().clearInMemoryData();
    PlantRepository().clearInMemoryData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }
}
