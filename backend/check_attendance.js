const db = require('./src/config/db');

async function checkAttendanceSchema() {
  try {
    const res = await db.query(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'attendance'"
    );
    console.log("Attendance Columns:");
    res.rows.forEach(row => console.log(`- ${row.column_name}: ${row.data_type}`));
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkAttendanceSchema();
