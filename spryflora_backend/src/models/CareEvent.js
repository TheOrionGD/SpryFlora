import mongoose from 'mongoose';

const careEventSchema = new mongoose.Schema(
  {
    clientOperationId: {
      type: String,
      required: true,
      unique: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    plantId: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: ['WATERING', 'SUNLIGHT', 'CHECKIN', 'DIAGNOSIS'],
      required: true,
    },
    watered: {
      type: Boolean,
      default: true,
    },
    sunlightHours: {
      type: Number,
      default: 4,
    },
    environmentCondition: {
      type: String,
      default: 'Bright Indirect',
    },
    verificationStatus: {
      type: String,
      enum: ['VERIFIED', 'FAILED', 'PENDING', 'UNVERIFIED'],
      default: 'UNVERIFIED',
    },
    evidenceImageReference: {
      type: String,
      default: null,
    },
    photoPath: {
      type: String,
      default: null,
    },
    notes: {
      type: String,
      default: null,
    },
    aiDiagnosis: {
      type: String,
      default: null,
    },
    xpEarned: {
      type: Number,
      default: 0,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(doc, ret) {
        ret.id = ret._id.toString();
        ret.userId = ret.userId ? ret.userId.toString() : ret.userId;
        delete ret.__v;
        return ret;
      },
    },
  }
);

careEventSchema.index({ userId: 1, plantId: 1, timestamp: -1 });

export const CareEvent = mongoose.model('CareEvent', careEventSchema);
