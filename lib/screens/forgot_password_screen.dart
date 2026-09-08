import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/video_background_backdrop.dart';

/// Kids Psychology UI Forgot Password Screen
/// Verification + New Password Reset with Mascot Artwork & Leaf Particle Effects
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialIdentifier;

  const ForgotPasswordScreen({
    super.key,
    this.initialIdentifier,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _favPlantCtrl = TextEditingController();

  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isVerified = false;
  bool _isLoading = false;
  bool _showConfetti = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdentifier != null && widget.initialIdentifier!.trim().isNotEmpty) {
      final id = widget.initialIdentifier!.trim();
      if (id.contains('@')) {
        _emailCtrl.text = id;
        _usernameCtrl.text = id.split('@').first;
      } else {
        _usernameCtrl.text = id;
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _favPlantCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2016, 5, 14),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2ECC71),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E8449),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dobCtrl.text = formatted;
      });
    }
  }

  Future<void> _handleVerifyDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final isMatch = await authService.verifySecurityDetails(
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        favoritePlant: _favPlantCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isMatch) {
        // Successfully verified
        setState(() {
          _isVerified = true;
          _showConfetti = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Identity Verified! Enter your new password below.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed: No matching account found with these details.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.resetPasswordWithSecurityAnswers(
        email: _emailCtrl.text.trim(),
        newPassword: _newPassCtrl.text,
      );

      setState(() {
        _isLoading = false;
        _showConfetti = true;
      });

      // Show Mascot Success Modal
      if (!mounted) return;
      await _showResetSuccessDialog(context);

      if (!mounted) return;
      Navigator.of(context).pop(_emailCtrl.text.trim());
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showResetSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF1E8449),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Image.asset(
                  'assets/sprites/mascot_graduate_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Color(0xFFF1C40F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PASSWORD RESET! 🔐',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your password has been updated!\nPlease log in within 10 minutes using your new password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(height: 20),
              FunBouncyButton(
                text: 'BACK TO LOGIN 🔑',
                onPressed: () => Navigator.of(ctx).pop(),
                color: const Color(0xFFF1C40F),
                textColor: Colors.black,
                height: 48,
                fontSize: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Video Player Background (assets/sprites/bg.mp4)
            const Positioned.fill(
              child: VideoBackgroundBackdrop(),
            ),

            // Translucent dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.50),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Leaf Particle Effect
            const Positioned.fill(
              child: LeavesParticleOverlay(),
            ),

            // 3. Foreground Scrollable Form Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Mascot Holding Card Stack Container
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // Emerald Green Kids Card Container
                            Container(
                              margin: const EdgeInsets.only(top: 80),
                              padding: const EdgeInsets.fromLTRB(22, 60, 22, 22),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card Title
                                  Text(
                                    _isVerified ? 'NEW PASSWORD' : 'FORGOT PASSWORD',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black38,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isVerified
                                        ? 'Enter your new password below:'
                                        : 'Verify your account security details:',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF9E79F),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  if (!_isVerified) ...[
                                    // 1. Email Address (Mail ID)
                                    _buildInputField(
                                      controller: _emailCtrl,
                                      hintText: 'Email Address (Mail ID)',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. Username
                                    _buildInputField(
                                      controller: _usernameCtrl,
                                      hintText: 'Username',
                                      icon: Icons.alternate_email_rounded,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 3. Child's Name
                                    _buildInputField(
                                      controller: _nameCtrl,
                                      hintText: 'Child\'s Name',
                                      icon: Icons.face_rounded,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter child\'s name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 4. Date of Birth
                                    GestureDetector(
                                      onTap: _selectDateOfBirth,
                                      child: AbsorbPointer(
                                        child: _buildInputField(
                                          controller: _dobCtrl,
                                          hintText: 'Date of Birth (YYYY-MM-DD)',
                                          icon: Icons.cake_rounded,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 5. Favorite Plant
                                    _buildInputField(
                                      controller: _favPlantCtrl,
                                      hintText: 'Favorite Plant (e.g. Sunflower)',
                                      icon: Icons.local_florist_rounded,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter favorite plant';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Button: Verify
                                    _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : FunBouncyButton(
                                            text: 'VERIFY DETAILS 🔍',
                                            onPressed: _handleVerifyDetails,
                                            color: const Color(0xFF1E8449),
                                            textColor: Colors.white,
                                            height: 52,
                                            fontSize: 17,
                                          ),
                                  ] else ...[
                                    // 1. New Password
                                    _buildInputField(
                                      controller: _newPassCtrl,
                                      hintText: 'New Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePass,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePass
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF27AE60),
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePass = !_obscurePass);
                                        },
                                      ),
                                      validator: (val) {
                                        if (val == null || val.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. Confirm New Password
                                    _buildInputField(
                                      controller: _confirmPassCtrl,
                                      hintText: 'Confirm New Password',
                                      icon: Icons.lock_reset_rounded,
                                      obscureText: _obscureConfirm,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF27AE60),
                                        ),
                                        onPressed: () {
                                          setState(() => _obscureConfirm = !_obscureConfirm);
                                        },
                                      ),
                                      validator: (val) {
                                        if (val != _newPassCtrl.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Button: Update Password
                                    _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : FunBouncyButton(
                                            text: 'UPDATE PASSWORD 🔒',
                                            onPressed: _handleResetPassword,
                                            color: const Color(0xFF1E8449),
                                            textColor: Colors.white,
                                            height: 52,
                                            fontSize: 17,
                                          ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Back to Login Link
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Back to Login',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFF1C40F),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Mascot Graduate Standing above and holding card
                            Positioned(
                              top: 0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFFF1C40F), width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Image.asset(
                                      'assets/sprites/mascot_graduate_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/logo/mascot_transparent.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2E7D32),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF27AE60), size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
