import rateLimit from 'express-rate-limit';
import { ERROR_CODES } from '../constants/index.js';

export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: {
      code: ERROR_CODES.TOO_MANY_REQUESTS,
      message: 'Too many requests, please try again later.',
    },
  },
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // Strict limit for registration/login
  message: {
    error: {
      code: ERROR_CODES.TOO_MANY_REQUESTS,
      message: 'Too many authentication attempts, please try again later.',
    },
  },
});

export const aiLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 40, // Strict rate limit on AI proxying
  message: {
    error: {
      code: ERROR_CODES.TOO_MANY_REQUESTS,
      message: 'Too many AI diagnostic requests, please try again later.',
    },
  },
});
