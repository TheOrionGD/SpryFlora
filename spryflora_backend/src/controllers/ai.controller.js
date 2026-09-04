import { AIService } from '../services/ai/ai.service.js';

export const identifyPlant = async (req, res, next) => {
  try {
    const result = await AIService.identifyPlant({
      image: req.body.image || req.body.photoPath || req.body.photo,
      prompt: req.body.prompt,
    });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const analyzePlant = async (req, res, next) => {
  try {
    const result = await AIService.analyzePlant({
      plant: req.body.plant,
      image: req.body.image || req.body.photoPath || req.body.photo,
      prompt: req.body.prompt,
    });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const verifyWatering = async (req, res, next) => {
  try {
    const result = await AIService.verifyWateringPhoto({
      plant: req.body.plant,
      image: req.body.image || req.body.photoPath || req.body.photo,
    });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const askBuddy = async (req, res, next) => {
  try {
    const result = await AIService.askBuddy({
      prompt: req.body.prompt || req.body.userQuestion || req.body.message,
      plant: req.body.plant,
    });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};
