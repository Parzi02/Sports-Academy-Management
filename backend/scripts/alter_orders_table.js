const db = require('../src/config/db');
const logger = require('../src/config/logger');

async function alterOrdersTable() {
  try {
    logger.info('Altering orders table to add payment fields...');
    await db.query(`
      ALTER TABLE orders
      ADD COLUMN IF NOT EXISTS utr_number VARCHAR(50),
      ADD COLUMN IF NOT EXISTS payment_proof TEXT;
    `);
    
    logger.info('Orders table altered successfully.');
  } catch (error) {
    logger.error('Error altering orders table:', error);
  } finally {
    process.exit(0);
  }
}

alterOrdersTable();
