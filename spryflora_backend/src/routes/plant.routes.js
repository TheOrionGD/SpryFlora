import express from 'express';
import * as plantController from '../controllers/plant.controller.js';
import { authenticateToken } from '../middleware/auth.middleware.js';
import careRoutes from './care.routes.js';
import certificateRoutes from './certificate.routes.js';

const router = express.Router();

router.use(authenticateToken);

// Mount nested plant routes
router.use('/:plantId/care', careRoutes);
router.use('/:plantId/certificate', certificateRoutes);

router.post('/', plantController.createPlant);
router.get('/', plantController.getPlants);
router.get('/:id', plantController.getPlantById);
router.patch('/:id', plantController.updatePlant);
router.delete('/:id', plantController.deletePlant);

export default router;
