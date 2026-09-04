import { CareService } from '../services/care.service.js';

export const waterPlant = async (req, res, next) => {
  try {
    const result = await CareService.waterPlant(req.user.id, req.params.plantId, req.body);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const getCareHistory = async (req, res, next) => {
  try {
    const history = await CareService.getPlantCareHistory(req.user.id, req.params.plantId);
    res.status(200).json(history);
  } catch (error) {
    next(error);
  }
};
