import { User } from '../models/User.js';
import { ERROR_CODES } from '../constants/index.js';

export class UserService {
  static async getProfile(userId) {
    const user = await User.findById(userId);
    if (!user) {
      const err = new Error('User not found.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }
    return user.toJSON();
  }

  static async updateProfile(userId, updateData) {
    const user = await User.findById(userId);
    if (!user) {
      const err = new Error('User not found.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }

    // Allowed profile fields only - SECURITY CHECK: Reject arbitrary client XP or streak overrides
    const allowedFields = ['name', 'childName', 'age', 'school', 'favoritePlant', 'profilePhotoUrl'];
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        user[field] = updateData[field];
      }
    }

    await user.save();
    return user.toJSON();
  }
}
