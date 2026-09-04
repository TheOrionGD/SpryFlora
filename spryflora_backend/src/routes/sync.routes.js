import express from 'express';
import * as syncController from '../controllers/sync.controller.js';
import { authenticateToken } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticateToken);

router.post('/', syncController.syncGeneral);
router.post('/plants', syncController.syncPlants);
router.post('/checkins', syncController.syncCheckins);
router.post('/user-profile', syncController.syncUserProfile);

export default router;
