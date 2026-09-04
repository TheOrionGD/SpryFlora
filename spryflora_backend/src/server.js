import app from './app.js';
import { env } from './config/env.js';
import { connectDatabase, disconnectDatabase } from './config/database.js';

let server;

const startServer = async () => {
  try {
    await connectDatabase();
    server = app.listen(env.port, () => {
      console.log(`[SpryFlora Backend] Server running on port ${env.port} (${env.nodeEnv})`);
    });
  } catch (error) {
    console.error(`[SpryFlora Backend] Startup failure: ${error.message}`);
    process.exit(1);
  }
};

const gracefulShutdown = async (signal) => {
  console.log(`\n[SpryFlora Backend] ${signal} signal received. Initiating graceful shutdown...`);
  if (server) {
    server.close(async () => {
      console.log('[SpryFlora Backend] HTTP server closed.');
      await disconnectDatabase();
      process.exit(0);
    });
  } else {
    await disconnectDatabase();
    process.exit(0);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

if (process.env.NODE_ENV !== 'test') {
  startServer();
}

export { app, server };
