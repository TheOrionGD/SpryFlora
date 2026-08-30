import 'dart:math' as math;
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';

/// Result of a comprehensive botanical plant health calculation
class PlantHealthReport {
  final int overallHealth; // 0 to 100
  final int hydrationScore; // 0 to 100
  final int sunlightScore; // 0 to 100
  final int consistencyScore; // 0 to 100
  final String status; // 'Thriving', 'Optimal', 'Needs Sunlight', 'Under-watered', 'Stressed'
  final String summaryMessage;
  final List<String> warnings;
  final List<String> recommendations;

  const PlantHealthReport({
    required this.overallHealth,
    required this.hydrationScore,
    required this.sunlightScore,
    required this.consistencyScore,
    required this.status,
    required this.summaryMessage,
    required this.warnings,
    required this.recommendations,
  });
}

/// Botanical Multi-Factor Plant Health Monitoring Engine
/// Evaluates:
/// 1. Hydration & Soil Moisture (40%)
/// 2. Sunlight & Photoperiod Exposure (35%)
/// 3. Care Consistency & Daily Streak (15%)
/// 4. Growth Progression Stability (10%)
class PlantHealthEngine {
  static const double hydrationWeight = 0.40;
  static const double sunlightWeight = 0.35;
  static const double consistencyWeight = 0.15;
  static const double progressionWeight = 0.10;

  /// Calculate a comprehensive health report for a given plant and its history
  static PlantHealthReport evaluate({
    required PlantModel plant,
    List<DailyCheckinModel> checkins = const [],
    int? currentCheckinSunlight,
    bool? currentCheckinWatered,
  }) {
    // 1. Calculate Hydration Score (0 - 100)
    int hydration = plant.hydrationScore;
    final int daysUntilWatering = plant.daysUntilWatering;
    
    if (currentCheckinWatered != null) {
      if (currentCheckinWatered) {
        hydration = (hydration + 15).clamp(80, 100);
      } else if (plant.isWateringDue) {
        hydration = (hydration - 10).clamp(20, 100);
      }
    } else {
      if (daysUntilWatering < 0) {
        // Overdue penalty: -8 pts per overdue day
        final overduePenalty = (-daysUntilWatering) * 8;
        hydration = (100 - overduePenalty).clamp(20, 100);
      } else if (daysUntilWatering == 0) {
        hydration = math.min(hydration, 88);
      } else {
        hydration = (hydration + 2).clamp(70, 100);
      }
    }

    // 2. Calculate Sunlight Score (0 - 100)
    int sunlight = plant.sunlightScore;
    final targetSun = plant.targetSunlightHours > 0 ? plant.targetSunlightHours : 4;
    final int loggedSun = currentCheckinSunlight ?? plant.sunlightHoursToday;
    
    if (loggedSun > 0) {
      final ratio = (loggedSun / targetSun).clamp(0.0, 1.3);
      if (ratio >= 0.8 && ratio <= 1.2) {
        sunlight = 100;
      } else if (ratio < 0.8) {
        sunlight = ((ratio / 0.8) * 80).round().clamp(30, 80);
      } else {
        // Slight excess sunlight penalty for shade-loving plants
        sunlight = 92;
      }
    } else {
      // Not logged yet today
      if (plant.isSunlightLoggedToday) {
        sunlight = 95;
      } else {
        sunlight = math.max(60, sunlight - 5);
      }
    }

    // 3. Calculate Care Consistency Score (0 - 100)
    int consistency = 85;
    if (checkins.isNotEmpty) {
      final recentCheckins = checkins.take(7).toList();
      final wateredDays = recentCheckins.where((c) => c.watered).length;
      final sunDays = recentCheckins.where((c) => c.sunlightHours > 0).length;
      final consistencyRatio = (wateredDays + sunDays) / (recentCheckins.length * 2);
      consistency = (consistencyRatio * 100).round().clamp(40, 100);
    }

    // 4. Calculate Growth Progression Stability (0 - 100)
    int progression = 95;
    if (plant.isCompleted) {
      progression = 100;
    } else if (plant.ageInDays > 0) {
      progression = 90;
    }

    // Weighted Overall Health Score (0 - 100)
    final double rawScore = (hydration * hydrationWeight) +
        (sunlight * sunlightWeight) +
        (consistency * consistencyWeight) +
        (progression * progressionWeight);
    final int overallHealth = rawScore.round().clamp(0, 100);

    // Determine Status
    String status = 'Optimal';
    final List<String> warnings = [];
    final List<String> recommendations = [];

    if (hydration < 55) {
      status = 'Under-watered';
      warnings.add('💧 Soil moisture is critically low. Watering is urgently required.');
      recommendations.add('Give ${plant.plantName} a thorough soaking until water drains.');
    } else if (sunlight < 55) {
      status = 'Needs Sunlight';
      warnings.add('☀️ Insufficient light exposure. Photosynthesis rate has dropped.');
      recommendations.add('Move ${plant.plantName} to a brighter spot for at least $targetSun hrs/day.');
    } else if (overallHealth >= 90) {
      status = 'Thriving';
      recommendations.add('Growth is peak! Continue current watering and lighting routine.');
    } else if (overallHealth >= 75) {
      status = 'Optimal';
      recommendations.add('Maintain steady sunlight and monitor watering schedule.');
    } else {
      status = 'Stressed';
      warnings.add('⚠️ Plant shows multiple stress indicators across water and light.');
      recommendations.add('Check soil moisture and ensure adequate indirect sunlight.');
    }

    String summaryMessage;
    switch (status) {
      case 'Thriving':
        summaryMessage = '🌟 ${plant.plantName} is thriving with optimal hydration and sunlight!';
        break;
      case 'Optimal':
        summaryMessage = '🌿 Healthy and steadily progressing through the ${plant.growthStageName} stage.';
        break;
      case 'Needs Sunlight':
        summaryMessage = '☀️ Sunlight level is below target ($targetSun hrs needed).';
        break;
      case 'Under-watered':
        summaryMessage = '💧 Dehydration risk: watering is overdue.';
        break;
      default:
        summaryMessage = '⚠️ Multi-factor botanical stress detected. Review care routine.';
    }

    return PlantHealthReport(
      overallHealth: overallHealth,
      hydrationScore: hydration,
      sunlightScore: sunlight,
      consistencyScore: consistency,
      status: status,
      summaryMessage: summaryMessage,
      warnings: warnings,
      recommendations: recommendations,
    );
  }
}
