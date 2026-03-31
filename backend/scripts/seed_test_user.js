const db = require('../src/config/db');

async function seed() {
  try {
    // 1. Create a default branch
    const branchRes = await db.query(
      "INSERT INTO branches (name, location) VALUES ('Main Academy', 'Koramangala') RETURNING id"
    );
    const branchId = branchRes.rows[0].id;
    console.log(`Created branch with ID: ${branchId}`);

    // 2. Create a test user
    const userRes = await db.query(
      "INSERT INTO users (name, phone, role, branch_id) VALUES ('Test User', '919876543210', 'admin', $1) RETURNING *",
      [branchId]
    );
    console.log('Created user:', userRes.rows[0]);

    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seed();
