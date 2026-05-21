const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();
const cron = require('node-cron');
const db = require('./config/db');
const logger = require('./config/logger');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Security Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Support Base64 images

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { error: true, message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Basic Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/member', require('./routes/member.routes'));
app.use('/api/products', require('./routes/products.routes'));

// Error Handler (must be last)
app.use(errorHandler);

// 7-Day Data Cleanup Cron Job
cron.schedule('0 0 * * *', async () => {
    try {
        logger.info('[CRON] Starting event cleanup...');
        const result = await db.query(`
            UPDATE events 
            SET image_base64 = NULL, description = NULL 
            WHERE date < CURRENT_DATE - INTERVAL '7 days' 
            AND status = 'past'
            AND (image_base64 IS NOT NULL OR description IS NOT NULL)
        `);
        logger.info(`[CRON] Event cleanup completed. Rows affected: ${result.rowCount}`);
    } catch (err) {
        logger.error('[CRON] Cleanup error:', err);
    }
});

// 7-Day Payment Screenshot Cleanup Cron Job
cron.schedule('0 0 * * *', async () => {
    try {
        logger.info('[CRON] Starting payment screenshot cleanup...');
        const result = await db.query(`
            UPDATE payments 
            SET screenshot_base64 = NULL 
            WHERE created_at < CURRENT_DATE - INTERVAL '7 days' 
            AND screenshot_base64 IS NOT NULL
        `);
        logger.info(`[CRON] Payment cleanup completed. Rows affected: ${result.rowCount}`);
    } catch (err) {
        logger.error('[CRON] Payment cleanup error:', err);
    }
});

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});

