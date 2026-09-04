import argon2 from 'argon2';
import bcrypt from 'bcryptjs';

export const hashPassword = async (password) => {
  try {
    return await argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3,
      parallelism: 1,
    });
  } catch (err) {
    // Fallback to bcrypt if native argon2 bindings fail in environment
    const salt = await bcrypt.genSalt(12);
    return await bcrypt.hash(password, salt);
  }
};

export const verifyPassword = async (hash, password) => {
  try {
    if (hash.startsWith('$argon2')) {
      return await argon2.verify(hash, password);
    }
    return await bcrypt.compare(password, hash);
  } catch (err) {
    try {
      return await bcrypt.compare(password, hash);
    } catch (_) {
      return false;
    }
  }
};
