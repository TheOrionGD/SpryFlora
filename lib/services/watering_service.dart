import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import 'plant_repository.dart';
import 'plant_health_engine.dart';
import 'ai_service.dart';

/// Comprehensive Plant Care & Daily Check-in Service
/// Handles Watering, Sunlight exposure logging, Multi-Factor Health calculation, and AI Diagnostics.
class WateringService {
  static final WateringService _instance = WateringService._internal();
  factory WateringService() => _instance;
  WateringService._internal();

  final PlantRepository _repository = PlantRepository();
  final AIService _aiService = AIService();

  /// Process Daily Check-in submission with full care telemetry
  Future<PlantModel> processCheckin({
    required PlantModel plant,
    required bool watered,
    int sunlightHours = 4,
    String environmentCondition = 'Bright Indirect',
    String? photoPath,
    String? notes,
  }) async {
    final now = DateTime.now();
    final existingCheckins = _repository.getCheckinsForPlant(plant.id);

    // Prevent duplicate care events / XP farming within the same day for the same plant
    final isAlreadyCheckedInToday = existingCheckins.any((c) {
      return c.checkinDate.year == now.year &&
          c.checkinDate.month == now.month &&
          c.checkinDate.day == now.day &&
          c.watered == watered;
    });

    if (isAlreadyCheckedInToday) {
      debugPrint('ℹ Duplicate care event ignored for plant ${plant.id} today.');
      return plant;
    }

    // 1. Generate AI Diagnosis for this check-in
    final aiDiagnosis = await _aiService.analyzeCheckinAndPhoto(
      plant: plant,
      watered: watered,
      sunlightHours: sunlightHours,
      environmentCondition: environmentCondition,
      photoPath: photoPath,
    );

    // 2. Record daily check-in model
    final checkin = DailyCheckinModel(
      id: 'checkin_${plant.id}_${now.year}${now.month}${now.day}_${now.millisecondsSinceEpoch}',
      plantId: plant.id,
      checkinDate: now,
      watered: watered,
      sunlightHours: sunlightHours,
      environmentCondition: environmentCondition,
      photoPath: photoPath,
      notes: notes,
      aiDiagnosis: aiDiagnosis,
      createdAt: now,
    );
    await _repository.addCheckin(checkin);

    // 3. Compute Multi-Factor Health using PlantHealthEngine
    final updatedCheckins = _repository.getCheckinsForPlant(plant.id);
    final healthReport = PlantHealthEngine.evaluate(
      plant: plant,
      checkins: updatedCheckins,
      currentCheckinSunlight: sunlightHours,
      currentCheckinWatered: watered,
    );

    // 4. Update Plant Model
    DateTime newLastWatered = plant.lastWateredDate;
    DateTime newNextWatering = plant.nextWateringDate;

    if (watered) {
      newLastWatered = now;
      newNextWatering = now.add(Duration(days: plant.wateringIntervalDays));
    }

    final updatedPlant = plant.copyWith(
      lastWateredDate: newLastWatered,
      nextWateringDate: newNextWatering,
      sunlightHoursToday: sunlightHours,
      lastSunlightDate: now,
      health: healthReport.overallHealth,
      hydrationScore: healthReport.hydrationScore,
      sunlightScore: healthReport.sunlightScore,
      consistencyScore: healthReport.consistencyScore,
      healthStatus: healthReport.status,
      updatedAt: now,
    );

    await _repository.updatePlant(updatedPlant);
    return updatedPlant;
  }

  /// Quick action to log sunlight separately
  Future<PlantModel> logSunlight({
    required PlantModel plant,
    required int hours,
    String environmentCondition = 'Bright Indirect',
  }) async {
    final now = DateTime.now();
    final existingCheckins = _repository.getCheckinsForPlant(plant.id);
    
    final healthReport = PlantHealthEngine.evaluate(
      plant: plant,
      checkins: existingCheckins,
      currentCheckinSunlight: hours,
    );

    final updatedPlant = plant.copyWith(
      sunlightHoursToday: hours,
      lastSunlightDate: now,
      health: healthReport.overallHealth,
      sunlightScore: healthReport.sunlightScore,
      healthStatus: healthReport.status,
      updatedAt: now,
    );

    await _repository.updatePlant(updatedPlant);
    return updatedPlant;
  }

  /// Calculates next watering date for a new plant
  static DateTime calculateInitialNextWatering(DateTime plantingDate, int intervalDays) {
    return plantingDate.add(Duration(days: intervalDays));
  }
}
