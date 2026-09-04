import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../src/app.js';
import { User } from '../src/models/User.js';


let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
});

afterAll(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});

beforeEach(async () => {
  await User.deleteMany({});
});

describe('Authentication API Suite', () => {
  it('should register a new user successfully and return token without passwordHash', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'testbotanist@spryflora.com',
        password: 'SecurePassword123!',
        name: 'Little Gardener',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('user');
    expect(res.body.user.email).toBe('testbotanist@spryflora.com');
    expect(res.body.user.passwordHash).toBeUndefined();
    expect(res.body.user.password).toBeUndefined();
  });

  it('should block duplicate email registration with 409 Conflict', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        email: 'duplicate@spryflora.com',
        password: 'Password123!',
        name: 'User One',
      });

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'duplicate@spryflora.com',
        password: 'AnotherPassword123!',
        name: 'User Two',
      });

    expect(res.statusCode).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  it('should authenticate valid credentials and return JWT token', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        email: 'login@spryflora.com',
        password: 'CorrectPassword123!',
        name: 'Login Test',
      });

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'login@spryflora.com',
        password: 'CorrectPassword123!',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.email).toBe('login@spryflora.com');
  });

  it('should reject wrong password with 401 Unauthorized', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        email: 'login@spryflora.com',
        password: 'CorrectPassword123!',
        name: 'Login Test',
      });

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'login@spryflora.com',
        password: 'WrongPassword999!',
      });

    expect(res.statusCode).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('should reject invalid auth token with 401 Unauthorized', async () => {
    const res = await request(app)
      .get('/api/auth/verify')
      .set('Authorization', 'Bearer invalid_bogus_token');

    expect(res.statusCode).toBe(401);
  });
});
