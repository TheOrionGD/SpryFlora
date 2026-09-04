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
    email: 'xpuser@spryflora.com',
    password: 'Password123!',
    name: 'XP Test User',
  });
  token = auth.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Server-Authoritative XP & Streak System Suite', () => {
  it('should ignore client attempts to write arbitrary XP: 999999 via profile update', async () => {
    const res = await request(app)
      .patch('/api/user/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({
        xp: 999999,
        careStreakDays: 999,
        favoritePlant: 'Rose',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.favoritePlant).toBe('Rose');
    expect(res.body.xp).not.toBe(999999);
    expect(res.body.careStreakDays).not.toBe(999);
  });

  it('should award server-authoritative +50 XP when creating a plant', async () => {
    const meBefore = await request(app)
      .get('/api/user/me')
      .set('Authorization', `Bearer ${token}`);
    const initialXP = meBefore.body.xp;

    await request(app)
      .post('/api/plants')
      .set('Authorization', `Bearer ${token}`)
      .send({ plantName: 'Streak Rose', speciesName: 'Rose' });

    const meAfter = await request(app)
      .get('/api/user/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meAfter.body.xp).toBe(initialXP + 50);
  });
});
