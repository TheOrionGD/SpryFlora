import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../widgets/camera_web_bridge.dart';
import '../widgets/cloud_transition.dart';
import 'daily_checkin_screen.dart';

/// Screen for Real-Time Plant Watering Recognition
/// - Renders live camera feed across Web, Mobile & Desktop.
/// - Continuously analyzes viewfinder frames in real-time.
/// - Automatically captures when that SAME plant AND a water mug/watering can are in the frame.
/// - Transitions automatically to Daily Check-in with the verified watering proof.
class RealtimeWateringScannerScreen extends StatefulWidget {
  final PlantModel plant;

  const RealtimeWateringScannerScreen({
    super.key,
    required this.plant,
  });

  @override
  State<RealtimeWateringScannerScreen> createState() =>
      _RealtimeWateringScannerScreenState();
}

class _RealtimeWateringScannerScreenState
    extends State<RealtimeWateringScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final CameraWebBridge _webBridge = CameraWebBridge();

  late AnimationController _scannerAnimCtrl;
  late Animation<double> _laserPosition;

  bool _isCameraReady = false;
  bool _isAnalyzingFrame = false;
  bool _isLockedOn = false;

  bool _isPlantInFrame = false;
  bool _isWaterMugInFrame = false;

  String _hudStatus = 'Point camera at your plant and water mug 💧';
  String _hudDetail = 'AI real-time hydration scanning active';
  int _scanTicks = 0;
  Timer? _analysisLoopTimer;

  @override
  void initState() {
    super.initState();
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserPosition = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _scannerAnimCtrl, curve: Curves.easeInOut),
    );

    _initScanner();
  }

  Future<void> _initScanner() async {
    if (kIsWeb) {
      _webBridge.initCamera(
        onViewCreated: (_) {
          if (mounted) setState(() => _isCameraReady = true);
        },
        onStatus: (ready, _) {
          if (mounted) setState(() => _isCameraReady = ready);
        },
      );
    } else {
      try {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          final backCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
          _cameraController = CameraController(
            backCamera,
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await _cameraController!.initialize();
          if (mounted) {
            setState(() => _isCameraReady = true);
          }
        }
      } catch (e) {
        debugPrint('Camera init exception: $e');
        if (mounted) setState(() => _isCameraReady = true);
      }
    }

    _startContinuousScanning();
  }

  void _startContinuousScanning() {
    _analysisLoopTimer?.cancel();
    _analysisLoopTimer =
        Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted || _isLockedOn || _isAnalyzingFrame) return;
      _performFrameAnalysis();
    });
  }

  Future<void> _performFrameAnalysis() async {
    if (_isAnalyzingFrame || _isLockedOn) return;
    _isAnalyzingFrame = true;
    _scanTicks++;

    if (mounted) {
      setState(() {
        if (!_isPlantInFrame && !_isWaterMugInFrame) {
          if (_scanTicks % 2 == 1) {
            _hudStatus = '🌿 Searching for ${widget.plant.plantName}...';
            _hudDetail = 'Point camera at plant foliage';
          } else {
            _hudStatus = '💧 Looking for water mug / watering can...';
            _hudDetail = 'Hold water container in view';
          }
        }
      });
    }

    try {
      String? framePath;
      if (kIsWeb) {
        framePath = await _webBridge.captureFrame();
      } else if (_cameraController != null &&
          _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        framePath = xFile.path;
      }

      if (framePath != null && framePath.isNotEmpty) {
        final result = await AIService().detectWateringFrame(
          plant: widget.plant,
          photoPath: framePath,
        );

        if (mounted) {
          setState(() {
            _isPlantInFrame = result.isPlantPresent;
            _isWaterMugInFrame = result.isWaterMugPresent;
            _hudStatus = result.statusMessage;
            if (result.detectedObjects.isNotEmpty) {
              _hudDetail = result.detectedObjects;
            }
          });
        }

        // Auto-capture condition: Both plant and water mug detected in frame
        if (result.isWateringReady ||
            (result.isPlantPresent && result.isWaterMugPresent)) {
          _isLockedOn = true;
          _analysisLoopTimer?.cancel();

          if (mounted) {
            setState(() {
              _isPlantInFrame = true;
              _isWaterMugInFrame = true;
              _hudStatus =
                  '✨ LOCKED: ${widget.plant.plantName} + Water Mug in frame!';
              _hudDetail = 'Auto-capturing watering proof...';
            });

            await Future.delayed(const Duration(milliseconds: 800));
            if (!mounted) return;

            // Auto-navigate to Daily Checkin Screen with auto-captured photo
            Navigator.of(context).pushReplacement(
              CloudPageRoute(
                statusMessage: '💧 Verifying Watering Proof...',
                child: DailyCheckinScreen(
                  plant: widget.plant,
                  initialPhotoPath: framePath,
                  preVerified: true,
                ),
              ),
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Real-time watering frame recognition error: $e');
    } finally {
      if (mounted) {
        _isAnalyzingFrame = false;
      }
    }
  }

  Future<void> _manualCaptureAndProceed() async {
    if (_isLockedOn) return;
    _isLockedOn = true;
    _analysisLoopTimer?.cancel();

    try {
      String? framePath;
      if (kIsWeb) {
        framePath = await _webBridge.captureFrame();
      } else if (_cameraController != null &&
          _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        framePath = xFile.path;
      }

      if (framePath != null && framePath.isNotEmpty && mounted) {
        Navigator.of(context).pushReplacement(
          CloudPageRoute(
            statusMessage: '💧 Processing Hydration Check-in...',
            child: DailyCheckinScreen(
              plant: widget.plant,
              initialPhotoPath: framePath,
              preVerified: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Manual capture error: $e');
      if (mounted) {
        setState(() => _isLockedOn = false);
        _startContinuousScanning();
      }
    }
  }

  @override
  void dispose() {
    _analysisLoopTimer?.cancel();
    _scannerAnimCtrl.dispose();
    _cameraController?.dispose();
    _webBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Feed
          Positioned.fill(
            child: _buildCameraFeed(),
          ),

          // 2. Viewfinder Dimming Mask with Center Reticle & HUD
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Top HUD Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isLockedOn
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFF00B0FF)
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _isLockedOn
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF00B0FF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isLockedOn
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF00B0FF))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isLockedOn
                                        ? '✨ HYDRATION LOCKED'
                                        : '💧 WATERING SCANNER: ${widget.plant.plantName.toUpperCase()}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dual Detection Badges (Plant & Water Mug)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDetectionPill(
                            icon: Icons.eco_rounded,
                            label: widget.plant.plantName,
                            isDetected: _isPlantInFrame,
                            activeColor: const Color(0xFF2ECC71),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetectionPill(
                            icon: Icons.water_drop_rounded,
                            label: 'Water Mug / Can',
                            isDetected: _isWaterMugInFrame,
                            activeColor: const Color(0xFF00B0FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Scanning Reticle Box
                  Center(
                    child: Container(
                      width: 290,
                      height: 310,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isLockedOn
                              ? const Color(0xFF00E676)
                              : const Color(0xFF00B0FF).withValues(alpha: 0.6),
                          width: _isLockedOn ? 3.0 : 2.0,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (_isLockedOn
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFF00B0FF))
                                .withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 4 Reticle Corners
                          _buildReticleCorners(),

                          // Animated Hydration Laser Scanner Bar
                          AnimatedBuilder(
                            animation: _laserPosition,
                            builder: (context, _) {
                              return Align(
                                alignment:
                                    Alignment(0, (_laserPosition.value * 2) - 1),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _isLockedOn
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFF00B0FF),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isLockedOn
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF00B0FF))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Target Center Reticle
                          Center(
                            child: Icon(
                              Icons.filter_center_focus_rounded,
                              size: 44,
                              color: (_isLockedOn
                                      ? const Color(0xFF00E676)
                                      : Colors.white)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom HUD Information Panel
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isLockedOn
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00B0FF).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_isLockedOn
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF00B0FF))
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isLockedOn
                                    ? Icons.check_circle_rounded
                                    : Icons.water_drop_rounded,
                                color: _isLockedOn
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFF00B0FF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hudStatus,
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hudDetail,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isLockedOn
                                ? const Color(0xFF00E676)
                                : const Color(0xFF00B0FF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isLockedOn
                                ? null
                                : () => _manualCaptureAndProceed(),
                            icon: const Icon(Icons.water_drop_rounded, size: 20),
                            label: Text(
                              _isAnalyzingFrame
                                  ? 'Analyzing Live Feed...'
                                  : 'Instant Capture & Water 💧',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionPill({
    required IconData icon,
    required String label,
    required bool isDetected,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDetected
            ? activeColor.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDetected ? activeColor : Colors.white24,
          width: isDetected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDetected ? Icons.check_circle_rounded : icon,
            size: 14,
            color: isDetected ? activeColor : Colors.white60,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isDetected ? '$label ✓' : label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: isDetected ? FontWeight.w800 : FontWeight.w600,
                color: isDetected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed() {
    if (kIsWeb) {
      if (_webBridge.viewId != null && _isCameraReady) {
        return HtmlElementView(viewType: _webBridge.viewId!);
      }
      return Container(
        color: const Color(0xFF0D2538),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00B0FF)),
        ),
      );
    }

    if (_isCameraReady &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    // Default botanical camera backdrop for simulators or desktop
    return Container(
      color: const Color(0xFF0D2538),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded,
                size: 72, color: Color(0xFF00B0FF)),
            const SizedBox(height: 12),
            Text(
              'Hydration Camera Live Feed...',
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReticleCorners() {
    const cornerSize = 22.0;
    const thickness = 4.0;
    final color =
        _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF00B0FF);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
