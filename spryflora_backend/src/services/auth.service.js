import { User } from '../models/User.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { signToken } from '../utils/jwt.js';
import { isValidEmail } from '../utils/validation.js';
import { ERROR_CODES } from '../constants/index.js';

export class AuthService {
  static async register({ email, password, name, username, childName, dob, favoritePlant }) {
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
    const cleanUsername = (username || '').trim().toLowerCase() || cleanEmail.split('@')[0];

    const existing = await User.findOne({
      $or: [
        { email: cleanEmail },
        ...(cleanUsername ? [{ username: cleanUsername }] : []),
      ],
    });

    if (existing) {
      const isEmailMatch = existing.email === cleanEmail;
      const err = new Error(
        isEmailMatch
          ? 'An account with this email already exists.'
          : 'This username is already taken. Try another!'
      );
      err.statusCode = 409;
      err.code = ERROR_CODES.CONFLICT;
      throw err;
    }

    const passwordHash = await hashPassword(password);
    const user = await User.create({
      email: cleanEmail,
      passwordHash,
      name: name || cleanEmail.split('@')[0],
      childName: childName || name || cleanEmail.split('@')[0],
      username: cleanUsername,
      dob: dob || '',
      favoritePlant: favoritePlant || '',
    });

    const token = signToken({ userId: user._id.toString(), email: user.email });
    return {
      token,
      user: user.toJSON(),
    };
  }

  static async login({ email, username, identifier, password }) {
    const rawIdentifier = email || username || identifier || '';
    if (!rawIdentifier || !password) {
      const err = new Error('Email/username and password are required.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const cleanIdentifier = rawIdentifier.trim().toLowerCase();
    const user = await User.findOne({
      $or: [
        { email: cleanIdentifier },
        { username: cleanIdentifier },
        { childName: new RegExp(`^${cleanIdentifier}$`, 'i') },
        { name: new RegExp(`^${cleanIdentifier}$`, 'i') },
      ],
    }).select('+passwordHash');

    if (!user) {
      const err = new Error('Invalid email/username or password.');
      err.statusCode = 401;
      err.code = ERROR_CODES.UNAUTHORIZED;
      throw err;
    }

    const valid = await verifyPassword(user.passwordHash, password);
    if (!valid) {
      const err = new Error('Invalid email/username or password.');
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

  static async forgotPasswordVerify({ email, username, name, favoritePlant }) {
    const cleanEmail = (email || '').trim().toLowerCase();
    const cleanUsername = (username || '').trim().toLowerCase();
    const cleanName = (name || '').trim().toLowerCase();

    if (!cleanEmail && !cleanUsername) {
      const err = new Error('Email or username is required for verification.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const query = [];
    if (cleanEmail) query.push({ email: cleanEmail });
    if (cleanUsername) query.push({ username: cleanUsername });

    const user = await User.findOne({ $or: query });
    if (!user) {
      const err = new Error('No user account found matching these credentials.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }

    if (cleanName && user.name) {
      const userName = user.name.toLowerCase();
      const userChildName = (user.childName || '').toLowerCase();
      const matches = userName.includes(cleanName) || cleanName.includes(userName) ||
                      userChildName.includes(cleanName) || cleanName.includes(userChildName);
      if (!matches) {
        const err = new Error('Security details do not match the account record.');
        err.statusCode = 400;
        err.code = ERROR_CODES.BAD_REQUEST;
        throw err;
      }
    }

    return {
      verified: true,
      email: user.email,
      message: 'Account identity verified successfully.',
    };
  }

  static async forgotPasswordReset({ email, newPassword }) {
    if (!email || !newPassword) {
      const err = new Error('Email and new password are required.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    if (newPassword.length < 6) {
      const err = new Error('Password must be at least 6 characters long.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const cleanEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: cleanEmail });
    if (!user) {
      const err = new Error('No user account found with this email.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }

    user.passwordHash = await hashPassword(newPassword);
    await user.save();

    return {
      success: true,
      message: 'Password has been reset successfully. You may now sign in.',
    };
  }
}
