import { ERROR_CODES } from '../constants/index.js';
import { env } from '../config/env.js';

export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const code = err.code || ERROR_CODES.INTERNAL_ERROR;
  const message = err.message || 'An internal server error occurred.';

  if (env.nodeEnv !== 'test') {
    console.error(`[Error] ${req.method} ${req.url} - ${statusCode} ${code}: ${message}`);
    if (err.stack && env.nodeEnv === 'development') {
      console.error(err.stack);
    }
  }

  res.status(statusCode).json({
    error: {
      code,
      message,
    },
  });
};
