import { PlantService } from './plant.service.js';
import { UserService } from './user.service.js';
import { ERROR_CODES } from '../constants/index.js';

export class CertificateService {
  static async checkEligibility(userId, plantId) {
    const plant = await PlantService.getPlantById(userId, plantId);
    const isEligible = plant.isCompleted === true || plant.growthProgress >= 1.0;

    return {
      plantId: plant.id,
      plantName: plant.plantName,
      speciesName: plant.speciesName,
      isEligible,
      growthProgress: plant.growthProgress,
      ageInDays: plant.ageInDays,
      lifespanDays: plant.lifespanDays,
      reason: isEligible
        ? 'Congratulations! Plant has reached full maturity.'
        : `Plant is at ${(plant.growthProgress * 100).toFixed(0)}% growth progress. Completion requires 100%.`,
    };
  }

  static async getCertificate(userId, plantId) {
    const eligibility = await this.checkEligibility(userId, plantId);
    if (!eligibility.isEligible) {
      const err = new Error('Plant is not eligible for certificate completion.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const user = await UserService.getProfile(userId);
    const plant = await PlantService.getPlantById(userId, plantId);

    return {
      certificateId: `cert_${plant.id}_${Date.now()}`,
      issuedTo: user.childName || user.name,
      plantName: plant.plantName,
      speciesName: plant.speciesName,
      botanicalName: plant.botanicalName,
      issueDate: new Date().toISOString(),
      achievementTitle: 'Master Botanist Certificate of Excellence',
      verifiedBy: 'SpryFlora Botanical Authority',
    };
  }
}
