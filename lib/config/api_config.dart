/// Centralized Application API Configuration
/// Automatically configured with active credentials and model endpoints.
class ApiConfig {
  // Configurable environment API credential (fallback to empty string for offline mode)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Validated working high-performance models
  static const String primaryModel = 'gemini-flash-lite-latest';
  static const String secondaryModel = 'gemini-3.5-flash';

  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
}
