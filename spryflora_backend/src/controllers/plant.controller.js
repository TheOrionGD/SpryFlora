import { PlantService } from '../services/plant.service.js';

export const createPlant = async (req, res, next) => {
  try {
    const plant = await PlantService.createPlant(req.user.id, req.body);
    res.status(201).json(plant);
  } catch (error) {
    next(error);
  }
};

export const getPlants = async (req, res, next) => {
  try {
    const plants = await PlantService.getUserPlants(req.user.id);
    res.status(200).json(plants);
  } catch (error) {
    next(error);
  }
};

export const getPlantById = async (req, res, next) => {
  try {
    const plant = await PlantService.getPlantById(req.user.id, req.params.id);
    res.status(200).json(plant);
  } catch (error) {
    next(error);
  }
};

export const updatePlant = async (req, res, next) => {
  try {
    const plant = await PlantService.updatePlant(req.user.id, req.params.id, req.body);
    res.status(200).json(plant);
  } catch (error) {
    next(error);
  }
};

export const deletePlant = async (req, res, next) => {
  try {
    const result = await PlantService.deletePlant(req.user.id, req.params.id);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};
