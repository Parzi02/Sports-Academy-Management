const db = require('../config/db');
const logger = require('../config/logger');

// Admin Profile
exports.getProfile = async (req, res, next) => {
  try {
    const query = `
      SELECT u.id, u.name, u.email, u.phone, u.address, u.profile_photo_base64, b.name as branch_name
      FROM users u
      LEFT JOIN branches b ON u.branch_id = b.id
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

exports.updateProfile = async (req, res, next) => {
  try {
    const { name, email, phone, address, profile_photo_base64 } = req.body;
    
    await db.query(`
      UPDATE users 
      SET name = $1, email = $2, phone = $3, address = $4, profile_photo_base64 = $5
      WHERE id = $6
    `, [name, email, phone, address, profile_photo_base64, req.user.id]);

    const selectQuery = `
      SELECT u.id, u.name, u.email, u.phone, u.address, u.profile_photo_base64, b.name as branch_name
      FROM users u
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
      'SELECT COUNT(*) FROM users WHERE branch_id = $1 AND role = $2',
      [req.branchId, 'member']
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
    let query = 'SELECT id, name, phone, member_id, role, profile_photo_base64 FROM users WHERE branch_id = $1 AND role = $2';
    const params = [req.branchId, 'member'];

    if (search) {
      query += ` AND (name ILIKE $${params.length + 1} OR member_id ILIKE $${params.length + 1})`;
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
    const query = `
      SELECT 
        u.id, u.name, u.phone, u.email, u.dob, u.gender, u.address, u.member_id, u.profile_photo_base64,
        e.start_date as date_of_joining, e.payment_status as status,
        b.name as batch_name, b.start_time as batch_time
      FROM users u
      LEFT JOIN enrollments e ON u.id = e.member_id
      LEFT JOIN batches b ON e.batch_id = b.id
      WHERE u.id = $1 AND u.branch_id = $2
    `;
    const result = await db.query(query, [id, req.branchId]);

    if (result.rows.length === 0) {
      const error = new Error('Member not found');
      error.statusCode = 404;
      throw error;
    }

    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
};

exports.addMember = async (req, res, next) => {
    const { name, phone, email, dob, gender, address, batch_id, membership_type, profile_photo_base64 } = req.body;
    try {
        await db.query('BEGIN');
        
        // 1. Create User
        const userRes = await db.query(
            `INSERT INTO users (branch_id, phone, email, name, dob, gender, address, role, member_id, profile_photo_base64) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
            [req.branchId, phone, email, name, dob, gender, address, 'member', `MEM${Date.now().toString().slice(-4)}`, profile_photo_base64]
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
            'SELECT id, name, sport, start_time, end_time FROM batches WHERE branch_id = $1',
            [req.branchId]
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
        const result = await db.query(
            `SELECT 
                u.id, 
                u.name, 
                u.member_id, 
                COALESCE(a.status, 'pending') as status
             FROM users u
             JOIN enrollments e ON u.id = e.member_id
             LEFT JOIN attendance a ON u.id = a.member_id AND a.batch_id = $2 AND a.date = $3
             WHERE u.branch_id = $1 AND e.batch_id = $2 AND u.role = 'member'`,
            [req.branchId, batchId, date]
        );
        res.json(result.rows);
    } catch (error) {
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

