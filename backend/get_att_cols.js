const db = require('./src/config/db');
db.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'attendance'").then(res => {
  require('fs').writeFileSync('att_cols.txt', JSON.stringify(res.rows));
  process.exit(0);
});
