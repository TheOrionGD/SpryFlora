import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final PlantRepository _plantRepo = PlantRepository();
  bool _masterNotifications = true;
  bool _wateringAlerts = true;
  bool _sunlightAlerts = true;
  bool _mascotAlerts = true;
  bool _certificateAlerts = true;

  List<_NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _generateNotificationFeed();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _masterNotifications =
            prefs.getBool('spryflora_reminders_enabled') ?? true;
        _wateringAlerts = prefs.getBool('spryflora_watering_alerts') ?? true;
        _sunlightAlerts = prefs.getBool('spryflora_sunlight_alerts') ?? true;
        _mascotAlerts = prefs.getBool('spryflora_mascot_alerts') ?? true;
        _certificateAlerts =
            prefs.getBool('spryflora_certificate_alerts') ?? true;
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _generateNotificationFeed() {
    final plants = _plantRepo.plants;
    final List<_NotificationItem> items = [];

    // Due plants notification
    final duePlants = plants.where((p) => p.isWateringDue).toList();
    if (duePlants.isNotEmpty) {
      items.add(
        _NotificationItem(
          id: '1',
          title: '💧 Hydration Needed!',
          body:
              '${duePlants.length} plant${duePlants.length > 1 ? 's' : ''} (${duePlants.map((p) => p.plantName).join(', ')}) need water today.',
          time: 'Just now',
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF03A9F4),
          bgColor: const Color(0xFFE1F5FE),
        ),
      );
    }

    // Health alert
    final healthyPlants = plants.where((p) => p.health >= 80).toList();
    if (healthyPlants.isNotEmpty) {
      items.add(
        _NotificationItem(
          id: '2',
          title: '🌟 Garden Thriving!',
          body:
              'Your garden is in excellent condition with ${healthyPlants.length} healthy plants.',
          time: '2 hours ago',
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF4CAF50),
          bgColor: const Color(0xFFE8F5E9),
        ),
      );
    }

    // Daily check-in reminder
    items.add(
      _NotificationItem(
        id: '3',
        title: '☀️ Daily Sunshine Check',
        body: 'Don\'t forget to log sunlight exposure for your plants today!',
        time: 'Today, 9:00 AM',
        icon: Icons.wb_sunny_rounded,
        iconColor: const Color(0xFFFFA000),
        bgColor: const Color(0xFFFFF8E1),
      ),
    );

    // Mascot achievement notification
    items.add(
      _NotificationItem(
        id: '4',
        title: '🌱 Mascot Companion Level Up',
        body:
            'Your sprout mascot has grown! Keep up the good plant care to unlock new stages.',
        time: 'Yesterday',
        icon: Icons.workspace_premium_rounded,
        iconColor: const Color(0xFF9C27B0),
        bgColor: const Color(0xFFF3E5F5),
      ),
    );

    setState(() {
      _notifications = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildAppBar(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master Switch Card
                        _buildMasterSwitchCard(),

                        const SizedBox(height: 20),

                        // Notification Category Settings Card
                        Text(
                          'Notification Controls',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryControlsCard(),

                        const SizedBox(height: 24),

                        // Recent Notification Feed Header
                        Row(
                          children: [
                            Text(
                              'Recent Alerts & Updates',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: SkeuoTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (_notifications.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _notifications.clear());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cleared all alerts!'),
                                      backgroundColor: SkeuoTheme.primaryGreen,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: SkeuoTheme.alertRed,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Notification Feed List
                        if (_notifications.isEmpty)
                          _buildEmptyNotificationsCard()
                        else
                          ..._notifications.map(_buildNotificationTile),

                        const SizedBox(height: 24),

                        // Send Test Notification CTA
                        SizedBox(
                          width: double.infinity,
                          child: FunBouncyButton(
                            text: '🔔 Send Test System Alert',
                            onPressed: () {
                              NotificationService().sendSystemNotification(
                                title: '🌱 SpryFlora Test Notification',
                                body:
                                    'Notification system is active and working properly!',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '🔔 System notification posted to device!'),
                                  backgroundColor: SkeuoTheme.primaryGreen,
                                ),
                              );
                            },
                            color: const Color(0xFF2E7D32),
                            height: 48,
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: SkeuoTheme.textPrimary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notification Center',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: SkeuoTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSwitchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _masterNotifications
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _masterNotifications
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _masterNotifications
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _masterNotifications
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allow Notifications',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                Text(
                  _masterNotifications
                      ? 'System & care alerts active'
                      : 'All notifications muted',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _masterNotifications,
            activeTrackColor: const Color(0xFF81C784),
            activeThumbColor: const Color(0xFF4CAF50),
            onChanged: (val) async {
              setState(() => _masterNotifications = val);
              await _savePreference('spryflora_reminders_enabled', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryControlsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF03A9F4),
            title: 'Watering Reminders',
            subtitle: 'Alert when plants need hydration',
            value: _wateringAlerts,
            onChanged: (val) {
              setState(() => _wateringAlerts = val);
              _savePreference('spryflora_watering_alerts', val);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F8EE)),
          _buildToggleRow(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFFA000),
            title: 'Sunlight Care Alerts',
            subtitle: 'Remind to check daily sunlight',
            value: _sunlightAlerts,
            onChanged: (val) {
              setState(() => _sunlightAlerts = val);
              _savePreference('spryflora_sunlight_alerts', val);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F8EE)),
          _buildToggleRow(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: 'Mascot Level-Up Milestones',
            subtitle: 'Celebrate mascot growth & XP',
            value: _mascotAlerts,
            onChanged: (val) {
              setState(() => _mascotAlerts = val);
              _savePreference('spryflora_mascot_alerts', val);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F8EE)),
          _buildToggleRow(
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFE74C3C),
            title: 'Certification Trophies',
            subtitle: 'Notify on master planter achievements',
            value: _certificateAlerts,
            onChanged: (val) {
              setState(() => _certificateAlerts = val);
              _savePreference('spryflora_certificate_alerts', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _masterNotifications && value,
            activeTrackColor: const Color(0xFF81C784),
            activeThumbColor: const Color(0xFF4CAF50),
            onChanged: _masterNotifications ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(_NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      item.time,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SkeuoTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotificationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 48, color: Color(0xFF81C784)),
          const SizedBox(height: 12),
          Text(
            'All Caught Up! 🌿',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You have no unread notifications or care alerts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
