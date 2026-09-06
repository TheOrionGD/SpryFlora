import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';

import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fun_bouncy_button.dart';

class WidgetConfigurationScreen extends StatefulWidget {
  final dynamic widgetId;

  const WidgetConfigurationScreen({
    super.key,
    required this.widgetId,
  });

  @override
  State<WidgetConfigurationScreen> createState() => _WidgetConfigurationScreenState();
}

class _WidgetConfigurationScreenState extends State<WidgetConfigurationScreen> {
  final PlantRepository _plantRepo = PlantRepository();
  final UserService _userService = UserService();

  String? _selectedPlantId; // null = Garden Overview
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _plantRepo.loadLocalData();
    await _userService.loadUserData();
    if (mounted) setState(() {});
  }

  PlantModel? get _selectedPlant {
    if (_selectedPlantId == null) return null;
    return _plantRepo.getPlantById(_selectedPlantId!);
  }

  void _saveAndFinishConfiguration() async {
    setState(() => _isSaving = true);
    try {
      final widgetId = widget.widgetId;
      final plant = _selectedPlant;
      final userName = _userService.currentUser?.childName ?? 'SpryFlora';

      if (plant != null) {
        final waterText = plant.isWateringDue
            ? '💧 Water Due Today!'
            : '💧 Water in ${plant.daysUntilWatering}d';
        final sunText = plant.isSunlightLoggedToday
            ? '☀️ ${plant.sunlightHoursToday}h Sun'
            : '☀️ Needs ${plant.targetSunlightHours}h Sun';

        await HomeWidget.saveWidgetData<String>('widget_plant_name.$widgetId', plant.plantName);
        await HomeWidget.saveWidgetData<String>('widget_plant_stage.$widgetId', '${plant.speciesName} • ${plant.growthStageName}');
        await HomeWidget.saveWidgetData<String>('widget_plant_health.$widgetId', '${plant.health}% (${plant.healthStatus})');
        await HomeWidget.saveWidgetData<String>('widget_water_status.$widgetId', waterText);
        await HomeWidget.saveWidgetData<String>('widget_sun_status.$widgetId', sunText);
      } else {
        final plants = _plantRepo.plants;
        if (plants.isEmpty) {
          await HomeWidget.saveWidgetData<String>('widget_plant_name.$widgetId', "$userName's Garden");
          await HomeWidget.saveWidgetData<String>('widget_plant_stage.$widgetId', 'No plants added yet');
          await HomeWidget.saveWidgetData<String>('widget_plant_health.$widgetId', 'Ready to Plant');
          await HomeWidget.saveWidgetData<String>('widget_water_status.$widgetId', '🌱 Tap to add plant');
          await HomeWidget.saveWidgetData<String>('widget_sun_status.$widgetId', '☀️ 0 Plants');
        } else {
          final sorted = List<PlantModel>.from(plants);
          sorted.sort((a, b) {
            if (a.isWateringDue && !b.isWateringDue) return -1;
            if (!a.isWateringDue && b.isWateringDue) return 1;
            return a.daysUntilWatering.compareTo(b.daysUntilWatering);
          });
          final topPlant = sorted.first;
          final waterText = topPlant.isWateringDue ? '💧 Water Due Today!' : '💧 Water in ${topPlant.daysUntilWatering}d';
          final sunText = topPlant.isSunlightLoggedToday ? '☀️ ${topPlant.sunlightHoursToday}h Sun' : '☀️ Needs ${topPlant.targetSunlightHours}h Sun';

          await HomeWidget.saveWidgetData<String>('widget_plant_name.$widgetId', topPlant.plantName);
          await HomeWidget.saveWidgetData<String>('widget_plant_stage.$widgetId', '${topPlant.speciesName} • ${topPlant.growthStageName}');
          await HomeWidget.saveWidgetData<String>('widget_plant_health.$widgetId', '${topPlant.health}% (${topPlant.healthStatus})');
          await HomeWidget.saveWidgetData<String>('widget_water_status.$widgetId', waterText);
          await HomeWidget.saveWidgetData<String>('widget_sun_status.$widgetId', sunText);
        }
      }

      await HomeWidget.updateWidget(
        name: 'FloraWidgetProvider',
        androidName: 'FloraWidgetProvider',
      );

      await HomeWidget.finishHomeWidgetConfigure();
    } catch (e) {
      debugPrint('Error finishing widget configuration: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = _plantRepo.plants;

    return Scaffold(
      backgroundColor: SkeuoTheme.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Card
                      _buildPreviewCard(),
                      const SizedBox(height: 24),

                      Text(
                        'Select Featured Plant for Widget',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Garden Overview Option
                      _buildSelectionTile(
                        id: null,
                        title: '🌿 Garden Overview (Auto Priority)',
                        subtitle: 'Displays plant needing water first',
                        isSelected: _selectedPlantId == null,
                      ),

                      // Plant Options
                      ...plants.map((p) => _buildSelectionTile(
                            id: p.id,
                            title: p.plantName,
                            subtitle: '${p.speciesName} • ${p.health}% Health',
                            isSelected: _selectedPlantId == p.id,
                          )),

                      const SizedBox(height: 32),

                      // Confirm & Finish Configuration Action Button
                      SizedBox(
                        width: double.infinity,
                        child: FunBouncyButton(
                          text: _isSaving ? 'Saving Configuration...' : 'Save & Finish Widget 🌿',
                          onPressed: () {
                            if (!_isSaving) _saveAndFinishConfiguration();
                          },
                          color: const Color(0xFF2E7D32),
                          height: 52,
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: SkeuoTheme.primaryGreen, size: 24),
          const SizedBox(width: 10),
          Text(
            'Configure Home Screen Widget',
            style: GoogleFonts.nunito(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: SkeuoTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final plant = _selectedPlant;
    final name = plant?.plantName ?? 'SpryFlora Garden';
    final stage = plant != null ? '${plant.speciesName} • ${plant.growthStageName}' : 'Garden Priority View';
    final health = plant != null ? '${plant.health}% Health' : '100% Health';
    final water = plant != null ? (plant.isWateringDue ? '💧 Water Due Today!' : '💧 Water in ${plant.daysUntilWatering}d') : '💧 Active Water Tracking';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'SpryFlora Widget',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1B4D3E)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFC8E6C9), borderRadius: BorderRadius.circular(8)),
                child: Text(health, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2E7D32))),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFD0E3D5)),
          Text(name, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: SkeuoTheme.textPrimary)),
          Text(stage, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF558B2F))),
          const SizedBox(height: 8),
          Text(water, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String? id,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlantId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF81C784) : const Color(0xFFEEEEEE),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: SkeuoTheme.textPrimary)),
                  Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: SkeuoTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
