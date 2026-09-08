import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_species.dart';
import '../services/ai_service.dart';
import '../services/excel_service.dart';
import '../widgets/camera_web_bridge.dart';
import '../widgets/cloud_transition.dart';
import 'add_plant_screen.dart';

/// Screen 1 of Plant Adding: Automated Real-Time Plant Recognition Scanner
/// Continuous viewfinder scanning (like Face Recognition) with zero manual capture/upload buttons.
/// Live feedback HUD detects plant species and automatically captures and navigates to Screen 2.
class RealtimePlantScannerScreen extends StatefulWidget {
  const RealtimePlantScannerScreen({super.key});

  @override
  State<RealtimePlantScannerScreen> createState() =>
      _RealtimePlantScannerScreenState();
}

class _RealtimePlantScannerScreenState extends State<RealtimePlantScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final CameraWebBridge _webBridge = CameraWebBridge();
  final ExcelService _excelService = ExcelService();

  late AnimationController _scannerAnimCtrl;
  late Animation<double> _laserPosition;
  late AnimationController _sparkleCtrl;
  late AnimationController _tenSecondCtrl;

  bool _isCameraReady = false;
  bool _isAnalyzingFrame = false;
  bool _isLockedOn = false;
  String _hudStatus = 'Point camera at any plant or leaf...';
  String _hudDetail = 'Automated AI Plant Recognition Active';
  int _scanTicks = 0;
  Timer? _analysisLoopTimer;
  double _elapsedSeconds = 0.0;
  Timer? _stopwatchTicker;

  List<PlantSpecies> _cachedSpecies = [];

  @override
  void initState() {
    super.initState();
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
    try {
      _cachedSpecies = await _excelService.loadSpeciesDatabase();
    } catch (_) {}

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
        // Fallback flag so scanner UI runs gracefully
        if (mounted) setState(() => _isCameraReady = true);
      }
    }

    // Start periodic scanning cycle (like real-time face recognition)
    _startContinuousScanning();
  }

  void _startContinuousScanning() {
    _analysisLoopTimer?.cancel();
    _analysisLoopTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
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
        if (_scanTicks % 3 == 1) {
          _hudStatus = '🌿 Scanning foliage & leaf vein structures...';
          _hudDetail = 'AI Vision Model analyzing live feed';
        } else if (_scanTicks % 3 == 2) {
          _hudStatus = '🔍 Evaluating species taxonomy & classification...';
          _hudDetail = 'Cross-referencing botanical database';
        } else {
          _hudStatus = '🌱 Matching plant species characteristics...';
          _hudDetail = 'Aligning camera angle with leaf';
        }
      });
    }

    try {
      String? framePath;
      if (kIsWeb) {
        framePath = await _webBridge.captureFrame();
      } else if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        framePath = xFile.path;
      }

      if (framePath != null && framePath.isNotEmpty) {
        final result = await AIService().identifyPlantSpecies(
          photoPath: framePath,
          cachedSpecies: _cachedSpecies,
        );

        if (result.isPlantDetected && result.confidencePercent >= 75) {
          // Positive recognition lock!
          _isLockedOn = true;
          _analysisLoopTimer?.cancel();

          if (mounted) {
            setState(() {
              _hudStatus = '✨ Confirmed: ${result.identifiedSpecies} (${result.confidencePercent}%)';
              _hudDetail = 'Auto-capturing and preparing plant profile...';
            });

            await Future.delayed(const Duration(milliseconds: 900));
            if (!mounted) return;

            // Transition automatically to Screen 2 (AddPlantScreen) with Cloud Transition
            Navigator.of(context).pushReplacement(
              CloudPageRoute(
                statusMessage: '🌱 Preparing Plant Profile...',
                child: AddPlantScreen(
                  autoCapturedPhotoPath: framePath,
                  initialSpecies: result.matchedSpecies,
                  identifiedSpeciesName: result.identifiedSpecies,
                  aiConfidence: result.confidencePercent,
                  isNewDiscovery: result.isNewDiscovery,
                  isPlantDetected: result.isPlantDetected,
                  rejectionReason: result.rejectionReason,
                  detectedObjectType: result.detectedObjectType,
                ),
              ),
            );
            return;
          }
        } else if (!result.isPlantDetected) {
          if (mounted) {
            setState(() {
              _hudStatus = '🔍 Aim directly at plant leaves or stem...';
              _hudDetail = result.rejectionReason ?? 'Searching for botanical foliage';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Real-time frame recognition error: $e');
      if (mounted) {
        setState(() {
          _hudStatus = '🔍 Point camera at plant foliage...';
          _hudDetail = 'Adjust camera angle and lighting';
        });
      }
    } finally {
      _isAnalyzingFrame = false;
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

          // 2. Viewfinder Dimming Mask with Center Reticle
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Sparkling 10-Second Loader & HUD Bar
                  _buildTopSparklingLoader(),

                  const Spacer(),

                  // Center Scanning Reticle Box (Simulates Face/Plant Recognition Box)
                  Center(
                    child: Container(
                      width: 280,
                      height: 320,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isLockedOn
                              ? const Color(0xFF00E676)
                              : const Color(0xFF2ECC71).withValues(alpha: 0.6),
                          width: _isLockedOn ? 3.0 : 2.0,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (_isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71))
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

                          // Animated Laser Scanner Bar
                          AnimatedBuilder(
                            animation: _laserPosition,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment(0, (_laserPosition.value * 2) - 1),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71))
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
                              size: 40,
                              color: (_isLockedOn ? const Color(0xFF00E676) : Colors.white)
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
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isLockedOn
                            ? const Color(0xFF00E676)
                            : const Color(0xFF2ECC71).withValues(alpha: 0.4),
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
                                color: (_isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71))
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isLockedOn ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                                color: _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hudStatus,
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hudDetail,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: (_isAnalyzingFrame || _isLockedOn)
                                ? null
                                : () => _performFrameAnalysis(),
                            icon: const Icon(Icons.flash_on_rounded, size: 20),
                            label: Text(
                              _isAnalyzingFrame ? 'Analyzing Plant...' : 'Instant Capture & Identify ⚡',
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

  Widget _buildCameraFeed() {
    if (kIsWeb) {
      if (_webBridge.viewId != null && _isCameraReady) {
        return HtmlElementView(viewType: _webBridge.viewId!);
      }
      return Container(
        color: const Color(0xFF1B2E1E),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    // Default botanical camera backdrop for simulators or desktop
    return Container(
      color: const Color(0xFF1B2E1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_florist_rounded, size: 72, color: Color(0xFF4CAF50)),
            const SizedBox(height: 12),
            Text(
              'Scanning Live Camera Stream...',
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
    final color = _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71);

    return Stack(
      children: [
        // Top-left
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
        // Top-right
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
        // Bottom-left
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
        // Bottom-right
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
    if (_isLockedOn) {
      phaseText = '✨ Plant Identified & Locked!';
    } else if (progress < 0.35) {
      phaseText = '🌿 Aligning Foliage & Leaf Veins...';
    } else if (progress < 0.70) {
      phaseText = '🔬 AI Vision Identifying Species...';
    } else {
      phaseText = '✨ Taxonomy & Health Diagnostics...';
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
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isLockedOn
                          ? const Color(0xFF00E676)
                          : const Color(0xFF2ECC71).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _isLockedOn ? const Color(0xFF00E676) : const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.9),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLockedOn ? 'TARGET CONFIRMED' : 'AI REAL-TIME SCANNER',
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
              const SizedBox(width: 10),
              // Live Stopwatch / Countdown Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLockedOn
                        ? [const Color(0xFF00E676), const Color(0xFF1B5E20)]
                        : [const Color(0xFF1E8449), const Color(0xFF114B27)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isLockedOn
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFF2ECC71).withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      _isLockedOn
                          ? 'LOCK'
                          : '${_elapsedSeconds.toStringAsFixed(1)}s / 10s',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Sparkling 10-Second Shimmer Progress Bar
          AnimatedBuilder(
            animation: Listenable.merge([_sparkleCtrl, _tenSecondCtrl]),
            builder: (context, child) {
              final sparkleOffset = _sparkleCtrl.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isLockedOn
                        ? const Color(0xFF00E676)
                        : const Color(0xFF2ECC71).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic phase text with animated sparkle icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Transform.rotate(
                                angle: sparkleOffset * 6.28,
                                child: Text(
                                  sparkleOffset > 0.5 ? '✨' : '⭐',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  phaseText,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF69F0AE),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Sparkling Progress Track
                    Stack(
                      children: [
                        // Background track
                        Container(
                          height: 7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill bar with gradient
                        FractionallySizedBox(
                          widthFactor: progress > 0 ? progress : 0.05,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLockedOn
                                    ? [const Color(0xFF00E676), const Color(0xFF69F0AE)]
                                    : [
                                        const Color(0xFF00E5FF),
                                        const Color(0xFF00E676),
                                        const Color(0xFFFFD54F),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
