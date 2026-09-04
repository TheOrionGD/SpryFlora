import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../src/app.js';

let mongoServer;
let token;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const auth = await request(app).post('/api/auth/register').send({
    email: 'syncuser@spryflora.com',
    password: 'Password123!',
    name: 'Sync Test User',
  });
  token = auth.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Offline Synchronization & Persistence Suite', () => {
  it('should sync local offline plants array and return authoritative remote list', async () => {
    const localPlants = [
      {
        id: 'local_plant_001',
        plantName: 'Offline Jade',
        speciesName: 'Jade Plant',
        plantingDate: new Date().toISOString(),
        wateringIntervalDays: 7,
      },
    ];

    const res = await request(app)
      .post('/api/sync/plants')
      .set('Authorization', `Bearer ${token}`)
      .send({ plants: localPlants });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.plants)).toBe(true);
    expect(res.body.plants.length).toBeGreaterThanOrEqual(1);
    expect(res.body.plants[0].plantName).toBe('Offline Jade');
  });

  it('should sync checkins idempotently without error', async () => {
    const localCheckins = [
      {
        id: 'checkin_001',
        plantId: 'local_plant_001',
        watered: true,
        checkinDate: new Date().toISOString(),
      },
    ];

    const res = await request(app)
      .post('/api/sync/checkins')
      .set('Authorization', `Bearer ${token}`)
      .send({ checkins: localCheckins });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.syncedCount).toBe(1);
  });
});
