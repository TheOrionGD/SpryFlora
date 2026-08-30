/// Stub implementation for non-web platforms (Android, iOS, Desktop)
class CameraWebBridge {
  String? get viewId => null;
  bool get isReady => false;

  void initCamera({
    required void Function(bool ready, String? error) onStatus,
    required void Function(String viewId) onViewCreated,
  }) {
    onStatus(true, null);
  }

  Future<String?> captureFrame() async {
    return null;
  }

  void dispose() {}
}
