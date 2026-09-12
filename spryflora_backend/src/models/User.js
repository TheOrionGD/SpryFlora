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
    username: {
      type: String,
      lowercase: true,
      trim: true,
    },
    dob: {
      type: String,
      default: '',
    },
    childName: {
      type: String,
      trim: true,
    },
    age: {
      type: Number,
      default: null,
    },
    school: {
      type: String,
      default: '',
      trim: true,
    },
    favoritePlant: {
      type: String,
      default: '',
      trim: true,
    },
    profilePhotoUrl: {
      type: String,
      default: null,
    },
    xp: {
      type: Number,
      default: 0,
      min: 0,
    },
    careStreakDays: {
      type: Number,
      default: 0,
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
        ret.username = ret.username || ret.email.split('@')[0];
        return ret;
      },
    },
  }
);

export const User = mongoose.model('User', userSchema);

