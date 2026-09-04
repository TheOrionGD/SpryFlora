import express from 'express';
import * as speciesController from '../controllers/species.controller.js';

const router = express.Router();

router.get('/', speciesController.getSpeciesList);
router.get('/search', speciesController.searchSpecies);
router.get('/:id', speciesController.getSpeciesById);

export default router;
