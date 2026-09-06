import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/leaves_particle_overlay.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final PlantRepository _plantRepo = PlantRepository();

  bool _remindersEnabled = true;
  String _selectedTime = '08:00 AM';
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  final Map<String, bool> _plantReminderToggles = {};

  final List<String> _timeOptions = [
    '08:00 AM (Morning)',
    '12:00 PM (Noon)',
    '05:00 PM (Evening)',
    '08:00 PM (Night)',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('spryflora_reminders_enabled') ?? true;
    final time = prefs.getString('spryflora_reminder_time') ?? '08:00 AM (Morning)';
    final sound = prefs.getBool('spryflora_sound_enabled') ?? true;
    final vib = prefs.getBool('spryflora_vibration_enabled') ?? true;

    for (final plant in _plantRepo.plants) {
      _plantReminderToggles[plant.id] =
          prefs.getBool('spryflora_plant_reminder_${plant.id}') ?? true;
    }

    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _selectedTime = time;
        _soundEnabled = sound;
        _vibrationEnabled = vib;
      });
    }
  }

  Future<void> _saveBoolPref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveStringPref(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final plants = _plantRepo.plants;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LeavesParticleOverlay(
        maxThroughput: true,
        child: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master Reminder Switch Card
                        _buildMasterReminderCard(),
                        const SizedBox(height: 20),

                        // Daily Reminder Schedule Time Card
                        Text(
                          'Daily Care Schedule Time',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTimeSelectionCard(),

                        const SizedBox(height: 20),

                        // Per-Plant Reminder Settings
                        if (plants.isNotEmpty) ...[
                          Text(
                            'Individual Plant Care Toggles',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildPlantTogglesCard(),
                          const SizedBox(height: 20),
                        ],

                        // Sound & Vibration Settings Card
                        Text(
                          'Sound & Alert Feedback',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SkeuoTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSoundSettingsCard(),

                        const SizedBox(height: 24),

                        // Action Button: Test Reminder Notification
                        SizedBox(
                          width: double.infinity,
                          child: FunBouncyButton(
                            text: '🔔 Test Plant Care Alert',
                            onPressed: () {
                              NotificationService().sendSystemNotification(
                                title: '🌿 Time to Water Your Plants!',
                                body:
                                    'Daily care reminder is active for $_selectedTime. Don\'t forget to check your green friends!',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '🔔 Care reminder alert posted to device!'),
                                  backgroundColor: SkeuoTheme.primaryGreen,
                                ),
                              );
                            },
                            color: const Color(0xFF2E7D32),
                            height: 50,
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
            'Plant Care Reminders',
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

  Widget _buildMasterReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _remindersEnabled
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
              color: _remindersEnabled
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _remindersEnabled
                  ? Icons.alarm_on_rounded
                  : Icons.alarm_off_rounded,
              color: _remindersEnabled
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
                  'Daily Plant Reminders',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                Text(
                  _remindersEnabled
                      ? 'Scheduled daily at $_selectedTime'
                      : 'All care reminders turned off',
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
            value: _remindersEnabled,
            activeTrackColor: const Color(0xFF81C784),
                  activeThumbColor: const Color(0xFF4CAF50),
            onChanged: (val) async {
              setState(() => _remindersEnabled = val);
              await _saveBoolPref('spryflora_reminders_enabled', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: _timeOptions.map((timeOption) {
          final isSelected = _selectedTime == timeOption;
          return GestureDetector(
            onTap: _remindersEnabled
                ? () async {
                    setState(() => _selectedTime = timeOption);
                    await _saveStringPref('spryflora_reminder_time', timeOption);
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF81C784)
                      : const Color(0xFFEEEEEE),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    timeOption,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : SkeuoTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlantTogglesCard() {
    final plants = _plantRepo.plants;

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
        children: plants.map((plant) {
          final isToggled = _plantReminderToggles[plant.id] ?? true;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_florist_rounded,
                        color: Color(0xFF4CAF50), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.plantName,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: SkeuoTheme.textPrimary,
                            ),
                          ),
                          Text(
                            plant.speciesName,
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
                      value: _remindersEnabled && isToggled,
                      activeTrackColor: const Color(0xFF81C784),
                  activeThumbColor: const Color(0xFF4CAF50),
                      onChanged: _remindersEnabled
                          ? (val) async {
                              setState(() {
                                _plantReminderToggles[plant.id] = val;
                              });
                              await _saveBoolPref(
                                  'spryflora_plant_reminder_${plant.id}', val);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              if (plant != plants.last)
                const Divider(height: 1, color: Color(0xFFF1F8EE)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundSettingsCard() {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notification Sound',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SkeuoTheme.textPrimary,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _soundEnabled,
                  activeTrackColor: const Color(0xFF81C784),
                  activeThumbColor: const Color(0xFF4CAF50),
                  onChanged: (val) async {
                    setState(() => _soundEnabled = val);
                    await _saveBoolPref('spryflora_sound_enabled', val);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F8EE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.vibration_rounded,
                    color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Device Haptic Vibration',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SkeuoTheme.textPrimary,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _vibrationEnabled,
                  activeTrackColor: const Color(0xFF81C784),
                  activeThumbColor: const Color(0xFF4CAF50),
                  onChanged: (val) async {
                    setState(() => _vibrationEnabled = val);
                    await _saveBoolPref('spryflora_vibration_enabled', val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
