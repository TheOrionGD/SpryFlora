import { Species } from '../models/Species.js';
import { ERROR_CODES } from '../constants/index.js';

export class SpeciesService {
  static async getAllSpecies() {
    const list = await Species.find().sort({ commonName: 1 });
    return list;
  }

  static async getSpeciesById(id) {
    let species = await Species.findOne({ speciesId: id });
    if (!species) {
      species = await Species.findById(id).catch(() => null);
    }
    if (!species) {
      const err = new Error('Species not found.');
      err.statusCode = 404;
      err.code = ERROR_CODES.NOT_FOUND;
      throw err;
    }
    return species;
  }

  static async searchSpecies(query) {
    if (!query) return this.getAllSpecies();
    const regex = new RegExp(query, 'i');
    return await Species.find({
      $or: [{ commonName: regex }, { botanicalName: regex }],
    }).sort({ commonName: 1 });
  }

  static async findOrCreateSpecies(speciesName, defaults = {}) {
    let species = await Species.findOne({
      $or: [
        { commonName: new RegExp(`^${speciesName}$`, 'i') },
        { speciesId: speciesName.toLowerCase().replaceAll(' ', '_') },
      ],
    });

    if (!species) {
      const speciesId = speciesName.toLowerCase().replaceAll(' ', '_');
      species = await Species.create({
        speciesId,
        commonName: speciesName,
        botanicalName: defaults.botanicalName || speciesName,
        matureHeightCm: defaults.matureHeightCm || 50.0,
        initialHeightCm: defaults.initialHeightCm || 2.0,
        growthDurationDays: defaults.growthDurationDays || defaults.lifespanDays || 150,
        wateringIntervalDays: defaults.wateringIntervalDays || 3,
        sunlightRequirements: defaults.sunlightRequirements || defaults.sunlight || 'Bright Indirect',
        careInstructions: defaults.careInstructions || defaults.careTip || 'Keep soil lightly moist.',
        description: defaults.description || 'Discovered plant species.',
      });
    }

    return species;
  }
}
