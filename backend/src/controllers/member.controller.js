const db = require('../config/db');
const logger = require('../config/logger');

// Member Dashboard
exports.getDashboard = async (req, res, next) => {
    try {
        // Attendance %
        const attendanceCountRes = await db.query(
            'SELECT COUNT(*) FROM attendance WHERE member_id = $1 AND status = $2',
            [req.user.id, 'present']
        );
        const totalAttendanceRes = await db.query(
            'SELECT COUNT(*) FROM attendance WHERE member_id = $1',
            [req.user.id]
        );
        const total = parseInt(totalAttendanceRes.rows[0].count);
        const present = parseInt(attendanceCountRes.rows[0].count);
        const attendancePercentage = total > 0 ? (present / total) * 100 : 0;

        // Enrollment & Batch Info
        const enrollmentRes = await db.query(
            `SELECT e.payment_status, e.membership_type, e.end_date as due_date, 
                    b.name as batch_name, b.sport, b.start_time, b.end_time, c.name as coach_name 
             FROM enrollments e 
             JOIN batches b ON e.batch_id = b.id 
             LEFT JOIN users c ON b.coach_id = c.id
             WHERE e.member_id = $1`,
            [req.user.id]
        );
        
        const enrollment = enrollmentRes.rows[0] || {};
        
        // Today's Schedule (Assigned Batch)
        const todaySchedule = enrollment.batch_name ? [{
            title: enrollment.batch_name,
            start_time: enrollment.start_time,
            end_time: enrollment.end_time,
            coach: enrollment.coach_name || 'Assigned',
            venue: 'Academy Training Ground'
        }] : [];

        // Check if attendance is already marked today
        const todayAttendanceRes = await db.query(
            'SELECT COUNT(*) FROM attendance WHERE member_id = $1 AND date = CURRENT_DATE',
            [req.user.id]
        );
        const isAttendanceMarkedToday = parseInt(todayAttendanceRes.rows[0].count) > 0;

        // Check for pending payments (Wait for approval)
        const pendingPaymentRes = await db.query(
            'SELECT COUNT(*) FROM payments WHERE member_id = $1 AND status = $2',
            [req.user.id, 'pending']
        );
        const isPaymentPending = parseInt(pendingPaymentRes.rows[0].count) > 0;

        res.json({
            isAttendanceMarkedToday: isAttendanceMarkedToday,
            isPaymentPending: isPaymentPending,
            attendancePercentage: attendancePercentage.toFixed(2),
            attendedSessions: present,
            totalSessions: total,
            feeStatus: enrollment.payment_status || 'due',
            membershipType: enrollment.membership_type || 'standard',
            dueDate: enrollment.due_date,
            batchName: enrollment.batch_name || 'No Batch',
            sport: enrollment.sport || 'Academy Training',
            coachName: enrollment.coach_name || 'Assigned',
            batchTime: enrollment.start_time ? `${enrollment.start_time} - ${enrollment.end_time}` : 'TBD',
            todaySchedule: todaySchedule
        });
    } catch (error) {
        next(error);
    }
};

// Mark Self Attendance
exports.markSelfAttendance = async (req, res, next) => {
    const { imageBase64 } = req.body;
    
    if (!imageBase64) {
        const error = new Error('A selfie is required to mark attendance');
        error.statusCode = 400;
        return next(error);
    }

    try {
        // 1. Get the member's active batch
        const enrollmentRes = await db.query(
            'SELECT batch_id FROM enrollments WHERE member_id = $1 LIMIT 1',
            [req.user.id]
        );

        if (enrollmentRes.rows.length === 0) {
            const error = new Error('No active enrollment found to mark attendance');
            error.statusCode = 404;
            return next(error);
        }

        const batchId = enrollmentRes.rows[0].batch_id;

        // 2. Insert or update attendance for today
        await db.query(
            `INSERT INTO attendance (member_id, batch_id, date, status, marked_by, selfie_base64) 
             VALUES ($1, $2, CURRENT_DATE, 'present', $1, $3) 
             ON CONFLICT (member_id, batch_id, date) 
             DO UPDATE SET status = 'present', marked_at = CURRENT_TIMESTAMP, selfie_base64 = EXCLUDED.selfie_base64`,
            [req.user.id, batchId, imageBase64]
        );

        res.json({ message: 'Attendance marked successfully' });
    } catch (error) {
        next(error);
    }
};

