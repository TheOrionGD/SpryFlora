import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/app_version.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/fun_bouncy_button.dart';
import 'ai_eco_buddy_screen.dart';
import 'login_screen.dart';
import 'my_plants_screen.dart';
import '../widgets/app_background.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'my_certifications_screen.dart';
import 'profile_setup_screen.dart';
import 'garden_screen.dart';
import 'notification_center_screen.dart';
import 'reminders_screen.dart';
import 'help_faq_screen.dart';


/// Profile & Settings Screen — Fun childish redesign
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final PlantRepository _plantRepository = PlantRepository();

  UserProfile? _user;
  bool _soundEnabled = true;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _user = _userService.currentUser;
    _loadPreferences();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
    );
    _headerCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        _showAuthRequiredDialog();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool('spryflora_sound_enabled') ?? true;
      });
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: SkeuoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Sign In Required',
              style: SkeuoTheme.funHeading(size: 17, color: SkeuoTheme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Please log in to your SpryFlora account to access Profile & Settings and sync your plant data.',
          style: SkeuoTheme.funBody(size: 14, color: SkeuoTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            child: Text('Cancel',
                style: SkeuoTheme.funBody(
                    size: 14,
                    color: SkeuoTheme.textMuted,
                    weight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SkeuoTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sign In 🌿',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  int get _avgHealth {
    final plants = _plantRepository.plants;
    if (plants.isEmpty) return 0;
    return (plants.fold<int>(0, (sum, p) => sum + p.health) / plants.length)
        .round();
  }

  int get _duePlantCount =>
      _plantRepository.plants.where((p) => p.isWateringDue).length;

  @override
  Widget build(BuildContext context) {
    final name = _user?.childName.trim();
    final displayName = (name != null && name.isNotEmpty) ? name : 'Little Gardener';
    final levelName = _user?.experienceLevelName ?? 'Beginner';
    final userXp = _user?.xp ?? 120;
    final plantCount = _plantRepository.plants.length;
    final gardenScore = 500 + plantCount * 65 + userXp;
    final daysActive = _user?.createdAt != null
        ? DateTime.now().difference(_user!.createdAt).inDays + 1
        : 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: FadeTransition(
          opacity: _headerFade,
          child: Column(
            children: [
              // Top App Bar
              _buildAppBar(),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Hero (Screen 16)
                      _buildProfileHero(displayName, levelName, userXp, gardenScore),
                      const SizedBox(height: 20),

                      // 4 Stats Grid: Plants Grown | Need Water | Avg Health | Days Active
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              label: 'Plants Grown',
                              value: '$plantCount',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Need Water',
                              value: '$_duePlantCount',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Avg Health',
                              value: '$_avgHealth%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Days Active',
                              value: '$daysActive',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                    // Settings Group Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE5EBD8), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32)
                                .withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.edit_rounded,
                            title: 'Edit Profile',
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileSetupScreen()),
                              );
                              if (mounted) {
                                setState(() {
                                  _user = _userService.currentUser;
                                });
                              }
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.workspace_premium_rounded,
                            title: 'My Certifications',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MyCertificationsScreen()),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notification Center',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NotificationCenterScreen()),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.alarm_rounded,
                            title: 'Plant Care Reminders',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RemindersScreen()),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: _soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            title: 'Sound & Music',
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() {
                                _soundEnabled = !_soundEnabled;
                              });
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(
                                  'spryflora_sound_enabled', _soundEnabled);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(_soundEnabled
                                        ? '🎵 Sound effects enabled!'
                                        : '🔇 Sound effects muted'),
                                    backgroundColor: SkeuoTheme.primaryGreen,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & FAQ',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const HelpFaqScreen()),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.delete_forever_rounded,
                            title: 'Delete Account & Data (Web)',
                            titleColor: SkeuoTheme.alertRed,
                            onTap: _showDeleteAccountDialog,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F8EE)),
                          _buildSettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            titleColor: SkeuoTheme.alertRed,
                            onTap: _showSignOutDialog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reset / Clear Data Action Button using FunBouncyButton
                    SizedBox(
                      width: double.infinity,
                      child: FunBouncyButton(
                        text: '🗑️ Reset App Data',
                        onPressed: _showResetConfirm,
                        color: SkeuoTheme.alertRed,
                        height: 50,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Release Version Info
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE5EBD8), width: 1),
                        ),
                        child: Text(
                          'SpryFlora App ${AppVersion.fullVersion}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SkeuoTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
  bottomNavigationBar: BottomNavBar(
    currentIndex: 4,
    onTap: (index) {
      if (index == 4) return;
      switch (index) {
        case 0:
          Navigator.of(context).pop();
          break;
        case 1:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MyPlantsScreen()),
          );
          break;
        case 2:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AIEcoBuddyScreen()),
          );
          break;
        case 3:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const GardenScreen()),
          );
          break;
      }
    },
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
              'Profile & Settings',
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


  Widget _buildProfileHero(String displayName, String levelName, int userXp, int gardenScore) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC8E6C9), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: AppPhotoView(
              imagePath: _user?.profilePhotoPath,
              fit: BoxFit.cover,
              fallback: Image.asset(
                'assets/sprites/avatar_boy_hero.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: SkeuoTheme.primaryGreen,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: SkeuoTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
          ),
          child: Text(
            '🏆 $levelName Gardener  •  $userXp XP',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Favorite Plant: ${_user?.favoritePlant ?? "Tulsi"} 🌱',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SkeuoTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: SkeuoTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor ?? SkeuoTheme.textPrimary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: titleColor ?? SkeuoTheme.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: titleColor ?? SkeuoTheme.textMuted,
        size: 22,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }



  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SkeuoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('🚪 Sign Out',
            style: SkeuoTheme.funHeading(size: 18, color: SkeuoTheme.alertRed)),
        content: Text(
          'Are you sure you want to sign out of your SpryFlora account?',
          style: SkeuoTheme.funBody(size: 14, color: SkeuoTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: SkeuoTheme.funBody(
                    size: 14,
                    color: SkeuoTheme.primaryGreen,
                    weight: FontWeight.w800)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SkeuoTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SkeuoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('🗑️ Reset Everything?',
            style: SkeuoTheme.funHeading(size: 18, color: SkeuoTheme.alertRed)),
        content: Text(
          'This will delete all your plants, check-ins, and profile data. Are you sure?',
          style: SkeuoTheme.funBody(size: 14, color: SkeuoTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('No, Keep It! 🌿',
                style: SkeuoTheme.funBody(
                    size: 14,
                    color: SkeuoTheme.primaryGreen,
                    weight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              await _userService.clearUserData();
              nav.pop();
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text('App data reset! 🌱',
                      style: SkeuoTheme.funBody(size: 14, color: Colors.white)),
                  backgroundColor: SkeuoTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ));
              }
            },
            child: Text('Yes, Reset',
                style: SkeuoTheme.funBody(
                    size: 14,
                    color: SkeuoTheme.alertRed,
                    weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccountDeletionWebPage() async {
    final urlStr = ApiConfig.accountDeletionUrl;
    final uri = Uri.parse(urlStr);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch account deletion URL: $urlStr'),
            backgroundColor: SkeuoTheme.alertRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching deletion page: $e'),
            backgroundColor: SkeuoTheme.alertRed,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SkeuoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🗑️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account & Data',
                style: SkeuoTheme.funHeading(
                    size: 17, color: SkeuoTheme.alertRed),
              ),
            ),
          ],
        ),
        content: Text(
          'In accordance with Google Play Store policies, account deletion is processed via our secure web portal.\n\n'
          'You will be redirected to the SpryFlora server deletion page to verify your credentials and request permanent removal of your account, plant logs, and stored data.',
          style: SkeuoTheme.funBody(size: 13.5, color: SkeuoTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: SkeuoTheme.funBody(
                    size: 14,
                    color: SkeuoTheme.textMuted,
                    weight: FontWeight.w700)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SkeuoTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openAccountDeletionWebPage();
            },
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('Open Web Page',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
