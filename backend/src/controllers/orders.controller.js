const db = require('../config/db');

exports.createOrder = async (req, res, next) => {
  const client = await db.pool.connect();
  try {
    const memberId = req.user.id;
    const { items, totalAmount } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Order must contain at least one item' });
    }

    await client.query('BEGIN');

    // Retrieve coach_id for the member
    const memberResult = await client.query('SELECT coach_id FROM members WHERE id = $1', [memberId]);
    const coachId = memberResult.rows[0]?.coach_id || null;

    // Insert order with JSON items
    const orderResult = await client.query(
      `INSERT INTO orders (member_id, coach_id, total_amount, status, items) 
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [memberId, coachId, totalAmount, 'pending', JSON.stringify(items)]
    );
    const orderId = orderResult.rows[0].id;

    await client.query('COMMIT');
    res.status(201).json({ message: 'Order created successfully', orderId });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
};

exports.getCoachOrders = async (req, res, next) => {
  try {
    const coachId = req.user.id;
    const query = `
      SELECT o.id, o.total_amount, o.status, o.items, o.created_at, 
             m.name as member_name, m.member_id as member_roll
      FROM orders o
      JOIN members m ON o.member_id = m.id
      WHERE o.coach_id = $1
      ORDER BY o.created_at DESC
    `;
    const result = await db.query(query, [coachId]);
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
};

exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const coachId = req.user.id;

    const query = `
      UPDATE orders 
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2 AND coach_id = $3
      RETURNING id, status
    `;
    const result = await db.query(query, [status, id, coachId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Order not found or unauthorized' });
    }

    res.json({ message: 'Order status updated', order: result.rows[0] });
  } catch (error) {
    next(error);
  }
};
