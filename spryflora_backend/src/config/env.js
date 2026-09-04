import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/spryflora_db',
  jwtSecret: process.env.JWT_SECRET || '',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '14d',
  geminiApiKey: process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY_1 || '',
  geminiApiKey1: process.env.GEMINI_API_KEY_1 || process.env.GEMINI_API_KEY || '',
  geminiApiKey2: process.env.GEMINI_API_KEY_2 || '',
  huggingFaceApiKey: process.env.HUGGINGFACE_API_KEY || '',
  huggingFaceModel: process.env.HUGGINGFACE_MODEL || 'foduucom/plant-leaf-detection-and-classification',
  groqApiKey: process.env.GROQ_API_KEY || '',
  aiBackendEnabled: process.env.AI_BACKEND_ENABLED !== 'false',
  corsOrigins: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : '*',
};

if (!env.jwtSecret && env.nodeEnv === 'production') {
  throw new Error('FATAL: JWT_SECRET environment variable must be set in .env or environment in production.');
}
