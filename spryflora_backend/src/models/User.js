import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: {
      type: String,
      required: true,
      select: false,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    childName: {
      type: String,
      trim: true,
    },
    age: {
      type: Number,
      default: 8,
    },
    school: {
      type: String,
      default: 'Spry Academy',
      trim: true,
    },
    favoritePlant: {
      type: String,
      default: 'Tulsi',
      trim: true,
    },
    profilePhotoUrl: {
      type: String,
      default: null,
    },
    xp: {
      type: Number,
      default: 120,
      min: 0,
    },
    careStreakDays: {
      type: Number,
      default: 1,
      min: 0,
    },
    completedPlantsCount: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(doc, ret) {
        delete ret.passwordHash;
        delete ret.__v;
        ret.id = ret._id.toString();
        ret.childName = ret.childName || ret.name;
        return ret;
      },
    },
  }
);

export const User = mongoose.model('User', userSchema);
