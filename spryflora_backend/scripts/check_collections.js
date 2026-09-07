import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function check() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 8000 });
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('--- DATABASE STATUS ---');
    console.log('Database Name:', mongoose.connection.db.databaseName);
    for (const c of collections) {
      const count = await mongoose.connection.db.collection(c.name).countDocuments();
      console.log(`${c.name}: ${count} documents`);
    }
  } catch (err) {
    console.error('Error connecting to MongoDB:', err.message);
  } finally {
    await mongoose.disconnect();
  }
}

check();
