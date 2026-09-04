import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Kids Psychology UI Register Screen with Mascot Celebration Artwork holding Card Container
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childNameCtrl = TextEditingController(text: 'Leo');
  final _usernameCtrl = TextEditingController(text: 'leo_gardener');
  final _parentEmailCtrl = TextEditingController(text: 'hero@spryflora.com');
  final _dobCtrl = TextEditingController(text: '2016-05-14');
  final _favPlantCtrl = TextEditingController(text: 'Sunflower 🌻');
  final _passCtrl = TextEditingController(text: 'spryflora123');
  final _confirmPassCtrl = TextEditingController(text: 'spryflora123');

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _showConfetti = false;

  @override
  void dispose() {
    _childNameCtrl.dispose();
    _usernameCtrl.dispose();
    _parentEmailCtrl.dispose();
    _dobCtrl.dispose();
    _favPlantCtrl.dispose();
    _passCtrl.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showConfetti = true;
    });

    try {
      final authService = AuthService();
      await authService.register(
        email: _parentEmailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _childNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        favoritePlant: _favPlantCtrl.text.trim(),
      );

      final userService = UserService();
      await userService.loadUserData();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show Mascot Celebration Dialog & Auto-login directly to Home Page
      await _showRegistrationSuccessDialog(context);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showConfetti = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showRegistrationSuccessDialog(BuildContext context) async {
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
              // Mascot Celebrating Confetti Artwork
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/sprites/mascot_celebrating_confetti.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.celebration_rounded,
                    size: 80,
                    color: Color(0xFFF1C40F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'YAY! 🎉 WELCOME!',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account Created Successfully!\nYour green journey begins now!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(height: 20),
              FunBouncyButton(
                text: 'START EXPLORING! 🌿',
                onPressed: () => Navigator.of(ctx).pop(),
                color: const Color(0xFFF1C40F),
                textColor: Colors.black,
                height: 48,
                fontSize: 16,
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
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Floating Leaves Particle Overlay
              const Positioned.fill(
                child: LeavesParticleOverlay(),
              ),

              // 2. Main Scrollable Content Layout
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
                          const SizedBox(height: 20),

                          // Mascot Holding Card Wrapper (Mascot Celebration Confetti + Green Card)
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Main Emerald Green Kids Card Container
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
                                    // Card Title inside container
                                    Text(
                                      'CREATE ACCOUNT',
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
                                      'Join SpryFlora & grow your virtual plant!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF9E79F),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // 1. Child Name
                                    _buildInputField(
                                      controller: _childNameCtrl,
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

                                    // 2. Username
                                    _buildInputField(
                                      controller: _usernameCtrl,
                                      hintText: 'Choose a Username',
                                      icon: Icons.alternate_email_rounded,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Choose a username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 3. Parent / Child Email
                                    _buildInputField(
                                      controller: _parentEmailCtrl,
                                      hintText: 'Email Address',
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
                                    ),
                                    const SizedBox(height: 12),

                                    // 6. Password
                                    _buildInputField(
                                      controller: _passCtrl,
                                      hintText: 'Password',
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
                                          return 'Must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 7. Confirm Password
                                    _buildInputField(
                                      controller: _confirmPassCtrl,
                                      hintText: 'Confirm Password',
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
                                        if (val != _passCtrl.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Green Register Button
                                    _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : FunBouncyButton(
                                            text: 'REGISTER & START 🌿',
                                            onPressed: _handleRegister,
                                            color: const Color(0xFF1E8449),
                                            textColor: Colors.white,
                                            height: 52,
                                            fontSize: 18,
                                          ),

                                    const SizedBox(height: 18),

                                    // Already have an account? Login
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (Navigator.of(context).canPop()) {
                                              Navigator.of(context).pop();
                                            } else {
                                              Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (_) => const LoginScreen(),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            'Login',
                                            style: GoogleFonts.nunito(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFF1C40F),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Mascot Celebrating Confetti Header Standing above and holding card
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
                                        'assets/sprites/mascot_celebrating_confetti.png',
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
