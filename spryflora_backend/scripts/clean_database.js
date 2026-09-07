import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function cleanDatabase() {
  try {
    console.log('Connecting to MongoDB database...');
    await mongoose.connect(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 10000 });
    const db = mongoose.connection.db;
    console.log(`Connected to database: "${db.databaseName}"`);

    const collections = await db.listCollections().toArray();
    console.log(`Found ${collections.length} collections.`);

    const report = [];

    for (const collInfo of collections) {
      const collName = collInfo.name;
      // Skip system collections if any
      if (collName.startsWith('system.')) continue;

      const coll = db.collection(collName);
      const countBefore = await coll.countDocuments();
      const result = await coll.deleteMany({});
      report.push({
        collection: collName,
        before: countBefore,
        deleted: result.deletedCount,
      });
      console.log(`[CLEANED] ${collName}: deleted ${result.deletedCount} of ${countBefore} documents.`);
    }

    console.log('\n================ CLEAN REPORT ================');
    console.table(report);
    console.log('All collections have been emptied successfully.');
    console.log('==============================================\n');
  } catch (error) {
    console.error('Failed to clean database:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
  }
}

cleanDatabase();
