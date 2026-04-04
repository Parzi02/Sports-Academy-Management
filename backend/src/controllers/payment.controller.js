const db = require('../config/db');

// Member: Submit Payment Proof
exports.submitPayment = async (req, res) => {
    const { amount, planType, utrNumber, screenshotBase64 } = req.body;
    
    if (!amount || !planType || !utrNumber || !screenshotBase64) {
        return res.status(400).json({ error: 'Missing required parameters' });
    }

    try {
        // Check for duplicate UTR
        const checkUtr = await db.query('SELECT id FROM payments WHERE utr_number = $1', [utrNumber]);
        if (checkUtr.rows.length > 0) {
            return res.status(400).json({ error: 'Duplicate Submission: This UTR is already recorded.' });
        }

        // Insert new payment with pending status
        const insertQuery = `
            INSERT INTO payments (member_id, amount, plan_type, utr_number, screenshot_base64, status) 
            VALUES ($1, $2, $3, $4, $5, 'pending')
            RETURNING id, amount, plan_type, status
        `;
        const result = await db.query(insertQuery, [
            req.user.id, amount, planType, utrNumber, screenshotBase64
        ]);

        res.status(201).json({ 
            message: 'Payment proof submitted for verification',
            payment: result.rows[0]
        });
    } catch (error) {
        console.error('Failed to submit payment:', error);
        res.status(500).json({ error: 'Failed to submit payment verification' });
    }
};

// Member: Get Payment History
exports.getPaymentHistory = async (req, res) => {
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
        console.error('Failed to fetch payment history:', error);
        res.status(500).json({ error: 'Failed to fetch history' });
    }
};

// Admin: Get Pending Payments
exports.getPendingPayments = async (req, res) => {
    try {
        const query = `
            SELECT p.id, p.amount, p.plan_type, p.utr_number, p.status, p.created_at, p.screenshot_base64,
                   u.name as member_name, u.phone as member_phone, u.member_id as member_sid
            FROM payments p
            JOIN users u ON p.member_id = u.id
            WHERE p.status = 'pending'
            ORDER BY p.created_at ASC
        `;
        // Assuming admin can see all for their branch or globally. 
        // Admin might have req.branchId. We will assume global for academy unless filtered.
        const result = await db.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Failed to fetch pending payments:', error);
        res.status(500).json({ error: 'Failed to fetch pending payments' });
    }
};

// Admin: Approve or Reject a payment
exports.updatePaymentStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body; // 'approved' or 'rejected'

    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
    }

    try {
        await db.query('BEGIN');

        // Update payment status
        const updatePaymentQuery = `
            UPDATE payments 
            SET status = $1 
            WHERE id = $2 
            RETURNING member_id, plan_type
        `;
        const paymentRes = await db.query(updatePaymentQuery, [status, id]);

        if (paymentRes.rows.length === 0) {
            await db.query('ROLLBACK');
            return res.status(404).json({ error: 'Payment not found' });
        }

        // If approved, update user's subscription end date
        if (status === 'approved') {
            const { member_id, plan_type } = paymentRes.rows[0];
            
            // Calculate days to add based on plan_type
            let daysToAdd = 30;
            const type = plan_type.toLowerCase();
            if (type.includes('quarterly')) daysToAdd = 90;
            else if (type.includes('yearly')) daysToAdd = 365;

            // Update enrollments table:
            // Check if end_date is NULL or in the past, set from CURRENT_DATE + interval
            // If in the future, add to existing date.
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
        res.json({ message: `Payment ${status} successfully` });
    } catch (error) {
        await db.query('ROLLBACK');
        console.error('Failed to update payment status:', error);
        res.status(500).json({ error: 'Failed to update payment' });
    }
};
