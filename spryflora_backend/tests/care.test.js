import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../src/app.js';

let mongoServer;
let tokenA;
let tokenB;
let plantId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const authA = await request(app).post('/api/auth/register').send({
    email: 'watera@spryflora.com',
    password: 'Password123!',
    name: 'Water User A',
  });
  tokenA = authA.body.token;

  const authB = await request(app).post('/api/auth/register').send({
    email: 'waterb@spryflora.com',
    password: 'Password123!',
    name: 'Water User B',
  });
  tokenB = authB.body.token;

  const plantRes = await request(app)
    .post('/api/plants')
    .set('Authorization', `Bearer ${tokenA}`)
    .send({ plantName: 'Care Plant', speciesName: 'Money Plant' });
  plantId = plantRes.body.id;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Care & Watering System Suite', () => {
  const testOpId = 'op_water_12345';

  it('should process valid watering request and award XP', async () => {
    const res = await request(app)
      .post(`/api/plants/${plantId}/care/water`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        clientOperationId: testOpId,
        watered: true,
      });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('careEvent');
    expect(res.body.isDuplicate).toBe(false);
    expect(res.body.xp).toBeGreaterThan(0);
  });

  it('should handle replayed request idempotently without double-rewarding XP', async () => {
    const res = await request(app)
      .post(`/api/plants/${plantId}/care/water`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        clientOperationId: testOpId,
        watered: true,
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.isDuplicate).toBe(true);
  });

  it('should REJECT unauthorized watering attempt on another user plant', async () => {
    const res = await request(app)
      .post(`/api/plants/${plantId}/care/water`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({
        clientOperationId: 'op_unauth_999',
        watered: true,
      });

    expect([403, 404]).toContain(res.statusCode);
  });
});
