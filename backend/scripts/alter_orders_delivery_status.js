const db = require('../src/config/db');

async function runMigration() {
  const client = await db.pool.connect();
  try {
    await client.query("ALTER TABLE orders ADD COLUMN delivery_status VARCHAR(50) DEFAULT 'pending';");
    console.log("Successfully added delivery_status column.");
  } catch (err) {
    if (err.code === '42701') {
      console.log("Column delivery_status already exists.");
    } else {
      console.error("Migration failed:", err);
    }
  } finally {
    client.release();
    process.exit(0);
  }
}

runMigration();
