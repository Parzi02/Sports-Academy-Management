const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();
const cron = require('node-cron');
const db = require('./config/db');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Support Base64 images

// Basic Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/member', require('./routes/member.routes'));

// 7-Day Data Cleanup Cron Job
cron.schedule('0 0 * * *', async () => {
    try {
        console.log('[CRON] Starting event cleanup...');
        const result = await db.query(`
            UPDATE events 
            SET image_base64 = NULL, description = NULL 
            WHERE date < CURRENT_DATE - INTERVAL '7 days' 
            AND status = 'past'
            AND (image_base64 IS NOT NULL OR description IS NOT NULL)
        `);
        console.log(`[CRON] Event cleanup completed. Rows affected: ${result.rowCount}`);
    } catch (err) {
        console.error('[CRON] Cleanup error:', err);
    }
});

// 7-Day Payment Screenshot Cleanup Cron Job
cron.schedule('0 0 * * *', async () => {
    try {
        console.log('[CRON] Starting payment screenshot cleanup...');
        const result = await db.query(`
            UPDATE payments 
            SET screenshot_base64 = NULL 
            WHERE created_at < CURRENT_DATE - INTERVAL '7 days' 
            AND screenshot_base64 IS NOT NULL
        `);
        console.log(`[CRON] Payment cleanup completed. Rows affected: ${result.rowCount}`);
    } catch (err) {
        console.error('[CRON] Payment cleanup error:', err);
    }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
