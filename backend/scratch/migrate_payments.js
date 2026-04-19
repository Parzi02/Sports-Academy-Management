const db = require('../src/config/db');

async function migrate() {
    try {
        console.log('Starting migration...');
        
        // Add new values to enum
        await db.query("ALTER TYPE payment_method_type ADD VALUE IF NOT EXISTS 'GPay'");
        await db.query("ALTER TYPE payment_method_type ADD VALUE IF NOT EXISTS 'PhonePe'");
        await db.query("ALTER TYPE payment_method_type ADD VALUE IF NOT EXISTS 'Paytm'");
        await db.query("ALTER TYPE payment_method_type ADD VALUE IF NOT EXISTS 'Amazon Pay'");
        console.log('Updated payment_method_type enum.');

        // Drop redundant column
        await db.query("ALTER TABLE payments DROP COLUMN IF EXISTS upi_transaction_id");
        console.log('Dropped upi_transaction_id column.');

        console.log('Migration successful!');
    } catch (error) {
        console.error('Migration failed:', error);
    } finally {
        process.exit();
    }
}

migrate();
