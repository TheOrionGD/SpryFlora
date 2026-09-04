import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { connectDatabase, disconnectDatabase } from '../src/config/database.js';
import { Species } from '../src/models/Species.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const seedSpecies = async () => {
  try {
    await connectDatabase();

    const jsonPath = path.resolve(__dirname, '../../assets/database/species_data.json');
    if (!fs.existsSync(jsonPath)) {
      console.error(`[Seed] Species data file not found at ${jsonPath}`);
      process.exit(1);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const speciesList = JSON.parse(rawData);

    console.log(`[Seed] Found ${speciesList.length} species records to import.`);

    for (const item of speciesList) {
      const commonName = item.name || item.commonName;
      const speciesId = item.speciesId || commonName.toLowerCase().replaceAll(' ', '_');

      let sunlightStr = item.sunlight || item.sunlightRequirements || 'Moderate Sun';
      let targetHours = 4;
      const lower = sunlightStr.toLowerCase();
      if (lower.contains ? lower.contains('full') || lower.contains('direct') : lower.includes('full') || lower.includes('direct')) {
        targetHours = 6;
      } else if (lower.contains ? lower.contains('low') || lower.contains('shade') : lower.includes('low') || lower.includes('shade')) {
        targetHours = 2;
      }

      await Species.findOneAndUpdate(
        { speciesId },
        {
          speciesId,
          commonName,
          botanicalName: item.botanicalName || commonName,
          matureHeightCm: item.matureHeightCm || 50.0,
          initialHeightCm: item.initialHeightCm || 2.0,
          growthDurationDays: item.lifespanDays || item.growthDurationDays || 150,
          wateringIntervalDays: item.wateringIntervalDays || 3,
          sunlightRequirements: sunlightStr,
          targetSunlightHours: targetHours,
          description: item.description || 'Discovered species.',
          idealTemp: item.idealTemp || '18°C - 28°C',
        },
        { upsert: true, new: true }
      );
    }

    console.log('[Seed] Species database seeding complete!');
    await disconnectDatabase();
    process.exit(0);
  } catch (error) {
    console.error(`[Seed] Error during species database seeding: ${error.message}`);
    process.exit(1);
  }
};

seedSpecies();
