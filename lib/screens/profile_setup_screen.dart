import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/excel_service.dart';
import '../services/image_service.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/skeuo_live_camera_screen.dart';
import 'home_screen.dart';

/// Screen 07: Child Profile Setup (from 255.jpg)
class ProfileSetupScreen extends StatefulWidget {
  final String? initialName;

  const ProfileSetupScreen({
    super.key,
    this.initialName,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _ageController = TextEditingController();
  final _schoolController = TextEditingController();
  final ImageService _imageService = ImageService();
  String _selectedPlant = '';
  String? _profilePhotoPath;
  bool _isLoading = false;
  bool _showConfetti = false;
  List<String> _plantOptions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _loadSpeciesOptions();
  }

  Future<void> _loadSpeciesOptions() async {
    try {
      final speciesList = await ExcelService().loadSpeciesDatabase();
      if (speciesList.isNotEmpty && mounted) {
        setState(() {
          _plantOptions = speciesList.map((s) => s.name).toList();
          if (_selectedPlant.isEmpty || !_plantOptions.contains(_selectedPlant)) {
            _selectedPlant = _plantOptions.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: SkeuoTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: SkeuoTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                'Add a Profile Photo',
                style: SkeuoTheme.funHeading(
                    size: 20, color: SkeuoTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _photoOptionButton(
                      emoji: '📷',
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final livePhoto =
                            await Navigator.of(context).push<String?>(
                          MaterialPageRoute(
                            builder: (_) => const SkeuoLiveCameraScreen(
                              title: 'Capture Profile Photo',
                              prefix: 'profile',
                            ),
                          ),
                        );
                        if (livePhoto != null) {
                          setState(() => _profilePhotoPath = livePhoto);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _photoOptionButton(
                      emoji: '🖼️',
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final path = await _imageService.pickFromGallery(
                            prefix: 'profile');
                        if (path != null) {
                          setState(() => _profilePhotoPath = path);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOptionButton({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: SkeuoTheme.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: SkeuoTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: SkeuoTheme.funBody(
                size: 14,
                color: SkeuoTheme.primaryGreen,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userProfile = UserProfile(
        childName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 10,
        school: _schoolController.text.trim(),
        favoritePlant: _selectedPlant,
        profilePhotoPath: _profilePhotoPath,
      );
      final userService = UserService();
      await userService.saveUserProfile(userProfile);
      await userService.setOnboardingCompleted(true);
      setState(() {
        _isLoading = false;
        _showConfetti = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const HomeScreen(),
          transitionsBuilder: (_, a1, a2, child) =>
              FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: SkeuoTheme.alertRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Stack(
            children: [
            // Top foliage accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: CustomPaint(
                painter: _TopBotanicalLeavesPainter(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Header
                      Text(
                        'Tell us about you!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This helps us personalize\nyour plant journey.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SkeuoTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Child Avatar with camera icon overlay
                      Center(
                        child: GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFC8E6C9), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.12),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: AppPhotoView(
                                    imagePath: _profilePhotoPath,
                                    fit: BoxFit.cover,
                                    fallback: Image.asset(
                                      'assets/sprites/avatar_boy_hero.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        size: 54,
                                        color: SkeuoTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: SkeuoTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Child Name
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Child Name',
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter child name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Age
                      _buildTextField(
                        controller: _ageController,
                        hint: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) {
                            return 'Please enter age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // School
                      _buildTextField(
                        controller: _schoolController,
                        hint: 'School',
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter school'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Favorite Plant Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE8F5E9), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPlant,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: SkeuoTheme.primaryGreen),
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: SkeuoTheme.textPrimary,
                            ),
                            items: _plantOptions.map((plant) {
                              return DropdownMenuItem<String>(
                                value: plant,
                                child: Text(plant),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPlant = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save Profile Button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: SkeuoTheme.primaryGreen),
                            )
                          : FunBouncyButton(
                              text: 'Save Profile',
                              onPressed: _saveProfile,
                              color: SkeuoTheme.primaryGreen,
                              height: 52,
                              fontSize: 17,
                            ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: SkeuoTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(
            fontSize: 15,
            color: const Color(0xFFA5D6A7),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

class _TopBotanicalLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final pathLeft = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
          size.width * 0.2, size.height * 0.1, size.width * 0.35, 0)
      ..close();
    canvas.drawPath(pathLeft, paint);

    final pathRight = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(
          size.width * 0.8, size.height * 0.25, size.width * 0.65, 0)
      ..close();
    canvas.drawPath(pathRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

