import { UserService } from '../services/user.service.js';

export const getMe = async (req, res, next) => {
  try {
    const profile = await UserService.getProfile(req.user.id);
    res.status(200).json(profile);
  } catch (error) {
    next(error);
  }
};

export const updateMe = async (req, res, next) => {
  try {
    const profile = await UserService.updateProfile(req.user.id, req.body);
    res.status(200).json(profile);
  } catch (error) {
    next(error);
  }
};
