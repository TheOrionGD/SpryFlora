import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { User } from '../src/models/User.js';
import { Plant } from '../src/models/Plant.js';
import { Species } from '../src/models/Species.js';
import { CareEvent } from '../src/models/CareEvent.js';
import { hashPassword } from '../src/utils/password.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const TEST_USER = {
  email: 'moneyplant_user@spryflora.com',
  username: 'moneyplant_master',
  password: 'Password123!',
  name: 'Leo Green',
  childName: 'Leo Green',
  age: 10,
  school: 'Emerald Botanical Academy',
  favoritePlant: 'Money Plant',
  xp: 1850,
  careStreakDays: 45,
  completedPlantsCount: 1,
};

async function seedMoneyPlantTestUser() {
  try {
    console.log('🌱 [Seed] Connecting to MongoDB...');
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI environment variable is missing in .env');
    }

    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log('✅ [Seed] Connected to MongoDB database:', mongoose.connection.db.databaseName);

    // 1. Ensure Species for Money Plant exists
    const speciesId = 'money_plant';
    let species = await Species.findOne({ speciesId });
    if (!species) {
      species = await Species.create({
        speciesId: 'money_plant',
        commonName: 'Money Plant',
        botanicalName: 'Epipremnum aureum',
        matureHeightCm: 50.0,
        initialHeightCm: 2.0,
        growthDurationDays: 150,
        wateringIntervalDays: 3,
        wateringTolerance: 'Moderate',
        sunlightRequirements: 'Bright Indirect Light',
        targetSunlightHours: 4,
        lifecycleStages: ['Seed', 'Sprout', 'Seedling', 'Young Plant', 'Growing Plant', 'Fully Grown Plant'],
        careInstructions: 'Water when top 2 inches of soil are dry, wipe leaves occasionally to remove dust, thrives in water or soil.',
        description: 'Lush cascading heart-leaf foliage with marbled gold variegation, known for air purification and resilience.',
        idealTemp: '15°C - 30°C',
        image: 'assets/images/plants/money_plant.png',
      });
      console.log('🌿 [Seed] Created Species record for Money Plant.');
    } else {
      console.log('🌿 [Seed] Species record for Money Plant already exists.');
    }

    // 2. Find or recreate Test User
    let user = await User.findOne({
      $or: [{ email: TEST_USER.email }, { username: TEST_USER.username }],
    });

    const hashedPassword = await hashPassword(TEST_USER.password);

    if (user) {
      console.log(`👤 [Seed] Existing test user found (${user.email}). Updating profile data...`);
      user.name = TEST_USER.name;
      user.childName = TEST_USER.childName;
      user.age = TEST_USER.age;
      user.school = TEST_USER.school;
      user.favoritePlant = TEST_USER.favoritePlant;
      user.xp = TEST_USER.xp;
      user.careStreakDays = TEST_USER.careStreakDays;
      user.completedPlantsCount = TEST_USER.completedPlantsCount;
      user.passwordHash = hashedPassword;
      await user.save();
    } else {
      console.log(`👤 [Seed] Creating new test user: ${TEST_USER.email}...`);
      user = await User.create({
        email: TEST_USER.email,
        username: TEST_USER.username,
        passwordHash: hashedPassword,
        name: TEST_USER.name,
        childName: TEST_USER.childName,
        age: TEST_USER.age,
        school: TEST_USER.school,
        favoritePlant: TEST_USER.favoritePlant,
        xp: TEST_USER.xp,
        careStreakDays: TEST_USER.careStreakDays,
        completedPlantsCount: TEST_USER.completedPlantsCount,
      });
    }

    const userId = user._id;

    // 3. Remove previous test plants and care events for this test user to keep it clean & fresh
    await Plant.deleteMany({ userId });
    await CareEvent.deleteMany({ userId });

    // 4. Create Fully Completed Money Plant Record
    const now = new Date();
    const plantedDate = new Date(now.getTime() - 160 * 24 * 60 * 60 * 1000); // 160 days ago
    const clientPlantId = `plant_money_plant_${userId.toString().slice(-6)}`;

    const plant = await Plant.create({
      userId,
      clientPlantId,
      plantName: 'Prosperity Money Plant',
      speciesName: 'Money Plant',
      speciesId: 'money_plant',
      commonName: 'Money Plant',
      botanicalName: 'Epipremnum aureum',
      imageUrl: 'assets/images/plants/money_plant.png',
      initialPhotoPath: 'assets/images/plants/money_plant.png',
      location: 'Living Room Window',
      plantedAt: plantedDate,
      plantingDate: plantedDate,
      lifespanDays: 150,
      growthDurationDays: 150,
      wateringIntervalDays: 3,
      targetSunlightHours: 4,
      sunlightHoursToday: 4,
      lastSunlightDate: now,
      lastWateredAt: now,
      lastWateredDate: now,
      nextWateringAt: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      nextWateringDate: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      initialHeightCm: 2.0,
      matureHeightCm: 50.0,
      currentHeightCm: 50.0,
      healthScore: 100,
      health: 100,
      hydrationScore: 100,
      sunlightScore: 100,
      consistencyScore: 100,
      healthStatus: 'Optimal',
      lifecycleStage: 'Fully Grown Plant',
      growthProgress: 1.0,
      isCompleted: true,
      isCompletedManually: true,
      version: 1,
    });

    console.log(`🪴 [Seed] Created Completed Money Plant record with ID: ${plant._id} (Client ID: ${clientPlantId})`);

    // 5. Generate Comprehensive Care History / Completed Tasks across 150 days
    const careMilestones = [
      {
        dayOffset: 160,
        type: 'WATERING',
        watered: true,
        sunlightHours: 4,
        notes: 'Planted Money Plant cutting into rich potting soil with drainage.',
        aiDiagnosis: 'Seed/Cutting successfully rooted. Optimal moisture levels detected.',
        xp: 50,
      },
      {
        dayOffset: 145,
        type: 'WATERING',
        watered: true,
        sunlightHours: 4,
        notes: 'First vibrant green sprout emerged!',
        aiDiagnosis: 'Sprout stage active. Healthy leaf bud formation.',
        xp: 25,
      },
      {
        dayOffset: 130,
        type: 'SUNLIGHT',
        watered: false,
        sunlightHours: 5,
        notes: 'Moved near morning sun window for optimal photosynthesis.',
        aiDiagnosis: 'Excellent chlorophyll production. Heart-shaped leaves expanding.',
        xp: 25,
      },
      {
        dayOffset: 110,
        type: 'CHECKIN',
        watered: true,
        sunlightHours: 4,
        notes: 'Seedling growing fast, stems getting stronger.',
        aiDiagnosis: 'Seedling stage thriving. Sturdy stems and crisp foliage.',
        xp: 30,
      },
      {
        dayOffset: 80,
        type: 'WATERING',
        watered: true,
        sunlightHours: 4,
        notes: 'Young plant stage. Third set of variegated leaves unfurling.',
        aiDiagnosis: 'Young Plant milestone reached. Golden-green variegation prominent.',
        xp: 35,
      },
      {
        dayOffset: 50,
        type: 'DIAGNOSIS',
        watered: true,
        sunlightHours: 4,
        notes: 'AI Health scan check-in: Lush trailing vines developing.',
        aiDiagnosis: 'Growing Plant stage: 100% Health. No pest presence or nutrient deficiency.',
        xp: 40,
      },
      {
        dayOffset: 20,
        type: 'WATERING',
        watered: true,
        sunlightHours: 4,
        notes: 'Regular scheduled watering completed. Plant reached 45cm!',
        aiDiagnosis: 'Vigorous vegetative growth. Nearing full mature height.',
        xp: 25,
      },
      {
        dayOffset: 1,
        type: 'WATERING',
        watered: true,
        sunlightHours: 4,
        notes: 'Final maturity milestone achieved! Plant is 50.0 cm tall with full golden cascading foliage.',
        aiDiagnosis: 'Fully Grown Plant: Master Botanist criteria fulfilled. 100% growth completion.',
        xp: 100,
      },
      {
        dayOffset: 0,
        type: 'CHECKIN',
        watered: true,
        sunlightHours: 4,
        notes: "Today's daily check-in and watering completed. All daily tasks up-to-date!",
        aiDiagnosis: 'Optimal condition maintained. Ready for Certificate generation and display.',
        xp: 25,
      },
    ];

    const createdEvents = [];
    for (let i = 0; i < careMilestones.length; i++) {
      const m = careMilestones[i];
      const eventDate = new Date(now.getTime() - m.dayOffset * 24 * 60 * 60 * 1000);
      const opId = `op_seed_${userId.toString().slice(-4)}_${plant._id.toString().slice(-4)}_${i}_${Date.now()}`;

      const careEvent = await CareEvent.create({
        clientOperationId: opId,
        userId,
        plantId: plant._id.toString(),
        type: m.type,
        watered: m.watered,
        sunlightHours: m.sunlightHours,
        environmentCondition: 'Bright Indirect',
        verificationStatus: 'VERIFIED',
        evidenceImageReference: 'assets/images/plants/money_plant.png',
        photoPath: 'assets/images/plants/money_plant.png',
        notes: m.notes,
        aiDiagnosis: m.aiDiagnosis,
        xpEarned: m.xp,
        timestamp: eventDate,
      });
      createdEvents.push(careEvent);
    }

    console.log(`📋 [Seed] Created ${createdEvents.length} verified Care Events / Completed Tasks.`);
    console.log('\n======================================================');
    console.log('🎉 TEST USER CREATION & SEEDING COMPLETED SUCCESSFULLY!');
    console.log('======================================================');
    console.log('🔑 Login Credentials:');
    console.log(`   • Email:    ${TEST_USER.email}`);
    console.log(`   • Username: ${TEST_USER.username}`);
    console.log(`   • Password: ${TEST_USER.password}`);
    console.log(`   • Child:    ${TEST_USER.childName} (Age: ${TEST_USER.age})`);
    console.log(`   • XP:       ${TEST_USER.xp} (Level: Advanced)`);
    console.log(`   • Streak:   ${TEST_USER.careStreakDays} Days`);
    console.log('\n🪴 Seeded Plant Details:');
    console.log(`   • Plant:    ${plant.plantName} (${plant.speciesName})`);
    console.log(`   • Height:   ${plant.currentHeightCm} cm / ${plant.matureHeightCm} cm`);
    console.log(`   • Progress: ${(plant.growthProgress * 100).toFixed(0)}% (Stage: ${plant.lifecycleStage})`);
    console.log(`   • Status:   isCompleted = ${plant.isCompleted}, health = ${plant.health}%`);
    console.log(`   • Tasks:    All daily tasks completed + ${createdEvents.length} milestone history events`);
    console.log(`   • Certificate Eligible: YES (Ready in Certificate Screen & My Certifications)`);
    console.log('======================================================\n');

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ [Seed] Error seeding test user:', error);
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    process.exit(1);
  }
}

seedMoneyPlantTestUser();
