import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../src/app.js';
import { User } from '../src/models/User.js';
import { Plant } from '../src/models/Plant.js';


let mongoServer;
let tokenA;
let tokenB;
let userAId;
let userBId;
let plantAId;
let plantBId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  // Register User A
  const resA = await request(app).post('/api/auth/register').send({
    email: 'usera@spryflora.com',
    password: 'Password123!',
    name: 'User A',
  });
  tokenA = resA.body.token;
  userAId = resA.body.user.id;

  // Register User B
  const resB = await request(app).post('/api/auth/register').send({
    email: 'userb@spryflora.com',
    password: 'Password123!',
    name: 'User B',
  });
  tokenB = resB.body.token;
  userBId = resB.body.user.id;

  // Create Plant for User A
  const plantARes = await request(app)
    .post('/api/plants')
    .set('Authorization', `Bearer ${tokenA}`)
    .send({ plantName: 'User A Tulsi', speciesName: 'Tulsi' });
  plantAId = plantARes.body.id;

  // Create Plant for User B
  const plantBRes = await request(app)
    .post('/api/plants')
    .set('Authorization', `Bearer ${tokenB}`)
    .send({ plantName: 'User B Rose', speciesName: 'Rose' });
  plantBId = plantBRes.body.id;
});

afterAll(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});

describe('P0 Server-Side Ownership Authorization Suite', () => {
  it('should allow User A to access User A own plant', async () => {
    const res = await request(app)
      .get(`/api/plants/${plantAId}`)
      .set('Authorization', `Bearer ${tokenA}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.plantName).toBe('User A Tulsi');
  });

  it('should REJECT User A accessing User B plant with 403 Forbidden', async () => {
    const res = await request(app)
      .get(`/api/plants/${plantBId}`)
      .set('Authorization', `Bearer ${tokenA}`);

    expect([403, 404]).toContain(res.statusCode);
  });

  it('should REJECT User A modifying User B plant with 403 Forbidden', async () => {
    const res = await request(app)
      .patch(`/api/plants/${plantBId}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ plantName: 'Hacked Name' });

    expect([403, 404]).toContain(res.statusCode);
  });

  it('should REJECT User A deleting User B plant with 403 Forbidden', async () => {
    const res = await request(app)
      .delete(`/api/plants/${plantBId}`)
      .set('Authorization', `Bearer ${tokenA}`);

    expect([403, 404]).toContain(res.statusCode);
  });

  it('should REJECT User A accessing User B certificate with 403 Forbidden', async () => {
    const res = await request(app)
      .get(`/api/plants/${plantBId}/certificate/eligibility`)
      .set('Authorization', `Bearer ${tokenA}`);

    expect([403, 404]).toContain(res.statusCode);
  });
});
