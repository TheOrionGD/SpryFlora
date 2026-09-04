import { User } from '../models/User.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { signToken } from '../utils/jwt.js';
import { isValidEmail } from '../utils/validation.js';
import { ERROR_CODES } from '../constants/index.js';

export class AuthService {
  static async register({ email, password, name }) {
    if (!isValidEmail(email)) {
      const err = new Error('Invalid email format.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    if (!password || password.length < 6) {
      const err = new Error('Password must be at least 6 characters long.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const cleanEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: cleanEmail });
    if (existing) {
      const err = new Error('An account with this email already exists.');
      err.statusCode = 409;
      err.code = ERROR_CODES.CONFLICT;
      throw err;
    }

    const passwordHash = await hashPassword(password);
    const user = await User.create({
      email: cleanEmail,
      passwordHash,
      name: name || cleanEmail.split('@')[0],
      childName: name || cleanEmail.split('@')[0],
    });

    const token = signToken({ userId: user._id.toString(), email: user.email });
    return {
      token,
      user: user.toJSON(),
    };
  }

  static async login({ email, password }) {
    if (!email || !password) {
      const err = new Error('Email and password are required.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const cleanEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: cleanEmail }).select('+passwordHash');
    if (!user) {
      const err = new Error('Invalid email or password.');
      err.statusCode = 401;
      err.code = ERROR_CODES.UNAUTHORIZED;
      throw err;
    }

    const valid = await verifyPassword(user.passwordHash, password);
    if (!valid) {
      const err = new Error('Invalid email or password.');
      err.statusCode = 401;
      err.code = ERROR_CODES.UNAUTHORIZED;
      throw err;
    }

    const token = signToken({ userId: user._id.toString(), email: user.email });
    return {
      token,
      user: user.toJSON(),
    };
  }

  static async verify(userId) {
    const user = await User.findById(userId);
    if (!user) {
      const err = new Error('User not found.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }
    return user.toJSON();
  }
}