// Attendance Logs
exports.getAttendanceLogs = async (req, res, next) => {
    try {
        const result = await db.query(
            'SELECT date, status FROM attendance WHERE member_id = $1 ORDER BY date DESC',
            [req.user.id]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Events
exports.getEvents = async (req, res, next) => {
    try {
        const result = await db.query(
            'SELECT id, title, sport_category, event_category, date, venue, status FROM events WHERE branch_id = $1 ORDER BY date DESC',
            [req.branchId]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

exports.toggleFavourite = async (req, res, next) => {
    const { eventId } = req.params;
    try {
        const check = await db.query(
            'SELECT id FROM event_favourites WHERE member_id = $1 AND event_id = $2',
            [req.user.id, eventId]
        );

        if (check.rows.length > 0) {
            await db.query('DELETE FROM event_favourites WHERE id = $1', [check.rows[0].id]);
            res.json({ isFavourite: false });
        } else {
            await db.query('INSERT INTO event_favourites (member_id, event_id) VALUES ($1, $2)', [req.user.id, eventId]);
            res.json({ isFavourite: true });
        }
    } catch (error) {
        next(error);
    }
};

// Fees & Payments
exports.recordPayment = async (req, res, next) => {
    const { amount, paymentMethod, upiTransactionId } = req.body;
    try {
        await db.query('BEGIN');
        
        // 1. Record Payment
        await db.query(
            `INSERT INTO payments (member_id, amount, payment_method, upi_transaction_id, status) 
             VALUES ($1, $2, $3, $4, $5)`,
            [req.user.id, amount, paymentMethod, upiTransactionId, 'success']
        );

        // 2. Update Enrollment Status
        await db.query(
            "UPDATE enrollments SET payment_status = 'paid' WHERE member_id = $1",
            [req.user.id]
        );

        await db.query('COMMIT');
        res.json({ message: 'Payment recorded successfully' });
    } catch (error) {
        await db.query('ROLLBACK');
        next(error);
    }
};

// Profile
exports.getProfile = async (req, res, next) => {
    try {
        const query = `
            SELECT u.name, u.phone, u.email, u.dob, u.gender, u.address, u.member_id, u.profile_photo_base64,
                   e.start_date as date_of_joining, b.sport, c.name as coach_name
            FROM users u
            LEFT JOIN enrollments e ON u.id = e.member_id
            LEFT JOIN batches b ON e.batch_id = b.id
            LEFT JOIN users c ON b.coach_id = c.id
            WHERE u.id = $1
        `;
        const result = await db.query(query, [req.user.id]);
        if (result.rows.length === 0) {
            const error = new Error('Profile not found');
            error.statusCode = 404;
            throw error;
        }
        res.json(result.rows[0]);
    } catch (error) {
        next(error);
    }
};

// Update Profile
exports.updateProfile = async (req, res, next) => {
    const { name, phone, address, profilePhotoBase64 } = req.body;
    try {
        const updateQuery = `
            UPDATE users 
            SET name = $1,
                phone = $2,
                address = $3,
                profile_photo_base64 = $4
            WHERE id = $5
            RETURNING *
        `;
        await db.query(updateQuery, [name, phone, address, profilePhotoBase64, req.user.id]);
        
        // Return updated profile
        const profileQuery = `
            SELECT u.name, u.phone, u.email, u.dob, u.gender, u.address, u.member_id, u.profile_photo_base64,
                   e.start_date as date_of_joining, b.sport, c.name as coach_name
            FROM users u
            LEFT JOIN enrollments e ON u.id = e.member_id
            LEFT JOIN batches b ON e.batch_id = b.id
            LEFT JOIN users c ON b.coach_id = c.id
            WHERE u.id = $1
        `;
        const result = await db.query(profileQuery, [req.user.id]);
        res.json(result.rows[0]);
    } catch (error) {
        next(error);
    }
};

