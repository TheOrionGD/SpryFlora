import express from 'express';
import * as authController from '../controllers/auth.controller.js';
import { authenticateToken } from '../middleware/auth.middleware.js';
import { authLimiter } from '../middleware/rateLimit.middleware.js';
import { validateBody } from '../middleware/validation.middleware.js';

const router = express.Router();

router.post('/register', authLimiter, validateBody(['email', 'password']), authController.register);
router.post('/login', authLimiter, validateBody(['email', 'password']), authController.login);
router.get('/verify', authenticateToken, authController.verify);
router.post('/logout', authenticateToken, authController.logout);
router.post('/forgot-password/verify', authLimiter, authController.forgotPasswordVerify);
router.post('/forgot-password/reset', authLimiter, validateBody(['email', 'newPassword']), authController.forgotPasswordReset);

export default router;
