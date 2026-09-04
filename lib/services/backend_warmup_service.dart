import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum WarmupStatus {
  idle,
  warming,
  ready,
  failed,
}

class BackendWarmupService extends ChangeNotifier {
  static final BackendWarmupService _instance = BackendWarmupService._internal();
  factory BackendWarmupService() => _instance;
  BackendWarmupService._internal();

  WarmupStatus _status = WarmupStatus.idle;
  int _attemptCount = 0;
  String _message = 'Initializing Cloud Engine...';
  Timer? _pingTimer;
  int _responseTimeMs = 0;

  WarmupStatus get status => _status;
  int get attemptCount => _attemptCount;
  String get message => _message;
  bool get isWarm => _status == WarmupStatus.ready;
  int get responseTimeMs => _responseTimeMs;

  void startWarmup() {
    if (_status == WarmupStatus.warming || _status == WarmupStatus.ready) return;

    _status = WarmupStatus.warming;
    _attemptCount = 0;
    _message = 'Warming Render backend instance... ⚡';
    notifyListeners();

    // Trigger initial ping immediately
    _pingBackend();

    // Repeat ping every 3.5 seconds until success or timer stopped
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (_status == WarmupStatus.ready) {
        _pingTimer?.cancel();
      } else {
        _pingBackend();
      }
    });
  }

  Future<void> _pingBackend() async {
    _attemptCount++;
    _message = 'Contacting Render Cloud (Attempt $_attemptCount)... ⚡';
    notifyListeners();

    final rootUrl = ApiConfig.backendBaseUrl;
    final healthUrl = '${ApiConfig.backendBaseUrl}/health';
    final aiHealthUrl = '${ApiConfig.aiBackendUrl}/health';

    final startMs = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        _responseTimeMs = DateTime.now().millisecondsSinceEpoch - startMs;
        _status = WarmupStatus.ready;
        _message = 'Render Cloud Engine Online & Ready! 🟢';
        _pingTimer?.cancel();
        notifyListeners();
        debugPrint('Render backend warm-up success in $_responseTimeMs ms');
        return;
      }
    } catch (e) {
      debugPrint('Backend warmup attempt $_attemptCount failed on /health (Render sleeping): $e');
    }

    // Fallback: ping root URL
    try {
      final rootResp = await http
          .get(Uri.parse(rootUrl))
          .timeout(const Duration(seconds: 4));
      if (rootResp.statusCode >= 200 && rootResp.statusCode < 400) {
        _responseTimeMs = DateTime.now().millisecondsSinceEpoch - startMs;
        _status = WarmupStatus.ready;
        _message = 'Render Cloud Engine Online & Ready! 🟢';
        _pingTimer?.cancel();
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Try AI backend proxy if distinct
    if (ApiConfig.usesBackendProxy && ApiConfig.aiBackendUrl != ApiConfig.backendBaseUrl) {
      try {
        final aiResp = await http
            .get(Uri.parse(aiHealthUrl))
            .timeout(const Duration(seconds: 4));
        if (aiResp.statusCode == 200) {
          _responseTimeMs = DateTime.now().millisecondsSinceEpoch - startMs;
          _status = WarmupStatus.ready;
          _message = 'Render AI Gateway Ready! 🟢';
          _pingTimer?.cancel();
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  void stopWarmup() {
    _pingTimer?.cancel();
  }
}
