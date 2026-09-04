import { Plant } from '../models/Plant.js';
import { SpeciesService } from './species.service.js';
import { XPService } from './xp.service.js';
import { ERROR_CODES, LIFECYCLE_STAGES } from '../constants/index.js';

export class PlantService {
  static calculateGrowthTelemetry(plant) {
    const plantedAt = plant.plantedAt ? new Date(plant.plantedAt) : new Date(plant.createdAt);
    const now = new Date();

    const cleanNow = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const cleanPlanted = new Date(plantedAt.getFullYear(), plantedAt.getMonth(), plantedAt.getDate());

    const diffDays = Math.max(0, Math.floor((cleanNow - cleanPlanted) / (1000 * 60 * 60 * 24)));
    const lifespanDays = plant.lifespanDays || plant.growthDurationDays || 150;

    const growthProgress = Math.min(1.0, Math.max(0.0, diffDays / lifespanDays));

    const initialHeight = plant.initialHeightCm || 2.0;
    const matureHeight = plant.matureHeightCm || 50.0;
    const healthMultiplier = Math.min(1.0, Math.max(0.5, (plant.health || 95) / 100.0));

    const currentHeightCm = parseFloat(
      (initialHeight + (matureHeight - initialHeight) * growthProgress * healthMultiplier).toFixed(1)
    );

    let lifecycleStage = LIFECYCLE_STAGES.SEED;
    if (growthProgress >= 0.90) {
      lifecycleStage = LIFECYCLE_STAGES.FULLY_GROWN;
    } else if (growthProgress >= 0.50) {
      lifecycleStage = LIFECYCLE_STAGES.GROWING;
    } else if (growthProgress >= 0.20) {
      lifecycleStage = LIFECYCLE_STAGES.SPROUT;
    }

    const isCompleted = plant.isCompletedManually || diffDays >= lifespanDays || growthProgress >= 1.0;

    return {
      ageInDays: diffDays,
      growthProgress,
      currentHeightCm: Math.min(matureHeight, currentHeightCm),
      lifecycleStage,
      isCompleted,
    };
  }

  static async createPlant(userId, plantData) {
    const speciesName = plantData.speciesName || plantData.commonName || 'Tulsi';
    const species = await SpeciesService.findOrCreateSpecies(speciesName, plantData);

    const plantedAt = plantData.plantingDate || plantData.plantedAt || new Date();
    const wateringIntervalDays = species.wateringIntervalDays || plantData.wateringIntervalDays || 3;
    const nextWateringAt = new Date(new Date(plantedAt).getTime() + wateringIntervalDays * 24 * 60 * 60 * 1000);

    const plant = new Plant({
      userId,
      clientPlantId: plantData.id || plantData.clientPlantId || `plant_${Date.now()}`,
      plantName: plantData.plantName || species.commonName,
      speciesName: species.commonName,
      speciesId: species.speciesId,
      commonName: species.commonName,
      botanicalName: species.botanicalName,
      imageUrl: plantData.imageUrl || plantData.initialPhotoPath || species.image,
      initialPhotoPath: plantData.initialPhotoPath || null,
      location: plantData.location || 'Living Room',
      plantedAt,
      plantingDate: plantedAt,
      lifespanDays: species.growthDurationDays,
      growthDurationDays: species.growthDurationDays,
      wateringIntervalDays,
      targetSunlightHours: species.targetSunlightHours || plantData.targetSunlightHours || 4,
      initialHeightCm: species.initialHeightCm,
      matureHeightCm: species.matureHeightCm,
      currentHeightCm: species.initialHeightCm,
      lastWateredAt: plantedAt,
      lastWateredDate: plantedAt,
      nextWateringAt,
      nextWateringDate: nextWateringAt,
      health: plantData.health || 95,
      healthScore: plantData.health || 95,
      hydrationScore: plantData.hydrationScore || 95,
      sunlightScore: plantData.sunlightScore || 95,
      consistencyScore: plantData.consistencyScore || 95,
      healthStatus: plantData.healthStatus || 'Optimal',
    });

    const telemetry = this.calculateGrowthTelemetry(plant);
    plant.growthProgress = telemetry.growthProgress;
    plant.currentHeightCm = telemetry.currentHeightCm;
    plant.lifecycleStage = telemetry.lifecycleStage;
    plant.isCompleted = telemetry.isCompleted;

    await plant.save();

    // Server-side reward logic: Award +50 XP for planting
    await XPService.awardXP(userId, XPService.getPlantingXP());

    return plant.toJSON();
  }

