import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/excel_service.dart';
import '../services/image_service.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import '../widgets/leaves_particle_overlay.dart';
import '../widgets/app_photo_view.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Full-Featured Kid-Friendly Registration Screen
/// Captures: Username, Password, Nickname/Name, Profile Icon/Avatar, Date of Birth (calculates Age), and Favorite Plant.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  DateTime? _selectedDob;
  int _calculatedAge = 8;
  String _selectedFavoritePlant = 'Sunflower';
  String? _profilePhotoPath;
  String _selectedAvatarEmoji = '🌻';

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _showConfetti = false;

  final List<String> _avatarEmojis = ['🌻', '🌿', '🌸', '🪴', '🌵', '🍀', '🍓'];
  List<String> _speciesOptions = ['Sunflower', 'Tulsi', 'Money Plant', 'Rose', 'Aloe Vera', 'Snake Plant', 'Monstera Deliciosa', 'Peace Lily', 'Jade Plant'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDob = DateTime(now.year - 8, now.month, now.day);
    _calculatedAge = 8;
    _loadPlantSpecies();
  }

  Future<void> _loadPlantSpecies() async {
    try {
      final list = await ExcelService().loadSpeciesDatabase();
      if (list.isNotEmpty && mounted) {
        setState(() {
          _speciesOptions = list.map((s) => s.name).toSet().toList();
          if (!_speciesOptions.contains(_selectedFavoritePlant)) {
            _selectedFavoritePlant = _speciesOptions.first;
          }
        });
      }
    } catch (_) {}
  }

  void _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    setState(() {
      _selectedDob = dob;
      _calculatedAge = age.clamp(3, 100);
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B5E20),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _calculateAge(picked);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final imageService = ImageService();
    final path = await imageService.pickFromGallery(prefix: 'profile');
    if (path != null && mounted) {
      setState(() {
        _profilePhotoPath = path;
      });
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nicknameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showConfetti = true;
    });

    final username = _usernameCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim().isNotEmpty ? _nicknameCtrl.text.trim() : username;
    final password = _passCtrl.text;
    final dobStr = _selectedDob != null ? _selectedDob!.toIso8601String().split('T')[0] : '';

    try {
      final authService = AuthService();
      await authService.register(
        username: username,
        password: password,
        name: nickname,
        dob: dobStr,
        favoritePlant: _selectedFavoritePlant,
      );

      final userService = UserService();
      await userService.saveUserProfile(UserProfile(
        childName: nickname,
        age: _calculatedAge,
        school: 'Green Garden Explorer',
        favoritePlant: _selectedFavoritePlant,
        profilePhotoPath: _profilePhotoPath,
      ));

      if (!mounted) return;
      setState(() => _isLoading = false);

      await _showRegistrationSuccessDialog(context, nickname);

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

  Future<void> _showRegistrationSuccessDialog(BuildContext context, String name) async {
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
                  'assets/sprites/mascot_celebrating_confetti.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.celebration_rounded,
                    size: 80,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome, $name! 🎉',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your botanical profile is set up. Let\'s start growing and caring for your dream garden!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8F8F5),
                ),
              ),
              const SizedBox(height: 20),
              FunBouncyButton(
                text: "Let's Explore My Garden 🌿",
                onPressed: () => Navigator.of(ctx).pop(),
                color: const Color(0xFFFFD54F),
                textColor: const Color(0xFF1B5E20),
                height: 48,
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
      body: FunConfettiOverlay(
        isActive: _showConfetti,
        child: LeavesParticleOverlay(
          maxThroughput: true,
          child: AppBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mascot Icon Header
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.asset(
                          'assets/sprites/mascot_pot_happy.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco_rounded,
                            size: 60,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Join SpryFlora! 🌱',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        'Create your botanical gardener profile',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Form Container Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── 1. Profile Icon / Avatar Picker ──
                              Center(
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickProfilePhoto,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 76,
                                            height: 76,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF4CAF50),
                                                width: 2.5,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: _profilePhotoPath != null
                                                  ? AppPhotoView(
                                                      imagePath: _profilePhotoPath,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        _selectedAvatarEmoji,
                                                        style: const TextStyle(fontSize: 38),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2E7D32),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Choose Avatar or Photo',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Avatar Emojis Row
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: _avatarEmojis.map((emoji) {
                                          final isSelected = _selectedAvatarEmoji == emoji && _profilePhotoPath == null;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedAvatarEmoji = emoji;
                                                _profilePhotoPath = null;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: isSelected ? Border.all(color: const Color(0xFF2E7D32), width: 1.5) : null,
                                              ),
                                              child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── 2. Username Field ──
                              _buildFieldLabel('Username', '🧑‍🌾'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _usernameCtrl,
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                decoration: _inputDecoration(
                                  hint: 'e.g. green_hero',
                                  icon: Icons.alternate_email_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter a username';
                                  if (v.trim().length < 3) return 'Username must be at least 3 chars';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── 3. Nickname / Name Field ──
                              _buildFieldLabel('Nickname / Child Name', '✨'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _nicknameCtrl,
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                decoration: _inputDecoration(
                                  hint: 'e.g. Devansh / Little Planter',
                                  icon: Icons.face_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter your nickname';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── 4. Date of Birth & Calculated Age ──
                              Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Date of Birth', '🎂'),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: _pickDateOfBirth,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F8EE),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.calendar_month_rounded, color: Color(0xFF2E7D32), size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _selectedDob != null
                                                      ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                                                      : 'Select Date',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF1B5E20),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Age', '🎈'),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: const Color(0xFF81C784), width: 1.2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$_calculatedAge yrs',
                                              style: GoogleFonts.fredoka(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── 5. Favorite Plant Dropdown ──
                              _buildFieldLabel('Favorite Plant', '🌸'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8EE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _speciesOptions.contains(_selectedFavoritePlant) ? _selectedFavoritePlant : _speciesOptions.first,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2E7D32)),
                                    items: _speciesOptions.map((species) {
                                      return DropdownMenuItem<String>(
                                        value: species,
                                        child: Text(
                                          species,
                                          style: GoogleFonts.nunito(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedFavoritePlant = val);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ── 6. Password Field ──
                              _buildFieldLabel('Password', '🔒'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                decoration: _inputDecoration(
                                  hint: 'Create a password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 18,
                                      color: const Color(0xFF388E3C),
                                    ),
                                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter a password';
                                  if (v.length < 4) return 'Password must be at least 4 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── 7. Confirm Password Field ──
                              _buildFieldLabel('Confirm Password', '🔐'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _confirmPassCtrl,
                                obscureText: _obscureConfirm,
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                decoration: _inputDecoration(
                                  hint: 'Repeat your password',
                                  icon: Icons.lock_reset_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 18,
                                      color: const Color(0xFF388E3C),
                                    ),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passCtrl.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                                    : FunBouncyButton(
                                        text: 'Create My Account 🌿',
                                        onPressed: _handleRegister,
                                        color: const Color(0xFF2E7D32),
                                        height: 48,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E4032),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: Text(
                              'Log In',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2E7D32),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(
        fontSize: 12.5,
        color: const Color(0xFF81C784),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF1F8EE),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}
