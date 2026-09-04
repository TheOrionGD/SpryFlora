import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../src/app.js';

let mongoServer;
let token;
let user;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const authRes = await request(app).post('/api/auth/register').send({
    email: 'gardener@spryflora.com',
    password: 'Password123!',
    name: 'Gardener',
  });
  token = authRes.body.token;
  user = authRes.body.user;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Plant Lifecycle & Growth API Suite', () => {
  let createdPlantId;

  it('should create a plant and calculate initial deterministic growth telemetry', async () => {
    const res = await request(app)
      .post('/api/plants')
      .set('Authorization', `Bearer ${token}`)
      .send({
        plantName: 'My Aloe',
        speciesName: 'Aloe Vera',
        location: 'Balcony',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.plantName).toBe('My Aloe');
    expect(res.body.speciesName).toBe('Aloe Vera');
    expect(res.body.growthProgress).toBeDefined();
    expect(res.body.currentHeightCm).toBeDefined();
    createdPlantId = res.body.id;
  });

  it('should retrieve plant list for authenticated user', async () => {
    const res = await request(app)
      .get('/api/plants')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(1);
  });

  it('should update plant details safely', async () => {
    const res = await request(app)
      .patch(`/api/plants/${createdPlantId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        plantName: 'Aloe Champion',
        location: 'Bedroom Window',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.plantName).toBe('Aloe Champion');
    expect(res.body.location).toBe('Bedroom Window');
  });

  it('should delete plant successfully', async () => {
    const res = await request(app)
      .delete(`/api/plants/${createdPlantId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
