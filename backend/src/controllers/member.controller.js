const db = require('../config/db');

// Member Dashboard
exports.getDashboard = async (req, res) => {
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
            `SELECT e.payment_status, e.membership_type, b.name as batch_name, b.sport, b.start_time, b.end_time, c.name as coach_name 
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

        res.json({
            isAttendanceMarkedToday: isAttendanceMarkedToday,
            attendancePercentage: attendancePercentage.toFixed(2),
            attendedSessions: present,
            totalSessions: total,
            feeStatus: enrollment.payment_status || 'due',
            membershipType: enrollment.membership_type || 'standard',
            batchName: enrollment.batch_name || 'No Batch',
            sport: enrollment.sport || 'Academy Training',
            coachName: enrollment.coach_name || 'Assigned',
            batchTime: enrollment.start_time ? `${enrollment.start_time} - ${enrollment.end_time}` : 'TBD',
            todaySchedule: todaySchedule
        });
    } catch (error) {
        console.error('Failed to fetch dashboard:', error);
        res.status(500).json({ error: 'Failed to fetch dashboard' });
    }
};

// Mark Self Attendance
exports.markSelfAttendance = async (req, res) => {
    const { imageBase64 } = req.body;
    
    if (!imageBase64) {
        return res.status(400).json({ error: 'A selfie is required to mark attendance' });
    }

    try {
        // 1. Get the member's active batch
        const enrollmentRes = await db.query(
            'SELECT batch_id FROM enrollments WHERE member_id = $1 LIMIT 1',
            [req.user.id]
        );

        if (enrollmentRes.rows.length === 0) {
            return res.status(404).json({ error: 'No active enrollment found to mark attendance' });
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
        console.error('Failed to mark self attendance:', error);
        res.status(500).json({ error: 'Failed to mark attendance' });
    }
};

// Attendance Logs
exports.getAttendanceLogs = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT date, status FROM attendance WHERE member_id = $1 ORDER BY date DESC',
            [req.user.id]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch attendance logs' });
    }
};

// Events
exports.getEvents = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT id, title, sport_category, event_category, date, venue, status FROM events WHERE branch_id = $1 ORDER BY date DESC',
            [req.branchId]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch events' });
    }
};

exports.toggleFavourite = async (req, res) => {
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
        res.status(500).json({ error: 'Failed to toggle favourite' });
    }
};

// Fees & Payments
exports.recordPayment = async (req, res) => {
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
        res.status(500).json({ error: 'Failed to record payment' });
    }
};

// Profile
exports.getProfile = async (req, res) => {
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
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Failed to fetch profile:', error);
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
};

// Update Profile
exports.updateProfile = async (req, res) => {
    const { name, phone, address, profilePhotoBase64 } = req.body;
    try {
        const query = `
            UPDATE users 
            SET name = COALESCE($1, name),
                phone = COALESCE($2, phone),
                address = COALESCE($3, address),
                profile_photo_base64 = COALESCE($4, profile_photo_base_64)
            WHERE id = $5
            RETURNING *
        `;
        // Wait, I should use snake_case for columns like profile_photo_base64
        // Let's re-verify the column name. It was profile_photo_base64 in select.
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
        console.error('Failed to update profile:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
};
