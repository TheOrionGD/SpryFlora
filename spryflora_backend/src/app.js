import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import mongoose from 'mongoose';
import { env } from './config/env.js';
import { apiLimiter } from './middleware/rateLimit.middleware.js';
import { errorHandler } from './middleware/error.middleware.js';

import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import plantRoutes from './routes/plant.routes.js';
import speciesRoutes from './routes/species.routes.js';
import syncRoutes from './routes/sync.routes.js';
import aiRoutes from './routes/ai.routes.js';
import deletionRoutes from './routes/deletion.routes.js';
import forgotPasswordRoutes from './routes/forgot_password.routes.js';

const app = express();

// Security Middlewares
app.use(helmet({ contentSecurityPolicy: false }));
app.use(
  cors({
    origin: env.corsOrigins,
    credentials: true,
  })
);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

if (env.nodeEnv !== 'test') {
  app.use(apiLimiter);
}

// Root & Health Probes
app.get('/', (req, res) => {
  res.status(200).json({
    message: '🚀 SpryFlora Cloud REST API & AI Gateway is Active!',
    status: 'online',
    health: '/health',
    readiness: '/ready',
    accountDeletionPortal: '/delete-account',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'spryflora-backend',
    timestamp: new Date().toISOString(),
    dbState: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

app.get('/ready', (req, res) => {
  const isDbReady = mongoose.connection.readyState === 1;
  if (isDbReady) {
    return res.status(200).json({ ready: true });
  }
  return res.status(503).json({ ready: false, reason: 'Database connection not ready' });
});

// Server-rendered Account Deletion Link & Password Recovery Portal
app.use('/delete-account', deletionRoutes);
app.use('/forgot-password', forgotPasswordRoutes);

// Primary API Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/plants', plantRoutes);
app.use('/api/species', speciesRoutes);
app.use('/api/sync', syncRoutes);

// Authenticated AI Gateway Proxy Routes
app.use('/ai', aiRoutes);

// Global Error Handler
app.use(errorHandler);

export default app;