  static async getUserPlants(userId) {
    const plants = await Plant.find({ userId }).sort({ createdAt: -1 });
    return plants.map((p) => {
      const telemetry = this.calculateGrowthTelemetry(p);
      const obj = p.toJSON();
      obj.growthProgress = telemetry.growthProgress;
      obj.currentHeightCm = telemetry.currentHeightCm;
      obj.lifecycleStage = telemetry.lifecycleStage;
      obj.isCompleted = telemetry.isCompleted;
      return obj;
    });
  }

  static async getPlantById(userId, plantId) {
    let plant = await Plant.findOne({ userId, _id: plantId }).catch(() => null);
    if (!plant) {
      plant = await Plant.findOne({ userId, clientPlantId: plantId });
    }

    if (!plant) {
      // Security P0 check: Check if plant exists under a different user ID to throw 403 Forbidden vs 404 Not Found
      const otherUserPlant = await Plant.findOne({
        $or: [{ _id: plantId }, { clientPlantId: plantId }],
      }).catch(() => null);

      if (otherUserPlant) {
        const err = new Error('Forbidden: You do not own this plant resource.');
        err.statusCode = 403;
        err.code = ERROR_CODES.FORBIDDEN;
        throw err;
      }

      const err = new Error('Plant not found.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }

    const telemetry = this.calculateGrowthTelemetry(plant);
    const obj = plant.toJSON();
    obj.growthProgress = telemetry.growthProgress;
    obj.currentHeightCm = telemetry.currentHeightCm;
    obj.lifecycleStage = telemetry.lifecycleStage;
    obj.isCompleted = telemetry.isCompleted;
    return obj;
  }

  static async updatePlant(userId, plantId, updateData) {
    // Perform ownership verification first
    await this.getPlantById(userId, plantId);

    let plant = await Plant.findOne({ userId, _id: plantId }).catch(() => null);
    if (!plant) {
      plant = await Plant.findOne({ userId, clientPlantId: plantId });
    }

    // Ignore client attempts to arbitrarily force species parameters
    const safeUpdatable = [
      'plantName',
      'location',
      'initialPhotoPath',
      'isCompletedManually',
      'health',
      'hydrationScore',
      'sunlightScore',
      'consistencyScore',
      'healthStatus',
      'sunlightHoursToday',
    ];

    for (const key of safeUpdatable) {
      if (updateData[key] !== undefined) {
        plant[key] = updateData[key];
        if (key === 'health') plant.healthScore = updateData[key];
        if (key === 'isCompletedManually') plant.isCompleted = updateData[key];
      }
    }

    plant.version += 1;
    await plant.save();

    const telemetry = this.calculateGrowthTelemetry(plant);
    const obj = plant.toJSON();
    obj.growthProgress = telemetry.growthProgress;
    obj.currentHeightCm = telemetry.currentHeightCm;
    obj.lifecycleStage = telemetry.lifecycleStage;
    obj.isCompleted = telemetry.isCompleted;
    return obj;
  }

  static async deletePlant(userId, plantId) {
    await this.getPlantById(userId, plantId); // Enforce ownership

    let res = await Plant.deleteOne({ userId, _id: plantId }).catch(() => null);
    if (!res || res.deletedCount === 0) {
      await Plant.deleteOne({ userId, clientPlantId: plantId });
    }
    return { success: true };
  }
}
