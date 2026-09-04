import { User } from '../models/User.js';
import { REWARD_XP } from '../constants/index.js';

export class XPService {
  static async awardXP(userId, points) {
    if (!userId || points <= 0) return null;
    const user = await User.findById(userId);
    if (!user) return null;

    user.xp = (user.xp || 0) + points;
    await user.save();
    return user.xp;
  }

  static getPlantingXP() {
    return REWARD_XP.PLANT_CREATION;
  }

  static getWateringXP() {
    return REWARD_XP.VALID_WATERING;
  }

  static getDiscoveryXP() {
    return REWARD_XP.SPECIES_DISCOVERY;
  }

  static getCompletionXP() {
    return REWARD_XP.COMPLETION;
  }
}
