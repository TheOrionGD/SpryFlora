import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/ai_service.dart';
import '../services/image_service.dart';
import '../services/watering_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/skeuo_live_camera_screen.dart';

/// Screen 12: Daily Check-in (from 255.jpg)
class DailyCheckinScreen extends StatefulWidget {
  final PlantModel plant;

  const DailyCheckinScreen({
    super.key,
    required this.plant,
  });

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final ImageService _imageService = ImageService();
  final WateringService _wateringService = WateringService();

  String? _capturedPhotoPath;
  bool _wateredToday = true; // default YES
  int _sunlightHours = 4;
  final String _environmentCondition = 'Bright Indirect';
  bool _isSubmitting = false;
  bool _showSuccessSplash = false;

  @override
  void initState() {
    super.initState();
    _sunlightHours = widget.plant.targetSunlightHours;
  }

  Future<void> _capturePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check-in Photo',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final livePhoto =
                            await Navigator.of(context).push<String?>(
                          MaterialPageRoute(
                            builder: (context) => SkeuoLiveCameraScreen(
                              title: 'Check-in: ${widget.plant.plantName}',
                              prefix: 'checkin_${widget.plant.id}',
                            ),
                          ),
                        );
                        if (livePhoto != null && mounted) {
                          setState(() => _capturedPhotoPath = livePhoto);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF81C784), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                size: 32, color: SkeuoTheme.primaryGreen),
                            const SizedBox(height: 8),
                            Text(
                              'Live Camera',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: SkeuoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final path = await _imageService.pickFromGallery(
                          prefix: 'checkin_${widget.plant.id}',
                        );
                        if (path != null && mounted) {
                          setState(() => _capturedPhotoPath = path);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF81C784), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                size: 32, color: SkeuoTheme.primaryGreen),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: SkeuoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCheckin() async {
    if (_capturedPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo for your daily check-in!'),
          backgroundColor: SkeuoTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_wateredToday && _capturedPhotoPath != null) {
        final verification = await AIService().verifyWateringPhoto(
          plant: widget.plant,
          photoPath: _capturedPhotoPath!,
        );

        if (verification['isVerified'] != true) {
          setState(() => _isSubmitting = false);
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  const Text('💧 Verification Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SkeuoTheme.alertRed)),
                ],
              ),
              content: Text(
                verification['rejectionReason'] ??
                    'Buddy couldn\'t verify your watering photo. Please capture a clear photo showing your plant and water! 🌱',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: SkeuoTheme.textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Try Again 📷', style: TextStyle(fontWeight: FontWeight.bold, color: SkeuoTheme.primaryGreen)),
                ),
              ],
            ),
          );
          return;
        }
      }

      final updatedPlant = await _wateringService.processCheckin(
        plant: widget.plant,
        watered: _wateredToday,
        sunlightHours: _sunlightHours,
        environmentCondition: _environmentCondition,
        photoPath: _capturedPhotoPath,
      );

      if (!mounted) return;

      setState(() => _showSuccessSplash = true);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: SkeuoTheme.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Check-in Complete!',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You logged care for ${widget.plant.plantName}! Health is now ${updatedPlant.health}%.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SkeuoTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(updatedPlant);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save check-in. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FunConfettiOverlay(
      isActive: _showSuccessSplash,
      mode: RewardSplashMode.waterSplash,
      child: Scaffold(
        backgroundColor: SkeuoTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: < Daily Check-in
              _buildAppBar(),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload container (Screen 12)
                      _buildPhotoUploadContainer(),
                      const SizedBox(height: 24),

                      // Did you water today?
                      Text(
                        'Did you water today?',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Yes / No options (Screen 12)
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceButton(
                              label: '✓ Yes',
                              isSelected: _wateredToday == true,
                              onTap: () => setState(() => _wateredToday = true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildChoiceButton(
                              label: 'No',
                              isSelected: _wateredToday == false,
                              onTap: () =>
                                  setState(() => _wateredToday = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Plant summary card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE5EBD8), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_rounded,
                                color: SkeuoTheme.primaryGreen, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.plant.plantName,
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: SkeuoTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${widget.plant.speciesName} • ${widget.plant.ageInDays} Days Old',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: SkeuoTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Check-in Button (Screen 12)
                      _isSubmitting
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: SkeuoTheme.primaryGreen),
                            )
                          : FunBouncyButton(
                              text: 'Submit Check-in',
                              onPressed: _submitCheckin,
                              color: SkeuoTheme.primaryGreen,
                              height: 52,
                              fontSize: 17,
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: SkeuoTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Daily Check-in',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadContainer() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4E8CE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _capturedPhotoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppPhotoView(
                      imagePath: _capturedPhotoPath,
                      fit: BoxFit.cover,
                      fallback: const Center(
                        child: Icon(Icons.eco_rounded,
                            size: 48, color: SkeuoTheme.primaryGreen),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: SkeuoTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: SkeuoTheme.primaryGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Take or Upload Plant Photo',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SkeuoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? SkeuoTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? SkeuoTheme.primaryGreen
                : const Color(0xFFC8E6C9),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : SkeuoTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

