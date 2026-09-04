import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/certificate_capture_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/botanical_corner_leaves.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/professional_landscape_certificate.dart';
import '../widgets/skeuo_button.dart';
import 'home_screen.dart';
import 'my_certifications_screen.dart';

/// 4-Step Interactive Professional Landscape Certificate Flow:
/// Step 0: Screen 17 — "You did it! Your plant is all grown!" (or Locked View if incomplete)
/// Step 1: Screen 18 — "Generating Certificate..." animated progress bar
/// Step 2: Screen 19 — Ultra-Realistic Professional Landscape Certificate Preview with Download & Share
/// Step 3: Screen 20 — "Yay! Certificate Saved in your gallery" + "Back to Home" & "View in Gallery"
class CertificateScreen extends StatefulWidget {
  final PlantModel plant;

  const CertificateScreen({
    super.key,
    required this.plant,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with TickerProviderStateMixin {
  late AnimationController _genProgressCtrl;
  final GlobalKey _certBoundaryKey = GlobalKey();

  int _currentStep =
      0; // 0 = Screen 17, 1 = Screen 18, 2 = Screen 19, 3 = Screen 20
  late String _userName;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _genProgressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Retrieve user name
    final user = UserService().currentUser;
    _userName = (user != null && user.childName.trim().isNotEmpty)
        ? user.childName.trim()
        : 'Plant Hero';
  }

  @override
  void dispose() {
    _genProgressCtrl.dispose();
    super.dispose();
  }

  void _startGenerating() {
    if (!AuthService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Authentication required to generate certificates.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!widget.plant.isCompleted) return;
    setState(() => _currentStep = 1);
    _genProgressCtrl.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _currentStep = 2);
      }
    });
  }

  Future<void> _handleDownload() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Uint8List? pngBytes = await CertificateCaptureService.capturePng(
          _certBoundaryKey,
          pixelRatio: 3.0);

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⚠️ Could not capture certificate. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final String? savedPath =
          await CertificateCaptureService.saveCertificateImage(
        pngBytes: pngBytes,
        plantName: widget.plant.plantName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    savedPath != null
                        ? '✅ Certificate saved to your device!'
                        : '✅ Certificate saved successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _currentStep = 3);
      }
    } catch (e) {
      debugPrint('Download error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Uint8List? pngBytes = await CertificateCaptureService.capturePng(
          _certBoundaryKey,
          pixelRatio: 3.0);

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Could not capture certificate for sharing.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await CertificateCaptureService.shareCertificateImage(
        pngBytes: pngBytes,
        plantName: widget.plant.plantName,
        recipientName: _userName,
      );
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkeuoTheme.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case 0:
        return _buildScreen17();
      case 1:
        return _buildScreen18();
      case 2:
        return _buildScreen19();
      case 3:
        return _buildScreen20();
      default:
        return _buildScreen17();
    }
  }

  /// --------------------------------------------------------------------------
  /// SCREEN 17: Certificate Collection Page - Exact Design Replication
  /// --------------------------------------------------------------------------
  Widget _buildScreen17() {
    final bool isCompleted = widget.plant.isCompleted;
    final int age = widget.plant.ageInDays;
    final int lifespan = widget.plant.lifespanDays;
    final int remainingDays = math.max(lifespan - age, 0);

    return FunConfettiOverlay(
      key: const ValueKey('screen_17'),
      isActive: isCompleted,
      mode: RewardSplashMode.certificateAchievement,
      child: Stack(
        children: [
          // 1. Nature Backdrop Image
          Positioned.fill(
            child: Image.asset(
              'assets/sprites/image.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF81D4FA),
                      Color(0xFFA5D6A7),
                      Color(0xFF388E3C),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Botanical Corner Leaves Frame
          const Positioned.fill(
            child: BotanicalLeavesFrame(
              leafSize: 130,
              opacity: 0.95,
            ),
          ),

          // 3. Back Button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),

          // 4. Content Area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  // Top-Right Title Block
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCompleted ? 'You did it!' : 'Almost there!',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1B4D2E),
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.white70,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompleted
                                ? 'Your plant is\nall grown!'
                                : '$remainingDays days left until\nyour plant matures!',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C5E3B),
                              height: 1.25,
                              shadows: const [
                                Shadow(
                                  color: Colors.white60,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Interactive Character Scene: Gardener Boy + Mascot Plant in Pot
                  SizedBox(
                    height: 250,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Gardener Boy Sprite
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 230,
                              child: Image.asset(
                                'assets/sprites/boy_planting.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/sprites/avatar_boy_hero.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right: Happy Plant Mascot
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 175,
                              child: Image.asset(
                                'assets/sprites/mascot_pot_happy.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/sprites/plant_potted.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Plant Title Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '🌿 ${widget.plant.plantName} • ${widget.plant.speciesName}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Action Button: "Generate Certificate"
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: isCompleted
                        ? Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF388E3C),
                                  Color(0xFF2ECC71),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _startGenerating,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Generate Certificate',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🔒 Certificate unlocks in $remainingDays days!',
                                    ),
                                    backgroundColor: const Color(0xFFE65100),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Locked ($remainingDays Days Left) 🔒',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  /// --------------------------------------------------------------------------
  /// SCREEN 18: "Generating Certificate..." + SpryFlora Logo + Animated Progress
  /// --------------------------------------------------------------------------
  Widget _buildScreen18() {
    return Center(
      key: const ValueKey('screen_18'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SpryFlora Smiling Sprout Mascot Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF81C784), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/logo/mascot_transparent.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logo/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_florist_rounded,
                        size: 54,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SpryFlora Brand Name
            Text(
              'SpryFlora',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B5E20),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Subtitle (matching Screen 18 from 255.jpg)
            Text(
              'Preparing your certificate...\nPlease wait a moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF455A64),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 28),

            // Animated Smooth Progress Bar (0% -> 100%)
            AnimatedBuilder(
              animation: _genProgressCtrl,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _genProgressCtrl.value,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// SCREEN 19: Ultra-Realistic Landscape Certificate Preview with Download & Share
  /// --------------------------------------------------------------------------
  Widget _buildScreen19() {
    return FunConfettiOverlay(
      key: const ValueKey('screen_19'),
      isActive: true,
      mode: RewardSplashMode.certificateAchievement,
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1B4D3E)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Official Credential',
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF1B4D3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 48), // Balance spacing
              ],
            ),
          ),

          // Scrollable / Interactive Landscape Certificate with Capture Boundary
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The RepaintBoundary enclosing the Landscape Certificate
                    RepaintBoundary(
                      key: _certBoundaryKey,
                      child: ProfessionalLandscapeCertificate(
                        plant: widget.plant,
                        recipientName: _userName,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Certificate Badge Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFA5D6A7), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'Digitally Verified & Registered on SpryFlora Ledger',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons: [Download] and [Share]
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                // Download / Save Button
                Expanded(
                  child: SkeuoButton(
                    text: _isProcessing ? 'Saving...' : 'Download',
                    icon: Icons.download_rounded,
                    color: const Color(0xFF2E7D32),
                    height: 50,
                    onPressed: _isProcessing ? null : _handleDownload,
                  ),
                ),
                const SizedBox(width: 12),
                // Share Button
                Expanded(
                  child: SkeuoButton(
                    text: _isProcessing ? 'Preparing...' : 'Share',
                    icon: Icons.share_rounded,
                    color: const Color(0xFF1B4D3E),
                    height: 50,
                    onPressed: _isProcessing ? null : _handleShare,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// SCREEN 20: "Yay! Certificate Saved in your gallery" - Exact Design Replication
  /// --------------------------------------------------------------------------
  Widget _buildScreen20() {
    return FunConfettiOverlay(
      key: const ValueKey('screen_20'),
      isActive: true,
      mode: RewardSplashMode.certificateAchievement,
      child: Stack(
        children: [
          // 1. Nature Backdrop Image
          Positioned.fill(
            child: Image.asset(
              'assets/sprites/image.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF81D4FA),
                      Color(0xFFA5D6A7),
                      Color(0xFF388E3C),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Botanical Corner Leaves Frame
          const Positioned.fill(
            child: BotanicalLeavesFrame(
              leafSize: 130,
              opacity: 0.95,
            ),
          ),

          // 3. Top Section (Title & Mascot Artwork)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Headline
                Text(
                  'Yay!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B4D2E),
                    shadows: const [
                      Shadow(
                        color: Colors.white70,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Certificate Saved\nin your gallery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C5E3B),
                    height: 1.25,
                    shadows: const [
                      Shadow(
                        color: Colors.white60,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Mascot Image Sitting on Nature Grass Field
                SizedBox(
                  height: 220,
                  child: Image.asset(
                    'assets/sprites/mascot_pot_happy.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logo/mascot_transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const Spacer(),

                // 4. Bottom Ivory Card Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: const BoxDecoration(
                    color: SkeuoTheme.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        offset: Offset(0, -6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Back to Home" Solid Green Pill Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF388E3C),
                              Color(0xFF2ECC71),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2ECC71)
                                  .withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            'Back to Home',
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // "View in Gallery" Subtitle Action Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MyCertificationsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View in Gallery',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
