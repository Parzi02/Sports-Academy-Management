const db = require('../src/config/db');
const logger = require('../src/config/logger');

async function createProductsTable() {
  try {
    logger.info('Creating products table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price NUMERIC(10, 2) NOT NULL,
        image_base64 TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    logger.info('Products table created successfully.');

    // Seed dummy data if the table is empty
    const result = await db.query('SELECT COUNT(*) FROM products');
    if (parseInt(result.rows[0].count) === 0) {
      logger.info('Seeding initial products...');
      const products = [
        ['Roller Skates', 'High-quality professional roller skates for all levels.', 2500.00],
        ['Skate Helmet', 'Protective headgear designed for maximum safety.', 800.00],
        ['Wrist Guards', 'Durable wrist support for preventing injuries.', 450.00],
        ['Knee Pads', 'Comfortable and impact-resistant knee protection.', 550.00],
        ['Elbow Pads', 'Ergonomic elbow pads for skateboarding and skating.', 500.00],
        ['Bearing Lube / Speed Cream', 'Premium lubricant to keep bearings spinning fast and smooth.', 350.00],
      ];

      for (const product of products) {
        await db.query(
          'INSERT INTO products (name, description, price) VALUES ($1, $2, $3)',
          product
        );
      }
      logger.info('Initial products seeded successfully.');
    } else {
      logger.info('Products table already contains data, skipping seeding.');
    }
  } catch (error) {
    logger.error('Error creating products table:', error);
  } finally {
    process.exit(0);
  }
}

createProductsTable();
