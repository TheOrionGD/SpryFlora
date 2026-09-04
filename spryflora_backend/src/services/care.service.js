import { CareEvent } from '../models/CareEvent.js';
import { PlantService } from './plant.service.js';
import { XPService } from './xp.service.js';
import { StreakService } from './streak.service.js';
import { AIService } from './ai/ai.service.js';
import { generateClientOpId } from '../utils/ids.js';
import { ERROR_CODES } from '../constants/index.js';

export class CareService {
  static async waterPlant(userId, plantId, body = {}) {
    // 1. Verify ownership
    const plant = await PlantService.getPlantById(userId, plantId);

    const clientOperationId = body.clientOperationId || body.operationId || generateClientOpId('water');

    // 2. Idempotency Check: Idempotency protection against retries & replayed requests
    const existingEvent = await CareEvent.findOne({ clientOperationId });
    if (existingEvent) {
      console.log(`[CareService] Idempotent hit for operationId: ${clientOperationId}`);
      return {
        careEvent: existingEvent.toJSON(),
        plant,
        isDuplicate: true,
      };
    }

    // 3. Prevent duplicate same-day watering care events for the same plant
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const sameDayEvent = await CareEvent.findOne({
      userId,
      plantId: plant._id || plant.id,
      type: 'WATERING',
      timestamp: { $gte: startOfToday, $lte: endOfToday },
    });

    if (sameDayEvent) {
      // Return existing plant state without double-rewarding XP/streak
      return {
        careEvent: sameDayEvent.toJSON(),
        plant,
        isDuplicate: true,
        message: 'Watering already recorded for today.',
      };
    }

    // 4. Verification Flow if photo evidence supplied
    let verificationStatus = 'VERIFIED';
    let aiDiagnosis = body.aiDiagnosis || null;
    let photoPath = body.photoPath || body.evidenceImageReference || null;

    if (photoPath) {
      const aiResult = await AIService.verifyWateringPhoto({ plant, image: photoPath });
      if (!aiResult.isVerified) {
        const err = new Error(aiResult.rejectionReason || 'Watering photo verification failed.');
        err.statusCode = 422;
        err.code = ERROR_CODES.UNPROCESSABLE;
        throw err;
      }
      aiDiagnosis = aiResult.message;
      verificationStatus = 'VERIFIED';
    }

    // 5. Create Care Event
    const careEvent = await CareEvent.create({
      clientOperationId,
      userId,
      plantId: plant._id || plant.id,
      type: 'WATERING',
      watered: true,
      verificationStatus,
      evidenceImageReference: photoPath,
      photoPath,
      aiDiagnosis,
      xpEarned: XPService.getWateringXP(),
      timestamp: new Date(),
    });

    // 6. Server-authoritative rewards: Award +25 XP and Update Care Streak
    const earnedXp = await XPService.awardXP(userId, XPService.getWateringXP());
    const currentStreak = await StreakService.updateCareStreak(userId);

    // 7. Update Plant Watering Telemetry
    const now = new Date();
    const wateringIntervalDays = plant.wateringIntervalDays || 3;
    const nextWateringAt = new Date(now.getTime() + wateringIntervalDays * 24 * 60 * 60 * 1000);

    const updatedPlant = await PlantService.updatePlant(userId, plantId, {
      lastWateredDate: now,
      nextWateringDate: nextWateringAt,
      health: Math.min(100, (plant.health || 95) + 5),
      hydrationScore: 100,
    });

    return {
      careEvent: careEvent.toJSON(),
      plant: updatedPlant,
      xp: earnedXp,
      careStreakDays: currentStreak,
      isDuplicate: false,
    };
  }

  static async getPlantCareHistory(userId, plantId) {
    await PlantService.getPlantById(userId, plantId); // Enforce ownership
    const events = await CareEvent.find({ userId, plantId }).sort({ timestamp: -1 });
    return events;
  }
}
