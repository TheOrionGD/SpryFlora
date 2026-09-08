// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web implementation for live camera streaming using HTML5 Video and Canvas
class CameraWebBridge {
  String? _viewId;
  html.VideoElement? _webVideoElement;
  html.MediaStream? _webStream;
  bool _isReady = false;
  bool _isDisposed = false;

  String? get viewId => _viewId;
  bool get isReady => _isReady && !_isDisposed;

  void initCamera({
    required void Function(bool ready, String? error) onStatus,
    required void Function(String viewId) onViewCreated,
  }) {
    _isDisposed = false;
    try {
      _viewId = 'live-webcam-${DateTime.now().millisecondsSinceEpoch}';
      _webVideoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _webVideoElement!,
      );

      onViewCreated(_viewId!);

      html.window.navigator.mediaDevices
          ?.getUserMedia({'video': true, 'audio': false}).then((stream) {
        if (_isDisposed) {
          for (final track in stream.getTracks()) {
            try {
              track.stop();
            } catch (_) {}
          }
          return;
        }
        _webStream = stream;
        _webVideoElement?.srcObject = stream;
        _isReady = true;
        onStatus(true, null);
      }).catchError((err) {
        if (!_isDisposed) {
          onStatus(false, 'Camera access denied: $err');
        }
      });
    } catch (e) {
      if (!_isDisposed) {
        onStatus(false, e.toString());
      }
    }
  }

  Future<String?> captureFrame() async {
    if (!_isReady || _isDisposed || _webVideoElement == null) return null;
    try {
      final video = _webVideoElement!;
      final int w = video.videoWidth > 0 ? video.videoWidth : 640;
      final int h = video.videoHeight > 0 ? video.videoHeight : 480;

      final canvas = html.CanvasElement(width: w, height: h);
      final ctx = canvas.context2D;
      ctx.translate(w, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(video, 0, 0);

      return canvas.toDataUrl('image/jpeg', 0.9);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _isDisposed = true;
    _isReady = false;
    if (_webStream != null) {
      for (final track in _webStream!.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
      _webStream = null;
    }
    if (_webVideoElement != null) {
      try {
        _webVideoElement!.srcObject = null;
        _webVideoElement!.pause();
        _webVideoElement!.remove();
      } catch (_) {}
      _webVideoElement = null;
    }
  }
}
