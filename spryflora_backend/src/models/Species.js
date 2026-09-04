import mongoose from 'mongoose';

const speciesSchema = new mongoose.Schema(
  {
    speciesId: {
      type: String,
      required: true,
      unique: true,
    },
    commonName: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    botanicalName: {
      type: String,
      required: true,
      trim: true,
    },
    matureHeightCm: {
      type: Number,
      required: true,
      default: 50.0,
    },
    initialHeightCm: {
      type: Number,
      default: 2.0,
    },
    growthDurationDays: {
      type: Number,
      required: true,
      default: 150,
    },
    wateringIntervalDays: {
      type: Number,
      required: true,
      default: 3,
    },
    wateringTolerance: {
      type: String,
      default: 'Moderate',
    },
    sunlightRequirements: {
      type: String,
      default: 'Bright Indirect',
    },
    targetSunlightHours: {
      type: Number,
      default: 4,
    },
    lifecycleStages: {
      type: [String],
      default: ['Seed', 'Sprout', 'Seedling', 'Young Plant', 'Growing Plant', 'Fully Grown Plant'],
    },
    careInstructions: {
      type: String,
      default: 'Ensure regular hydration and adequate light exposure according to species needs.',
    },
    description: {
      type: String,
      default: 'Beautiful plant species.',
    },
    idealTemp: {
      type: String,
      default: '18°C - 28°C',
    },
    image: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(doc, ret) {
        ret.id = ret._id.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

export const Species = mongoose.model('Species', speciesSchema);
