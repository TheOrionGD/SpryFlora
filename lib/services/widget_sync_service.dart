import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/plant_model.dart';
import '../models/user_model.dart';
import 'plant_repository.dart';
import 'user_service.dart';

/// Service to synchronize SpryFlora live plant metrics to Phone Home Screen Widgets
class WidgetSyncService {
  static final WidgetSyncService _instance = WidgetSyncService._internal();
  factory WidgetSyncService() => _instance;
  WidgetSyncService._internal();

  static const String _androidWidgetName = 'FloraWidgetProvider';

  /// Syncs current garden state to phone home screen widget
  Future<void> updateWidgetData({
    List<PlantModel>? plantsList,
    UserProfile? userProfile,
  }) async {
    // Only supported on Android & iOS mobile environments
    if (kIsWeb) return;

    try {
      final plants = plantsList ?? PlantRepository().plants;
      final user = userProfile ?? UserService().currentUser;
      final userName = user?.childName.isNotEmpty == true ? user!.childName : 'SpryFlora';

      await HomeWidget.saveWidgetData<String>('widget_user_name', userName);

      if (plants.isEmpty) {
        // Empty garden state
        await HomeWidget.saveWidgetData<String>('widget_plant_name', "$userName's Garden");
        await HomeWidget.saveWidgetData<String>('widget_plant_stage', 'No plants added yet');
        await HomeWidget.saveWidgetData<String>('widget_plant_health', 'Ready to Plant');
        await HomeWidget.saveWidgetData<String>('widget_water_status', '🌱 Tap to add plant');
        await HomeWidget.saveWidgetData<String>('widget_sun_status', '☀️ 0 Plants');
      } else {
        // Find priority plant: overdue first, then due today, then first in garden
        final sorted = List<PlantModel>.from(plants);
        sorted.sort((a, b) {
          if (a.isWateringDue && !b.isWateringDue) return -1;
          if (!a.isWateringDue && b.isWateringDue) return 1;
          return a.daysUntilWatering.compareTo(b.daysUntilWatering);
        });

        final topPlant = sorted.first;
        final waterText = topPlant.isWateringDue
            ? '💧 Water Due Today!'
            : '💧 Water in ${topPlant.daysUntilWatering}d';

        final sunText = topPlant.isSunlightLoggedToday
            ? '☀️ ${topPlant.sunlightHoursToday}h Sun'
            : '☀️ Needs ${topPlant.targetSunlightHours}h Sun';

        await HomeWidget.saveWidgetData<String>('widget_plant_name', topPlant.plantName);
        await HomeWidget.saveWidgetData<String>(
          'widget_plant_stage',
          '${topPlant.speciesName} • ${topPlant.growthStageName}',
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_plant_health',
          '${topPlant.health}% (${topPlant.healthStatus})',
        );
        await HomeWidget.saveWidgetData<String>('widget_water_status', waterText);
        await HomeWidget.saveWidgetData<String>('widget_sun_status', sunText);
      }

      // Trigger Home Screen Widget refresh
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        // Silently skip on test environments or platforms missing home_widget plugin
        return;
      }
      debugPrint('Error updating home screen widget: $e');
    }
  }
}
