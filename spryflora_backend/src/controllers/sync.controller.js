import { SyncService } from '../services/sync.service.js';

export const syncGeneral = async (req, res, next) => {
  try {
    const { plants, checkins, userProfile } = req.body;
    let plantsRes = null;
    let checkinsRes = null;
    let profileRes = null;

    if (Array.isArray(plants)) {
      plantsRes = await SyncService.syncPlants(req.user.id, plants);
    }
    if (Array.isArray(checkins)) {
      checkinsRes = await SyncService.syncCheckins(req.user.id, checkins);
    }
    if (userProfile) {
      profileRes = await SyncService.syncUserProfile(req.user.id, userProfile);
    }

    res.status(200).json({
      success: true,
      plants: plantsRes ? plantsRes.plants : undefined,
      checkinsSynced: checkinsRes ? checkinsRes.syncedCount : undefined,
      userProfile: profileRes ? profileRes.user : undefined,
      syncedAt: new Date().toISOString(),
    });
  } catch (error) {
    next(error);
  }
};

export const syncPlants = async (req, res, next) => {
  try {
    const localPlants = req.body.plants || [];
    const result = await SyncService.syncPlants(req.user.id, localPlants);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const syncCheckins = async (req, res, next) => {
  try {
    const localCheckins = req.body.checkins || [];
    const result = await SyncService.syncCheckins(req.user.id, localCheckins);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const syncUserProfile = async (req, res, next) => {
  try {
    const profile = req.body.user || req.body.userProfile;
    const result = await SyncService.syncUserProfile(req.user.id, profile);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};
