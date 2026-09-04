import { User } from '../models/User.js';
import { CareEvent } from '../models/CareEvent.js';

export class StreakService {
  static async updateCareStreak(userId, careDate = new Date()) {
    const user = await User.findById(userId);
    if (!user) return 0;

    const startOfToday = new Date(careDate.getFullYear(), careDate.getMonth(), careDate.getDate());
    const startOfYesterday = new Date(startOfToday.getTime() - 24 * 60 * 60 * 1000);
    const endOfToday = new Date(startOfToday.getTime() + 24 * 60 * 60 * 1000);

    // Check if user already did a care event today before this one
    const checkinToday = await CareEvent.findOne({
      userId,
      timestamp: { $gte: startOfToday, $lt: endOfToday },
    });

    if (checkinToday) {
      // Already checked in today, maintain streak without double-incrementing
      return user.careStreakDays;
    }

    // Check if user had a care event yesterday
    const checkinYesterday = await CareEvent.findOne({
      userId,
      timestamp: { $gte: startOfYesterday, $lt: startOfToday },
    });

    if (checkinYesterday || user.careStreakDays === 0) {
      user.careStreakDays += 1;
    } else {
      // Streak broken, reset to 1
      user.careStreakDays = 1;
    }

    await user.save();
    return user.careStreakDays;
  }
}
