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
    email: 'aiuser@spryflora.com',
    password: 'Password123!',
    name: 'AI Test User',
  });
  token = auth.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('AI Gateway & Proxy Security Suite', () => {
  it('should REJECT unauthenticated AI endpoint calls with 401 Unauthorized', async () => {
    const res = await request(app).post('/ai/plant-identify').send({ prompt: 'test' });
    expect(res.statusCode).toBe(401);
  });

  it('should accept AI buddy request when authenticated', async () => {
    const res = await request(app)
      .post('/ai/buddy')
      .set('Authorization', `Bearer ${token}`)
      .send({ prompt: 'How much water does my Tulsi need?' });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('result');
  });

  it('should return explicit error or false verification when photo is missing without fake success', async () => {
    const res = await request(app)
      .post('/ai/watering-verification')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toBe(200);
    expect(res.body.isVerified).toBe(false);
    expect(res.body.rejectionReason).toBeDefined();
  });
});
