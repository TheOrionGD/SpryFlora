import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import 'register_screen.dart';

/// Kids Psychology UI Login Screen with Mascot Graduate Artwork holding the Card Container
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.login(
        email: _identifierCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final userService = UserService();
      await userService.loadUserData();
      final hasUser = await userService.hasUserData();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show Mascot Graduation Celebration Dialog
      await _showLoginSuccessDialog(context);

      if (!mounted) return;
      if (hasUser && userService.currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
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

  Future<void> _showLoginSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF2E7D32),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mascot Graduate Artwork
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/sprites/mascot_graduate_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: Color(0xFFF1C40F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back! 🌸',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Successfully Logged In! Ready to grow your plants?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(height: 20),
              FunBouncyButton(
                text: 'Let\'s Go! 🚀',
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Floating Leaves Particle Effect
            const Positioned.fill(
              child: LeavesParticleOverlay(),
            ),

            // 2. Main Content Layout
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

                        // Mascot Holding Card Wrapper (Peek-a-boo Mascot Graduate + Emerald Card)
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // Main Emerald Green Kids Card Container
                            Container(
                              margin: const EdgeInsets.only(top: 80),
                              padding: const EdgeInsets.fromLTRB(22, 60, 22, 22),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.95),
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
                                    'LOGIN',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
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
                                    'Login to continue your plant adventure!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF9E79F),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Username / Email Input Field
                                  _buildInputField(
                                    controller: _identifierCtrl,
                                    hintText: 'Email ID or Username',
                                    icon: Icons.person_outline_rounded,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter your email or username';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Password Input Field
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
                                      if (val == null || val.isEmpty) {
                                        return 'Enter your password';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // Remember Me & Forgot Password Row
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFFF1C40F),
                                          checkColor: Colors.black,
                                          side: const BorderSide(color: Colors.white, width: 2),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4)),
                                          onChanged: (val) {
                                            setState(() => _rememberMe = val ?? true);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          final updatedEmail = await Navigator.of(context).push<String>(
                                            MaterialPageRoute(
                                              builder: (_) => ForgotPasswordScreen(
                                                initialIdentifier: _identifierCtrl.text,
                                              ),
                                            ),
                                          );
                                           if (updatedEmail != null && updatedEmail.isNotEmpty && context.mounted) {
                                             setState(() {
                                               _identifierCtrl.text = updatedEmail;
                                               _passCtrl.clear();
                                             });
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text(
                                                   'Password updated! Please log in with your new password.',
                                                   style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                                                 ),
                                                 backgroundColor: const Color(0xFF27AE60),
                                                 behavior: SnackBarBehavior.floating,
                                               ),
                                             );
                                           }
                                        },
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFF9E79F),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 22),

                                  // Green Bouncy Sign In Button
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : FunBouncyButton(
                                          text: 'SIGN IN 🌿',
                                          onPressed: _handleLogin,
                                          color: const Color(0xFF1E8449),
                                          textColor: Colors.white,
                                          height: 52,
                                          fontSize: 18,
                                        ),

                                  const SizedBox(height: 20),

                                  // Don't have an account? Sign Up Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Sign Up',
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

                            // Mascot Graduate Header Standing above and holding card
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF27AE60), size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
