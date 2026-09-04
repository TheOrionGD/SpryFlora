import express from 'express';
import * as userController from '../controllers/user.controller.js';
import { authenticateToken } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticateToken);

router.get('/me', userController.getMe);
router.patch('/me', userController.updateMe);

// Aliases for Flutter compatibility
router.get('/profile', userController.getMe);
router.patch('/profile', userController.updateMe);

export default router;
