import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/skeuo_theme.dart';
import 'app_photo_view.dart';
import 'camera_web_bridge.dart';
import 'skeuo_icon_button.dart';

/// Full Screen Real-Time Live Camera View
/// - Streams live webcam video in Flutter Web.
/// - Provides real-time camera viewfinder, reticle brackets, shutter animations,
///   instant photo preview, retake/confirm flow, and permanent local storage on Desktop & Mobile.
class SkeuoLiveCameraScreen extends StatefulWidget {
  final String title;
  final String prefix;

  const SkeuoLiveCameraScreen({
    super.key,
    this.title = 'Live Botanical Camera',
    this.prefix = 'photo',
  });

  @override
  State<SkeuoLiveCameraScreen> createState() => _SkeuoLiveCameraScreenState();
}

class _SkeuoLiveCameraScreenState extends State<SkeuoLiveCameraScreen>
    with SingleTickerProviderStateMixin {
  final CameraWebBridge _bridge = CameraWebBridge();
  final ImageService _imageService = ImageService();

  String? _viewId;
  bool _isCameraReady = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCapturing = false;
  String? _capturedPhotoPath;

  late AnimationController _reticleCtrl;

  @override
  void initState() {
    super.initState();
    _reticleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeLiveCamera();
  }

  void _initializeLiveCamera() {
    if (kIsWeb) {
      _bridge.initCamera(
        onViewCreated: (id) {
          if (mounted) setState(() => _viewId = id);
        },
        onStatus: (ready, error) {
          if (!mounted) return;
          if (ready) {
            setState(() {
              _isCameraReady = true;
              _hasError = false;
            });
          } else {
            setState(() {
              _hasError = true;
              _errorMessage = error ?? 'Camera error';
            });
          }
        },
      );
    } else {
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  void dispose() {
    _reticleCtrl.dispose();
    _bridge.dispose();
    super.dispose();
  }

  Future<void> _captureFrame() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      if (kIsWeb) {
        final dataUrl = await _bridge.captureFrame();
        if (mounted && dataUrl != null) {
          setState(() {
            _capturedPhotoPath = dataUrl;
          });
        }
      } else {
        final photoPath = await _imageService.captureFromCamera(
          prefix: widget.prefix,
        );
        if (mounted && photoPath != null) {
          setState(() {
            _capturedPhotoPath = photoPath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera capture error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final photoPath = await _imageService.pickFromGallery(
        prefix: widget.prefix,
      );
      if (mounted && photoPath != null) {
        setState(() {
          _capturedPhotoPath = photoPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _confirmPhoto() {
    if (_capturedPhotoPath != null) {
      Navigator.of(context).pop(_capturedPhotoPath);
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhotoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111E13),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SkeuoIconButton(
                    icon: Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.15),
                    iconColor: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _capturedPhotoPath != null
                          ? SkeuoTheme.primaryGreen
                          : const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _capturedPhotoPath != null
                              ? Icons.check_circle_rounded
                              : Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _capturedPhotoPath != null ? 'CAPTURED' : 'LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Viewport & Reticle Viewfinder
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _capturedPhotoPath != null
                        ? SkeuoTheme.primaryGreen
                        : Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // If photo is already captured, render the instant preview
                      if (_capturedPhotoPath != null)
                        AppPhotoView(
                          imagePath: _capturedPhotoPath,
                          fit: BoxFit.cover,
                          fallback: const Center(
                            child: Icon(Icons.eco_rounded,
                                size: 64, color: SkeuoTheme.primaryGreen),
                          ),
                        )
                      else if (_hasError)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_off_rounded,
                                    size: 48, color: Colors.white70),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!_isCameraReady)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: SkeuoTheme.primaryGreen),
                              SizedBox(height: 16),
                              Text(
                                'Connecting to live camera...',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else if (kIsWeb && _viewId != null)
                        HtmlElementView(viewType: _viewId!)
                      else
                        // Native Camera Viewfinder Placeholder
                        Container(
                          color: const Color(0xFF1B2E1E),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 56,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Ready to Snap Plant Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap the shutter button below to capture',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Animated Reticle Target Overlay
                      if (_capturedPhotoPath == null)
                        AnimatedBuilder(
                          animation: _reticleCtrl,
                          builder: (context, child) {
                            return Center(
                              child: Container(
                                width: 240 + (_reticleCtrl.value * 8),
                                height: 240 + (_reticleCtrl.value * 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                        alpha: 0.3 + (_reticleCtrl.value * 0.3)),
                                    width: 1.8,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Stack(
                                  children: [
                                    // Corner indicators
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.white, width: 3),
                                            left: BorderSide(
                                                color: Colors.white, width: 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.white, width: 3),
                                            right: BorderSide(
                                                color: Colors.white, width: 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                                color: Colors.white, width: 3),
                                            left: BorderSide(
                                                color: Colors.white, width: 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                                color: Colors.white, width: 3),
                                            right: BorderSide(
                                                color: Colors.white, width: 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Plant Framing Guidance Overlay
                      if (_capturedPhotoPath == null)
                        Positioned(
                          top: 16,
                          left: 20,
                          right: 20,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: SkeuoTheme.primaryGreen.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🌱 ', style: TextStyle(fontSize: 13)),
                                  Text(
                                    'Align plant leaves, seedlings, or stem inside frame',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: _capturedPhotoPath != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Retake Button
                        GestureDetector(
                          onTap: _retakePhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Retake',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Confirm / Use Photo Button
                        GestureDetector(
                          onTap: _confirmPhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: SkeuoTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: SkeuoTheme.primaryGreen
                                      .withValues(alpha: 0.5),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_rounded,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Use Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Picker Option
                        GestureDetector(
                          onTap: _isCapturing ? null : _pickFromGallery,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Shutter Button
                        GestureDetector(
                          onTap: _isCapturing ? null : _captureFrame,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isCapturing
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                SkeuoTheme.primaryGreen),
                                      ),
                                    )
                                  : Container(
                                      width: 58,
                                      height: 58,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      child: const Icon(
                                        Icons.camera_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Quick Flip / Tip Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: Colors.white60,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
