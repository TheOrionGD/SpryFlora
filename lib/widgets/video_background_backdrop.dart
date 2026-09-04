import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Reusable Video Background Backdrop Widget.
/// Loads and loops assets/sprites/bg.mp4 continuously in the background,
/// with a graceful nature gradient fallback if loading or unsupported.
class VideoBackgroundBackdrop extends StatefulWidget {
  final Widget? child;

  const VideoBackgroundBackdrop({
    super.key,
    this.child,
  });

  @override
  State<VideoBackgroundBackdrop> createState() =>
      _VideoBackgroundBackdropState();
}

class _VideoBackgroundBackdropState extends State<VideoBackgroundBackdrop> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/sprites/bg.mp4');
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      await _controller!.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('VideoBackgroundBackdrop notice: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized &&
            _controller != null &&
            _controller!.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B4F72),
                  Color(0xFF2E86C1),
                  Color(0xFF1E8449),
                  Color(0xFF114B27),
                ],
              ),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
