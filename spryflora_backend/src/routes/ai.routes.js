import express from 'express';
import * as aiController from '../controllers/ai.controller.js';
import { authenticateToken } from '../middleware/auth.middleware.js';
import { aiLimiter } from '../middleware/rateLimit.middleware.js';

const router = express.Router();

router.use(aiLimiter);
router.use(authenticateToken);

router.post('/plant-identify', aiController.identifyPlant);
router.post('/plant-analysis', aiController.analyzePlant);
router.post('/watering-verification', aiController.verifyWatering);
router.post('/buddy', aiController.askBuddy);

export default router;
