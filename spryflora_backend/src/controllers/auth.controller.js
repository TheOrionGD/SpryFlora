import { AuthService } from '../services/auth.service.js';

export const register = async (req, res, next) => {
  try {
    const result = await AuthService.register(req.body);
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const result = await AuthService.login(req.body);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const verify = async (req, res, next) => {
  try {
    const user = await AuthService.verify(req.user.id);
    res.status(200).json({ valid: true, user });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req, res, next) => {
  res.status(200).json({ success: true, message: 'Logged out successfully.' });
};

export const forgotPasswordVerify = async (req, res, next) => {
  try {
    const result = await AuthService.forgotPasswordVerify(req.body);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const forgotPasswordReset = async (req, res, next) => {
  try {
    const result = await AuthService.forgotPasswordReset(req.body);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};
