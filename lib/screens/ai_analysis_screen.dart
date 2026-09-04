import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaf_discovery_badge_dialog.dart';
import '../widgets/skeuo_live_camera_screen.dart';

import '../widgets/app_background.dart';

/// Screen 13: AI Plant Analysis (from 255.jpg)
/// - Top Bar: Back button + "AI Plant Analysis" + Real-time Camera Scanner action
/// - Scanned plant image with glowing reticle / AI bounding box
/// - Species verification badge & discovery explorer rewards
/// - Stat Badges: Health 90% (❤️), Disease: Healthy, Confidence: 98%
/// - Recommendations Checklist:
///   * Water tomorrow morning
///   * Keep in sunlight
///   * No disease detected
///   * Plant is in perfect condition
/// - "View History" button
class AIAnalysisScreen extends StatefulWidget {
  final PlantModel plant;
  final String? initialPhotoPath;

  const AIAnalysisScreen({
    super.key,
    required this.plant,
    this.initialPhotoPath,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineCtrl;
  bool _isAnalyzing = false;
  late int _health;
  late String _disease;
  late int _confidence;
  late List<String> _recommendations;
  String? _photoPath;
  String _identifiedSpecies = '';
  bool _isNewDiscovery = false;
  bool _isPlantDetected = true;
  String? _rejectionReason;
  String _detectedObjectType = 'Plant / Leaf';

  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _photoPath = widget.initialPhotoPath ?? widget.plant.initialPhotoPath;
    _identifiedSpecies = widget.plant.speciesName;
    _health = widget.plant.health;
    _disease = widget.plant.health >= 80 ? 'Healthy' : 'Needs Care';
    _confidence = 98;
    _recommendations = [
      'Water tomorrow morning',
      'Keep in sunlight (${widget.plant.targetSunlightHours}h daily)',
      'No active disease detected',
      'Plant is growing in optimal condition',
    ];

    _runLiveAIDiagnosis();
  }

  Future<void> _runLiveAIDiagnosis() async {
    setState(() => _isAnalyzing = true);
    final result = await _aiService.analyzePlantPhoto(
      plant: widget.plant,
      photoPath: _photoPath,
    );

    if (mounted) {
      setState(() {
        _isPlantDetected = result.isPlantDetected;
        _rejectionReason = result.rejectionReason;
        _detectedObjectType = result.detectedObjectType;
        _health = result.healthPercent;
        _disease = result.diseaseStatus;
        _confidence = result.confidencePercent;
        _recommendations = result.recommendations;
        _identifiedSpecies = result.identifiedSpecies;
        _isNewDiscovery = result.isNewDiscovery;
        _isAnalyzing = false;
      });

      if (result.isPlantDetected && result.isNewDiscovery) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            LeafDiscoveryBadgeDialog.show(
              context,
              speciesName: result.identifiedSpecies,
              badgeName: result.discoveryBadgeName ??
                  '🌱 Botanical Explorer Badge',
              rewardMessage: result.discoveryRewardMessage ??
                  'You discovered a new plant species!',
            );
          }
        });
      }
    }
  }

  Future<void> _scanNewPhoto() async {
    final livePhoto = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => SkeuoLiveCameraScreen(
          title: 'Scan Plant: ${widget.plant.plantName}',
          prefix: 'scan_${widget.plant.id}',
        ),
      ),
    );
    if (livePhoto != null && mounted) {
      setState(() => _photoPath = livePhoto);
      _runLiveAIDiagnosis();
    }
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: SkeuoTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Analysis',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: SkeuoTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded,
                color: SkeuoTheme.primaryGreen, size: 24),
            tooltip: 'Scan Live Photo',
            onPressed: _scanNewPhoto,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scanned Plant Photo Container with Reticle ────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 280,
                    height: 240,
                    decoration: BoxDecoration(
                      color: _isPlantDetected
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _isPlantDetected
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: _isPlantDetected
                            ? const Color(0xFF81C784)
                            : const Color(0xFFE57373),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AppPhotoView(
                        imagePath: _photoPath,
                        fit: BoxFit.cover,
                        fallback: _buildFallbackIllustration(),
                      ),
                    ),
                  ),

                  // Animated Scanning Line Overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedBuilder(
                        animation: _scanLineCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _ScannerLinePainter(
                              progress: _scanLineCtrl.value,
                              isPlant: _isPlantDetected,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Reticle corner marks
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ReticleCornersPainter(
                          isPlant: _isPlantDetected,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Non-Plant Rejection Alert / Verification Banner ──
            if (!_isPlantDetected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFEF5350),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFCDD2),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFC62828),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Non-Plant Photo Captured',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFC62828),
                                ),
                              ),
                              Text(
                                'Detected: $_detectedObjectType',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFB71C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'REJECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _rejectionReason ??
                          'The scanner detected a wall, pen, or non-plant object. Please capture a clear image of plant leaves, seedlings, or stem.',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _scanNewPhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Re-Scan Plant Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isNewDiscovery
                      ? const Color(0xFFFFF8E1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isNewDiscovery
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFFE8F5E9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isNewDiscovery
                            ? const Color(0xFFFFECB3)
                            : const Color(0xFFE8F5E9),
                      ),
                      child: Text(
                        _isNewDiscovery ? '🎖️' : '🌿',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isNewDiscovery
                                ? 'New Discovery Identified!'
                                : 'Botanical Database Match',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isNewDiscovery
                                  ? const Color(0xFFE65100)
                                  : SkeuoTheme.textSecondary,
                            ),
                          ),
                          Text(
                            _identifiedSpecies.isNotEmpty
                                ? _identifiedSpecies
                                : widget.plant.speciesName,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isNewDiscovery
                            ? const Color(0xFFFF8F00)
                            : SkeuoTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isNewDiscovery ? 'NEW DISCOVERY' : 'VERIFIED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (_isAnalyzing)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2E7D32)),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AI is analyzing leaf features & database...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Stat Badges Row: Health, Disease, Confidence ──────────────
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Health',
                    value: '$_health%',
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFE53935),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Disease',
                    value: _disease,
                    icon: Icons.shield_rounded,
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Confidence',
                    value: '$_confidence%',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFFFFA000),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Recommendations Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE8F5E9),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendations',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF37474F),
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

            const SizedBox(height: 28),

            // ── "View History" Button ─────────────────────────────────────
            FunBouncyButton(
              text: 'View History',
              onPressed: () {
                Navigator.of(context).pop();
              },
              color: const Color(0xFF4CAF50),
              textColor: Colors.white,
              height: 52,
              fontSize: 16,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFallbackIllustration() {
    return Center(
      child: Image.asset(
        'assets/illustrations/tracking_plant.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.local_florist_rounded,
          size: 80,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE8F5E9),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerLinePainter extends CustomPainter {
  final double progress;
  final bool isPlant;

  _ScannerLinePainter({required this.progress, this.isPlant = true});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final strokeColor = isPlant ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          strokeColor.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPlant != isPlant;
}

class _ReticleCornersPainter extends CustomPainter {
  final bool isPlant;

  _ReticleCornersPainter({this.isPlant = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlant ? const Color(0xFF00E676) : const Color(0xFFFF5252)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 18.0;
    const pad = 12.0;

    // Top Left
    canvas.drawLine(
        const Offset(pad, pad + len), const Offset(pad, pad), paint);
    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad + len, pad), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - pad - len, pad),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + len), paint);

    // Bottom Left
    canvas.drawLine(Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - pad - len, size.height - pad),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad - len),
        Offset(size.width - pad, size.height - pad), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticleCornersPainter oldDelegate) =>
      oldDelegate.isPlant != isPlant;
}

