const db = require('../src/config/db');
const logger = require('../src/config/logger');

async function migrateOrders() {
  try {
    logger.info('Migrating orders to use JSON items...');
    await db.query('BEGIN');
    
    // Drop order_items table completely as requested
    await db.query(`DROP TABLE IF EXISTS order_items;`);
    
    // Add items column to orders if it doesn't exist
    await db.query(`
      ALTER TABLE orders 
      ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]';
    `);

    await db.query('COMMIT');
    logger.info('Successfully migrated orders to use JSON items and dropped order_items table.');
  } catch (error) {
    await db.query('ROLLBACK');
    logger.error('Error during migration:', error);
  } finally {
    process.exit(0);
  }
}

migrateOrders();
