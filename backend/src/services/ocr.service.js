const { createWorker } = require('tesseract.js');
const logger = require('../config/logger');

/**
 * Detects the payment app from a base64 encoded screenshot.
 * @param {string} base64Image - The base64 encoded image string.
 * @returns {Promise<string>} - The detected payment method ('GPay', 'PhonePe', 'Paytm', 'Amazon Pay', or 'upi').
 */
exports.detectPaymentApp = async (base64Image) => {
    try {
        logger.info('Starting OCR detection on payment screenshot...');
        
        // Clean base64 if it has prefix
        const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");
        const imageBuffer = Buffer.from(base64Data, 'base64');

        const worker = await createWorker('eng');
        const { data: { text } } = await worker.recognize(imageBuffer);
        await worker.terminate();

        const lowerText = text.toLowerCase();
        logger.debug(`OCR Result: ${text}`);

        if (lowerText.includes('google pay') || lowerText.includes('gpay')) {
            return 'GPay';
        }
        if (lowerText.includes('phonepe')) {
            return 'PhonePe';
        }
        if (lowerText.includes('paytm')) {
            return 'Paytm';
        }
        if (lowerText.includes('amazon pay')) {
            return 'Amazon Pay';
        }

        return 'upi'; // Default fallback
    } catch (error) {
        logger.error('OCR Detection error:', error);
        return 'upi'; // Fallback on error
    }
};
