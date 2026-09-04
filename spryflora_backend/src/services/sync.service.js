import { PlantService } from './plant.service.js';
import { CareEvent } from '../models/CareEvent.js';
import { UserService } from './user.service.js';
import { SyncOperation } from '../models/SyncOperation.js';
import { generateClientOpId } from '../utils/ids.js';

export class SyncService {
  static async syncPlants(userId, localPlants = []) {
    const processed = [];

    for (const localPlant of localPlants) {
      const clientPlantId = localPlant.id || localPlant.clientPlantId;
      if (!clientPlantId) continue;

      const opId = `sync_plant_${clientPlantId}_${localPlant.updatedAt || Date.now()}`;
      const existingOp = await SyncOperation.findOne({ clientOperationId: opId });

      if (existingOp) {
        continue; // Skip duplicate operation
      }

      try {
        let plant = await PlantService.getPlantById(userId, clientPlantId).catch(() => null);
        if (!plant) {
          // Create plant on backend
          plant = await PlantService.createPlant(userId, localPlant);
        } else {
          // Update existing plant
          plant = await PlantService.updatePlant(userId, clientPlantId, localPlant);
        }

        await SyncOperation.create({
          clientOperationId: opId,
          userId,
          operationType: 'UPSERT',
          entityType: 'PLANT',
          entityId: clientPlantId,
          payload: localPlant,
          status: 'PROCESSED',
        });
      } catch (err) {
        console.error(`[SyncService] Plant sync error for ${clientPlantId}:`, err.message);
      }
    }

    // Return current authoritative plant list for user
    const remotePlants = await PlantService.getUserPlants(userId);
    return {
      success: true,
      plants: remotePlants,
      lastSyncedAt: new Date().toISOString(),
    };
  }

  static async syncCheckins(userId, localCheckins = []) {
    let syncedCount = 0;

    for (const checkin of localCheckins) {
      const checkinId = checkin.id || checkin.checkinId;
      if (!checkinId) continue;

      const opId = `sync_checkin_${checkinId}`;
      const existingOp = await SyncOperation.findOne({ clientOperationId: opId });

      if (existingOp) {
        syncedCount++;
        continue;
      }

      try {
        const plantId = checkin.plantId;
        const existingEvent = await CareEvent.findOne({
          userId,
          clientOperationId: checkinId,
        });

        if (!existingEvent && plantId) {
          await CareEvent.create({
            clientOperationId: checkinId,
            userId,
            plantId,
            type: checkin.watered ? 'WATERING' : 'CHECKIN',
            watered: checkin.watered === true,
            sunlightHours: checkin.sunlightHours || 4,
            environmentCondition: checkin.environmentCondition || 'Bright Indirect',
            verificationStatus: 'UNVERIFIED',
            notes: checkin.notes || null,
            aiDiagnosis: checkin.aiDiagnosis || null,
            timestamp: checkin.checkinDate ? new Date(checkin.checkinDate) : new Date(),
          });
        }

        await SyncOperation.create({
          clientOperationId: opId,
          userId,
          operationType: 'CREATE',
          entityType: 'CHECKIN',
          entityId: checkinId,
          payload: checkin,
          status: 'PROCESSED',
        });

        syncedCount++;
      } catch (err) {
        console.error(`[SyncService] Checkin sync error for ${checkinId}:`, err.message);
      }
    }

    return {
      success: true,
      syncedCount,
    };
  }

  static async syncUserProfile(userId, userPayload) {
    if (!userPayload) {
      return { success: false, message: 'Empty payload' };
    }

    const updatedUser = await UserService.updateProfile(userId, userPayload);
    return {
      success: true,
      user: updatedUser,
    };
  }
}
