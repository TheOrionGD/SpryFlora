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
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final CameraWebBridge _webBridge = CameraWebBridge();

  late AnimationController _scannerAnimCtrl;
  late Animation<double> _laserPosition;
  late AnimationController _sparkleCtrl;
  late AnimationController _tenSecondCtrl;

  bool _isCameraReady = false;
  bool _isAnalyzingFrame = false;
  bool _isLockedOn = false;
  bool _hasNoPlantDetected = false;

  bool _isPlantInFrame = false;
  bool _isWaterMugInFrame = false;

  String _hudStatus = 'Point camera at your plant and water mug 💧';
  String _hudDetail = 'AI real-time hydration scanning active';
  int _scanTicks = 0;
  Timer? _analysisLoopTimer;
  double _elapsedSeconds = 0.0;
  Timer? _stopwatchTicker;

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

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _tenSecondCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _isLockedOn) return;
      setState(() {
        _elapsedSeconds = (_elapsedSeconds + 0.1);
        if (_elapsedSeconds > 10.0) _elapsedSeconds = 0.0;
      });
    });

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

    if (mounted && !_hasNoPlantDetected) {
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
            if (!result.isPlantPresent) {
              _hasNoPlantDetected = true;
              _hudStatus = 'No plant in frame';
              _hudDetail = 'Point camera at ${widget.plant.plantName} foliage or tap to capture';
            } else {
              _hasNoPlantDetected = false;
              _hudStatus = result.statusMessage;
              if (result.detectedObjects.isNotEmpty) {
                _hudDetail = result.detectedObjects;
              }
            }
          });
        }

        // Auto-capture condition: Both plant and water mug detected in frame
        if (result.isPlantPresent &&
            (result.isWateringReady || result.isWaterMugPresent)) {
          _isLockedOn = true;
          _hasNoPlantDetected = false;
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
      if (mounted) {
        setState(() {
          _hasNoPlantDetected = false;
          _hudStatus = 'Aim camera at ${widget.plant.plantName}';
          _hudDetail = 'Hold water mug near foliage';
        });
      }
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
    _stopwatchTicker?.cancel();
    _scannerAnimCtrl.dispose();
    _sparkleCtrl.dispose();
    _tenSecondCtrl.dispose();
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
                  // Top Sparkling 10-Second Loader & HUD Bar
                  _buildTopSparklingLoader(),

                  // Dual Detection Badges (Plant & Water Mug)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDetectionPill(
                            icon: Icons.eco_rounded,
                            label: _hasNoPlantDetected ? 'No Plant Found' : widget.plant.plantName,
                            isDetected: _isPlantInFrame && !_hasNoPlantDetected,
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
                      width: 280,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasNoPlantDetected
                              ? const Color(0xFFE53935)
                              : _isLockedOn
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF00B0FF).withValues(alpha: 0.6),
                          width: (_isLockedOn || _hasNoPlantDetected) ? 3.0 : 2.0,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (_hasNoPlantDetected
                                    ? const Color(0xFFE53935)
                                    : _isLockedOn
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF00B0FF))
                                .withValues(alpha: 0.28),
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
                              final laserColor = _hasNoPlantDetected
                                  ? const Color(0xFFE53935)
                                  : _isLockedOn
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFF00B0FF);
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
                                        laserColor,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: laserColor.withValues(alpha: 0.8),
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
                              _hasNoPlantDetected
                                  ? Icons.error_outline_rounded
                                  : Icons.filter_center_focus_rounded,
                              size: 44,
                              color: (_hasNoPlantDetected
                                      ? const Color(0xFFE53935)
                                      : _isLockedOn
                                          ? const Color(0xFF00E676)
                                          : Colors.white)
                                  .withValues(alpha: 0.7),
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
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _hasNoPlantDetected
                            ? const Color(0xFFE53935)
                            : _isLockedOn
                                ? const Color(0xFF00E676)
                                : const Color(0xFF00B0FF).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _hasNoPlantDetected
                              ? const Color(0xFFE53935).withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.5),
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
                                color: (_hasNoPlantDetected
                                        ? const Color(0xFFE53935)
                                        : _isLockedOn
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFF00B0FF))
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _hasNoPlantDetected
                                    ? Icons.cancel_rounded
                                    : _isLockedOn
                                        ? Icons.check_circle_rounded
                                        : Icons.water_drop_rounded,
                                color: _hasNoPlantDetected
                                    ? const Color(0xFFFF5252)
                                    : _isLockedOn
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
                                      color: _hasNoPlantDetected
                                          ? const Color(0xFFFF5252)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hudDetail,
                                    style: GoogleFonts.nunito(
                                      color: _hasNoPlantDetected
                                          ? const Color(0xFFFFCDD2)
                                          : Colors.white70,
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
                            _hasNoPlantDetected
                                ? const Color(0xFFE53935)
                                : _isLockedOn
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
                            onPressed: (_isLockedOn || _isAnalyzingFrame)
                                ? null
                                : () => _manualCaptureAndProceed(),
                            icon: const Icon(
                              Icons.water_drop_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isAnalyzingFrame
                                  ? 'Analyzing Live Feed...'
                                  : 'Instant Capture & Water 💧',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
    final color = _hasNoPlantDetected
        ? const Color(0xFFE53935)
        : _isLockedOn
            ? const Color(0xFF00E676)
            : const Color(0xFF00B0FF);

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

  Widget _buildTopSparklingLoader() {
    final progress = (_elapsedSeconds / 10.0).clamp(0.0, 1.0);

    String phaseText;
    if (_hasNoPlantDetected) {
      phaseText = '⚠️ No plant found in camera view';
    } else if (_isLockedOn) {
      phaseText = '✨ Plant & Mug Confirmed • Hydration Ready!';
    } else if (!_isPlantInFrame && !_isWaterMugInFrame) {
      phaseText = '🌿 Aim at ${widget.plant.plantName} & water mug...';
    } else if (_isPlantInFrame && !_isWaterMugInFrame) {
      phaseText = '💧 Plant detected! Bring water mug in view...';
    } else if (!_isPlantInFrame && _isWaterMugInFrame) {
      phaseText = '🌿 Water mug detected! Aim at plant leaves...';
    } else {
      phaseText = '✨ Verifying hydration frame alignment...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Close Button + Scanner Title + Live Stopwatch Badge
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasNoPlantDetected
                          ? const Color(0xFFE53935)
                          : _isLockedOn
                              ? const Color(0xFF00E676)
                              : const Color(0xFF00B0FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _hasNoPlantDetected
                              ? const Color(0xFFE53935)
                              : _isLockedOn
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF00B0FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_hasNoPlantDetected
                                      ? const Color(0xFFE53935)
                                      : _isLockedOn
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFF00B0FF))
                                  .withValues(alpha: 0.9),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hasNoPlantDetected
                              ? 'NO PLANT DETECTED'
                              : _isLockedOn
                                  ? '✨ HYDRATION LOCKED'
                                  : '💧 WATERING SCANNER: ${widget.plant.plantName.toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            color: _hasNoPlantDetected ? const Color(0xFFFF5252) : Colors.white,
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
              const SizedBox(width: 10),
              // Live Stopwatch / Countdown Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hasNoPlantDetected
                        ? [const Color(0xFFD32F2F), const Color(0xFF5D1010)]
                        : _isLockedOn
                            ? [const Color(0xFF00E676), const Color(0xFF1B5E20)]
                            : [const Color(0xFF0288D1), const Color(0xFF01579B)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hasNoPlantDetected
                        ? const Color(0xFFFF5252)
                        : _isLockedOn
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFF40C4FF).withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasNoPlantDetected
                              ? const Color(0xFFE53935)
                              : const Color(0xFF00B0FF))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _sparkleCtrl,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _sparkleCtrl.value * 2 * 3.14159,
                          child: Icon(
                            _hasNoPlantDetected ? Icons.warning_amber_rounded : Icons.auto_awesome,
                            color: Colors.white,
                            size: 13,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _hasNoPlantDetected
                          ? 'ALERT'
                          : '${(10.0 - _elapsedSeconds).clamp(0.0, 10.0).toStringAsFixed(1)}s',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: 10-Second Sparkling Gradient Progress Bar
          Container(
            height: 7,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLockedOn
                            ? [
                                const Color(0xFF00E676),
                                const Color(0xFF69F0AE),
                              ]
                            : [
                                const Color(0xFF00B0FF),
                                const Color(0xFF00E5FF),
                                const Color(0xFF76FF03),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLockedOn
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF00B0FF))
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Row 3: Micro Phase Status
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              phaseText,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
