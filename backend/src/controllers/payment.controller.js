const db = require('../config/db');
const logger = require('../config/logger');
const ocrService = require('../services/ocr.service');

// Member: Submit Payment Proof
exports.submitPayment = async (req, res, next) => {
    const { amount, planType, utrNumber, screenshotBase64 } = req.body;
    
    try {
        // Check for duplicate UTR
        const checkUtr = await db.query('SELECT id FROM payments WHERE utr_number = $1', [utrNumber]);
        if (checkUtr.rows.length > 0) {
            const error = new Error('Duplicate Submission: This UTR is already recorded.');
            error.statusCode = 400;
            throw error;
        }

        // Detect payment app from screenshot
        const paymentMethod = await ocrService.detectPaymentApp(screenshotBase64);
        logger.info(`Detected payment method: ${paymentMethod}`);

        // Insert new payment with pending status
        const insertQuery = `
            INSERT INTO payments (member_id, amount, plan_type, utr_number, screenshot_base64, status, payment_method) 
            VALUES ($1, $2, $3, $4, $5, 'pending', $6)
            RETURNING id, amount, plan_type, status, payment_method
        `;
        const result = await db.query(insertQuery, [
            req.user.id, amount, planType, utrNumber, screenshotBase64, paymentMethod
        ]);

        res.status(201).json({ 
            message: 'Payment proof submitted for verification',
            payment: result.rows[0]
        });
    } catch (error) {
        next(error);
    }
};

// Member: Get Payment History
exports.getPaymentHistory = async (req, res, next) => {
    try {
        const query = `
            SELECT id, amount, plan_type, utr_number, status, created_at 
            FROM payments 
            WHERE member_id = $1 
            ORDER BY created_at DESC
        `;
        const result = await db.query(query, [req.user.id]);
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Admin: Get Pending Payments
exports.getPendingPayments = async (req, res, next) => {
    try {
        const query = `
            SELECT p.id, p.amount, p.plan_type, p.utr_number, p.status, p.created_at, p.screenshot_base64,
                   u.name as member_name, u.phone as member_phone, u.member_id as member_sid
            FROM payments p
            JOIN members u ON p.member_id = u.id
            WHERE p.status = 'pending' AND u.branch_id = $1 AND u.coach_id = $2
            ORDER BY p.created_at ASC
        `;
        const result = await db.query(query, [req.branchId, req.user.id]);
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Admin: Approve or Reject a payment
exports.updatePaymentStatus = async (req, res, next) => {
    const { id } = req.params;
    const { status } = req.body; // 'success' or 'failed'

    if (!['success', 'failed'].includes(status)) {
        const error = new Error('Invalid status. Use success or failed.');
        error.statusCode = 400;
        return next(error);
    }

    try {
        await db.query('BEGIN');

        // Update payment status (security check: ensure the payment belongs to a user in the admin's branch)
        const checkQuery = `
            SELECT p.member_id, p.plan_type 
            FROM payments p
            JOIN members u ON p.member_id = u.id
            WHERE p.id = $1 AND u.branch_id = $2
        `;
        const checkRes = await db.query(checkQuery, [id, req.branchId]);
        
        if (checkRes.rows.length === 0) {
            await db.query('ROLLBACK');
            const error = new Error('Payment not found or access denied');
            error.statusCode = 404;
            throw error;
        }

        const { member_id, plan_type } = checkRes.rows[0];

        const updatePaymentQuery = `
            UPDATE payments 
            SET status = $1 
            WHERE id = $2
        `;
        await db.query(updatePaymentQuery, [status, id]);

        // If success (approved), update user's subscription end date
        if (status === 'success') {
            // Calculate days to add based on plan_type
            let daysToAdd = 30;
            const type = plan_type.toLowerCase();
            if (type.includes('quarterly')) daysToAdd = 90;
            else if (type.includes('yearly')) daysToAdd = 365;

            const updateEnrollmentQuery = `
                UPDATE enrollments 
                SET end_date = CASE 
                    WHEN end_date IS NULL OR end_date < CURRENT_DATE THEN CURRENT_DATE + ($1 || ' days')::interval
                    ELSE end_date + ($1 || ' days')::interval
                END,
                payment_status = 'paid'
                WHERE member_id = $2
            `;
            await db.query(updateEnrollmentQuery, [daysToAdd, member_id]);
        }

        await db.query('COMMIT');
        res.json({ message: `Payment ${status === 'success' ? 'approved' : 'rejected'} successfully` });
    } catch (error) {
        await db.query('ROLLBACK');
        next(error);
    }
};


