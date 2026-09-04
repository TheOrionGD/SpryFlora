import { ERROR_CODES } from '../constants/index.js';

export const validateBody = (requiredFields) => {
  return (req, res, next) => {
    if (!req.body) {
      return res.status(400).json({
        error: {
          code: ERROR_CODES.BAD_REQUEST,
          message: 'Missing request body.',
        },
      });
    }

    const missing = requiredFields.filter((field) => {
      const val = req.body[field];
      return val === undefined || val === null || (typeof val === 'string' && val.trim() === '');
    });

    if (missing.length > 0) {
      return res.status(400).json({
        error: {
          code: ERROR_CODES.BAD_REQUEST,
          message: `Missing required fields: ${missing.join(', ')}`,
        },
      });
    }

    next();
  };
};
