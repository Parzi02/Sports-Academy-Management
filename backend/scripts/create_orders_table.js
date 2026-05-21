const db = require('../src/config/db');
const logger = require('../src/config/logger');

async function createOrdersTable() {
  try {
    logger.info('Creating orders tables...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        member_id UUID REFERENCES members(id),
        coach_id UUID REFERENCES coaches(id),
        total_amount NUMERIC(10, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        items JSONB DEFAULT '[]',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    logger.info('Orders tables created successfully.');
  } catch (error) {
    logger.error('Error creating orders tables:', error);
  } finally {
    process.exit(0);
  }
}

createOrdersTable();
