import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function cleanExceptTester() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 10000 });
    const db = mongoose.connection.db;

    console.log(`Connected to database: "${db.databaseName}"`);

    // 1. Delete all users except reviewer@spryflora.com
    const userResult = await db.collection('users').deleteMany({ email: { $ne: 'reviewer@spryflora.com' } });
    console.log(`[CLEANED] users: deleted ${userResult.deletedCount} non-tester user(s).`);

    // 2. Delete all plants
    const plantResult = await db.collection('plants').deleteMany({});
    console.log(`[CLEANED] plants: deleted ${plantResult.deletedCount} plant(s).`);

    // 3. Delete all care events
    const careResult = await db.collection('careevents').deleteMany({});
    console.log(`[CLEANED] careevents: deleted ${careResult.deletedCount} care event(s).`);

    // 4. Delete all sync operations
    const syncResult = await db.collection('syncoperations').deleteMany({});
    console.log(`[CLEANED] syncoperations: deleted ${syncResult.deletedCount} sync operation(s).`);

    console.log('\n================ DATABASE STATUS AFTER CLEANUP ================');
    const collections = await db.listCollections().toArray();
    for (const c of collections) {
      const count = await db.collection(c.name).countDocuments();
      console.log(`- ${c.name}: ${count} document(s)`);
    }

    const remainingUsers = await db.collection('users').find({}).toArray();
    console.log('\nPreserved Tester User(s):');
    remainingUsers.forEach(u => {
      console.log(`  - Email: ${u.email} | Name: ${u.name} | Username: ${u.username}`);
    });
    console.log('===============================================================\n');

  } catch (error) {
    console.error('Error cleaning database:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
  }
}

cleanExceptTester();
