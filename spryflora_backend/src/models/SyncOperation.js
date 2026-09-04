import mongoose from 'mongoose';

const syncOperationSchema = new mongoose.Schema(
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
    operationType: {
      type: String,
      enum: ['CREATE', 'UPDATE', 'DELETE', 'UPSERT'],
      required: true,
    },
    entityType: {
      type: String,
      enum: ['PLANT', 'CHECKIN', 'USER_PROFILE'],
      required: true,
    },
    entityId: {
      type: String,
      default: null,
    },
    payload: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    status: {
      type: String,
      enum: ['PROCESSED', 'SKIPPED_DUPLICATE', 'FAILED'],
      default: 'PROCESSED',
    },
    processedAt: {
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

export const SyncOperation = mongoose.model('SyncOperation', syncOperationSchema);
