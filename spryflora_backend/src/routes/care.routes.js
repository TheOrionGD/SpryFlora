import express from 'express';
import * as careController from '../controllers/care.controller.js';

const router = express.Router({ mergeParams: true });

router.post('/water', careController.waterPlant);
router.get('/', careController.getCareHistory);

export default router;
