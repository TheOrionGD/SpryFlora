import { SpeciesService } from '../services/species.service.js';

export const getSpeciesList = async (req, res, next) => {
  try {
    const list = await SpeciesService.getAllSpecies();
    res.status(200).json(list);
  } catch (error) {
    next(error);
  }
};

export const getSpeciesById = async (req, res, next) => {
  try {
    const species = await SpeciesService.getSpeciesById(req.params.id);
    res.status(200).json(species);
  } catch (error) {
    next(error);
  }
};

export const searchSpecies = async (req, res, next) => {
  try {
    const query = req.query.q || req.query.query || '';
    const results = await SpeciesService.searchSpecies(query);
    res.status(200).json(results);
  } catch (error) {
    next(error);
  }
};
