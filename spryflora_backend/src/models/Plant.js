import mongoose from 'mongoose';

const plantSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    clientPlantId: {
      type: String,
    },
    plantName: {
      type: String,
      required: true,
      trim: true,
    },
    speciesName: {
      type: String,
      required: true,
      trim: true,
    },
    speciesId: {
      type: String,
      default: null,
    },
    commonName: {
      type: String,
      trim: true,
    },
    botanicalName: {
      type: String,
      trim: true,
    },
    imageUrl: {
      type: String,
      default: null,
    },
    initialPhotoPath: {
      type: String,
      default: null,
    },
    location: {
      type: String,
      default: 'Living Room',
    },
    plantedAt: {
      type: Date,
      default: Date.now,
    },
    plantingDate: {
      type: Date,
      default: Date.now,
    },
    lifespanDays: {
      type: Number,
      default: 150,
      min: 1,
    },
    growthDurationDays: {
      type: Number,
      default: 150,
      min: 1,
    },
    wateringIntervalDays: {
      type: Number,
      default: 3,
      min: 1,
    },
    targetSunlightHours: {
      type: Number,
      default: 4,
    },
    sunlightHoursToday: {
      type: Number,
      default: 0,
    },
    lastSunlightDate: {
      type: Date,
      default: null,
    },
    lastWateredAt: {
      type: Date,
      default: Date.now,
    },
    lastWateredDate: {
      type: Date,
      default: Date.now,
    },
    nextWateringAt: {
      type: Date,
      default: () => new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    },
    nextWateringDate: {
      type: Date,
      default: () => new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    },
    initialHeightCm: {
      type: Number,
      default: 2.0,
    },
    matureHeightCm: {
      type: Number,
      default: 50.0,
    },
    currentHeightCm: {
      type: Number,
      default: 2.0,
    },
    healthScore: {
      type: Number,
      default: 95,
      min: 0,
      max: 100,
    },
    health: {
      type: Number,
      default: 95,
      min: 0,
      max: 100,
    },
    hydrationScore: {
      type: Number,
      default: 95,
      min: 0,
      max: 100,
    },
    sunlightScore: {
      type: Number,
      default: 95,
      min: 0,
      max: 100,
    },
    consistencyScore: {
      type: Number,
      default: 95,
      min: 0,
      max: 100,
    },
    healthStatus: {
      type: String,
      default: 'Optimal',
    },
    lifecycleStage: {
      type: String,
      default: 'Seed',
    },
    growthProgress: {
      type: Number,
      default: 0.0,
      min: 0.0,
      max: 1.0,
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    isCompletedManually: {
      type: Boolean,
      default: false,
    },
    version: {
      type: Number,
      default: 1,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(doc, ret) {
        ret.id = ret.clientPlantId || ret._id.toString();
        ret._id = ret._id.toString();
        ret.userId = ret.userId.toString();
        ret.commonName = ret.commonName || ret.speciesName;
        ret.botanicalName = ret.botanicalName || ret.speciesName;
        ret.plantingDate = ret.plantingDate || ret.plantedAt;
        ret.lastWateredDate = ret.lastWateredDate || ret.lastWateredAt;
        ret.nextWateringDate = ret.nextWateringDate || ret.nextWateringAt;
        delete ret.__v;
        return ret;
      },
    },
  }
);

plantSchema.index({ userId: 1 });
plantSchema.index({ userId: 1, clientPlantId: 1 });

export const Plant = mongoose.model('Plant', plantSchema);
