const db = require('../config/db');
const logger = require('../config/logger');

// Admin Profile
exports.getProfile = async (req, res, next) => {
  try {
    const table = req.user.role === 'admin' ? 'coaches' : 'members';
    const query = `
      SELECT u.id, u.name, u.email, u.phone, u.address, u.profile_photo_base64, u.upi_id, b.name as branch_name
      FROM ${table} u
      LEFT JOIN branches b ON u.branch_id = b.id
      WHERE u.id = $1
    `;
    logger.info(`Fetching profile for ${req.user.role} ID: ${req.user.id}`);
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

exports.updateProfile = async (req, res, next) => {
  try {
    const { name, email, phone, address, profile_photo_base64 } = req.body;
    
    const table = req.user.role === 'admin' ? 'coaches' : 'members';
    await db.query(`
      UPDATE ${table} 
      SET name = $1, email = $2, phone = $3, address = $4, profile_photo_base64 = $5
      WHERE id = $6
    `, [name, email, phone, address, profile_photo_base64, req.user.id]);

    const selectQuery = `
      SELECT u.id, u.name, u.email, u.phone, u.address, u.profile_photo_base64, u.upi_id, b.name as branch_name
      FROM ${table} u
      LEFT JOIN branches b ON u.branch_id = b.id
      WHERE u.id = $1
    `;
    const result = await db.query(selectQuery, [req.user.id]);
    
    res.json({ message: 'Profile updated successfully', profile: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// Dashboard Stats
exports.getDashboardStats = async (req, res, next) => {
  try {
    const membersCount = await db.query(
      'SELECT COUNT(*) FROM members WHERE branch_id = $1 AND coach_id = $2',
      [req.branchId, req.user.id]
    );
    const eventsCount = await db.query(
      'SELECT COUNT(*) FROM events WHERE branch_id = $1',
      [req.branchId]
    );

    res.json({
      totalMembers: parseInt(membersCount.rows[0].count),
      totalEvents: parseInt(eventsCount.rows[0].count),
    });
  } catch (error) {
    next(error);
  }
};

// Member Management
exports.getMembers = async (req, res, next) => {
  const { search, batchId, status } = req.query;
  try {
    let query = `
      SELECT 
        u.id, u.name, u.phone, u.member_id, u.profile_photo_base64,
        u.coach_id, c.name as coach_name,
        e.payment_status, e.end_date as membership_end_date
      FROM members u
      LEFT JOIN coaches c ON u.coach_id = c.id
      LEFT JOIN enrollments e ON u.id = e.member_id
      WHERE u.branch_id = $1 AND u.coach_id = $2
    `;
    const params = [req.branchId, req.user.id];

    if (search) {
      query += ` AND (u.name ILIKE $${params.length + 1} OR u.member_id ILIKE $${params.length + 1})`;
      params.push(`%${search}%`);
    }

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
};

exports.getMemberById = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // 1. Fetch Member Profile
        const profileQuery = `
      SELECT 
        u.id, u.name, u.phone, u.email, u.dob, u.gender, u.address, u.member_id, u.profile_photo_base64,
        e.start_date as date_of_joining, e.payment_status as status, e.membership_type,
        b.name as batch_name, b.start_time as batch_time
      FROM members u
      LEFT JOIN enrollments e ON u.id = e.member_id
      LEFT JOIN batches b ON e.batch_id = b.id
      WHERE u.id = $1 AND u.branch_id = $2
    `;
    const profileRes = await db.query(profileQuery, [id, req.branchId]);

    if (profileRes.rows.length === 0) {
      const error = new Error('Member not found');
      error.statusCode = 404;
      throw error;
    }

    const profile = profileRes.rows[0];

    // Calculate Amount Due
    let amountDue = 500;
    const type = (profile.membership_type || '').toLowerCase();
    if (type.includes('quarterly')) amountDue = 1500;
    else if (type.includes('yearly')) amountDue = 6000;

    // 2. Fetch Attendance History (last 30)
    const attendanceQuery = `
      SELECT a.id, TO_CHAR(a.date, 'YYYY-MM-DD') as date, a.status, b.name as batch_name
      FROM attendance a
      JOIN batches b ON a.batch_id = b.id
      WHERE a.member_id = $1
      ORDER BY a.date DESC
      LIMIT 30
    `;
    const attendanceRes = await db.query(attendanceQuery, [id]);

    // 3. Fetch Payment History
    const paymentQuery = `
      SELECT id, amount, plan_type, utr_number, status, TO_CHAR(created_at, 'YYYY-MM-DD') as date
      FROM payments
      WHERE member_id = $1
      ORDER BY created_at DESC
    `;
    const paymentRes = await db.query(paymentQuery, [id]);

    res.json({
      ...profile,
      amount_due: amountDue,
      attendance: attendanceRes.rows,
      payments: paymentRes.rows,
    });
  } catch (error) {
    next(error);
  }
};

exports.recordCashPayment = async (req, res, next) => {
    const { id } = req.params;
    const { amount, planType } = req.body;

    try {
        await db.query('BEGIN');

        // 1. Verify existence of member in admin's branch
        const userCheck = await db.query('SELECT id FROM members WHERE id = $1 AND branch_id = $2', [id, req.branchId]);
        if (userCheck.rows.length === 0) {
            await db.query('ROLLBACK');
            const error = new Error('Member not found or access denied');
            error.statusCode = 404;
            throw error;
        }

        // 2. Insert payment record (status = approved, utr_number = CASH)
        const insertQuery = `
            INSERT INTO payments (member_id, amount, plan_type, utr_number, status, recorded_by) 
            VALUES ($1, $2, $3, 'CASH', 'success', $4)
        `;
        await db.query(insertQuery, [id, amount, planType, req.user.id]);


        // 3. Update enrollment status and end_date
        let daysToAdd = 30;
        const type = planType.toLowerCase();
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
        await db.query(updateEnrollmentQuery, [daysToAdd, id]);

        await db.query('COMMIT');
        res.json({ message: 'Cash payment recorded successfully' });
    } catch (error) {
        await db.query('ROLLBACK');
        next(error);
    }
};

exports.addMember = async (req, res, next) => {
    const { name, phone, email, dob, gender, address, batch_id, coach_id, membership_type, profile_photo_base64 } = req.body;
    try {
        if (!coach_id) {
            const error = new Error('Coach assignment is required');
            error.statusCode = 400;
            throw error;
        }

        await db.query('BEGIN');
        
        // 1. Create Member
        const userRes = await db.query(
            `INSERT INTO members (branch_id, phone, email, name, dob, gender, address, member_id, profile_photo_base64, coach_id) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
            [req.branchId, phone, email, name, dob, gender, address, `MEM${Date.now().toString().slice(-4)}`, profile_photo_base64, coach_id]
        );
        const userId = userRes.rows[0].id;

        // 2. Create Enrollment
        let daysToAdd = 30; // Default to 30 days
        const type = membership_type.toLowerCase();
        if (type.includes('quarterly')) daysToAdd = 90;
        else if (type.includes('yearly')) daysToAdd = 365;

        await db.query(
            `INSERT INTO enrollments (member_id, batch_id, membership_type, start_date, end_date, payment_status) 
             VALUES ($1, $2, $3, CURRENT_DATE, CURRENT_DATE + ($4 || ' days')::interval, 'due')`,
            [userId, batch_id, membership_type, daysToAdd]
        );

        await db.query('COMMIT');
        res.status(201).json({ message: 'Member added successfully', userId });
    } catch (error) {
        await db.query('ROLLBACK');
        next(error);
    }
};

// Attendance
exports.markAttendance = async (req, res, next) => {
    const { batchId, date, attendanceList } = req.body; // attendanceList: [{memberId, status}]
    try {
        // Security Check: Verify batch belongs to admin's branch
        const batchCheck = await db.query('SELECT id FROM batches WHERE id = $1 AND branch_id = $2', [batchId, req.branchId]);
        if (batchCheck.rows.length === 0) {
            const error = new Error('Batch not found or access denied');
            error.statusCode = 403;
            throw error;
        }

        const queries = attendanceList.map(item => {
            return db.query(
                `INSERT INTO attendance (member_id, batch_id, date, status, marked_by) 
                 VALUES ($1, $2, $3, $4, $5) 
                 ON CONFLICT (member_id, batch_id, date) DO UPDATE SET status = $4, marked_at = CURRENT_TIMESTAMP`,
                [item.memberId, batchId, date, item.status, req.user.id]
            );
        });
        await Promise.all(queries);
        res.json({ message: 'Attendance marked successfully' });
    } catch (error) {
        next(error);
    }
};


// Events
exports.createEvent = async (req, res, next) => {
    const { title, description, sport_category, event_category, date, start_time, end_time, venue, image_base64 } = req.body;
    try {
        const result = await db.query(
            `INSERT INTO events (branch_id, title, description, sport_category, event_category, date, start_time, end_time, venue, image_base64, created_by) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id`,
            [req.branchId, title, description, sport_category, event_category, date, start_time, end_time, venue, image_base64, req.user.id]
        );
        res.status(201).json({ message: 'Event created successfully', eventId: result.rows[0].id });
    } catch (error) {
        next(error);
    }
};

// Get Batches for dropdowns
exports.getBatches = async (req, res, next) => {
    try {
        const result = await db.query(
            `SELECT DISTINCT b.id, b.name, b.sport, b.start_time, b.end_time 
             FROM batches b 
             JOIN enrollments e ON b.id = e.batch_id 
             JOIN members m ON e.member_id = m.id 
             WHERE b.branch_id = $1 AND m.coach_id = $2`,
            [req.branchId, req.user.id]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Get Events List
exports.getEvents = async (req, res, next) => {
    try {
        const result = await db.query(
            'SELECT * FROM events WHERE branch_id = $1 ORDER BY date DESC',
            [req.branchId]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Get Attendance for a specific batch and date
exports.getAttendance = async (req, res, next) => {
    const { batchId, date } = req.query;
    try {
        // Security Check: Verify batch belongs to admin's branch
        const batchCheck = await db.query('SELECT id FROM batches WHERE id = $1 AND branch_id = $2', [batchId, req.branchId]);
        if (batchCheck.rows.length === 0) {
            const error = new Error('Batch not found or access denied');
            error.statusCode = 403;
            throw error;
        }

         const result = await db.query(
            `SELECT 
                u.id, 
                u.name, 
                u.member_id,
                a.status
             FROM enrollments e
             JOIN members u ON e.member_id = u.id
             LEFT JOIN attendance a ON u.id = a.member_id AND a.batch_id = $1 AND a.date = $2
             WHERE e.batch_id = $1 AND u.branch_id = $3 AND u.coach_id = $4`,
            [batchId, date, req.branchId, req.user.id]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

// Update Member Enrollment (Batch & Plan)
exports.updateMemberEnrollment = async (req, res, next) => {
    const { id } = req.params;
    const { batch_id, membership_type } = req.body;

    try {
        await db.query('BEGIN');

        // Security Check: Verify member belongs to admin's branch
        const memberCheck = await db.query(
            'SELECT id FROM members WHERE id = $1 AND branch_id = $2',
            [id, req.branchId]
        );

        if (memberCheck.rows.length === 0) {
            await db.query('ROLLBACK');
            const error = new Error('Member not found or access denied');
            error.statusCode = 404;
            throw error;
        }

        // Update enrollment
        const updateFields = [];
        const params = [id];
        let paramIndex = 2;

        if (batch_id) {
            updateFields.push(`batch_id = $${paramIndex++}`);
            params.push(batch_id);
        }
        if (membership_type) {
            updateFields.push(`membership_type = $${paramIndex++}`);
            params.push(membership_type);
        }

        if (updateFields.length > 0) {
            const updateQuery = `
                UPDATE enrollments 
                SET ${updateFields.join(', ')} 
                WHERE member_id = $1
            `;
            await db.query(updateQuery, params);
        }

        await db.query('COMMIT');
        res.json({ message: 'Enrollment updated successfully' });
    } catch (error) {
        await db.query('ROLLBACK');
        next(error);
    }
};

// Get dates with marked attendance in a range
exports.getMarkedDays = async (req, res, next) => {
    const { startDate, endDate } = req.query;
    try {
        const result = await db.query(
            `SELECT DISTINCT TO_CHAR(date, 'YYYY-MM-DD') as date
             FROM attendance a
             JOIN batches b ON a.batch_id = b.id
             WHERE b.branch_id = $1 AND a.date BETWEEN $2 AND $3`,
            [req.branchId, startDate, endDate]
        );
        res.json(result.rows.map(r => r.date));
    } catch (error) {
        next(error);
    }
};

// Get Coaches List
exports.getCoaches = async (req, res, next) => {
    try {
        const result = await db.query(
            'SELECT id, name, phone, upi_id FROM coaches WHERE branch_id = $1',
            [req.branchId]
        );
        res.json(result.rows);
    } catch (error) {
        next(error);
    }
};

module.exports = exports;
