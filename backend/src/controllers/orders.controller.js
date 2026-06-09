const db = require('../config/db');

exports.createOrder = async (req, res, next) => {
  const client = await db.pool.connect();
  try {
    const memberId = req.user.id;
    const { items, totalAmount, utrNumber, paymentProof } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Order must contain at least one item' });
    }

    await client.query('BEGIN');

    // Retrieve coach_id for the member
    const memberResult = await client.query('SELECT coach_id FROM members WHERE id = $1', [memberId]);
    const coachId = memberResult.rows[0]?.coach_id || null;

    // Insert order with JSON items, UTR, and payment proof
    const orderResult = await client.query(
      `INSERT INTO orders (member_id, coach_id, total_amount, status, delivery_status, items, utr_number, payment_proof) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
      [memberId, coachId, totalAmount, 'pending', 'pending', JSON.stringify(items), utrNumber, paymentProof]
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
      SELECT o.id, o.total_amount, o.status, o.delivery_status, o.items, o.created_at, o.utr_number, o.payment_proof,
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
    const { status, delivery_status } = req.body;
    const coachId = req.user.id;

    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (status) {
      updates.push(`status = $${paramIndex++}`);
      values.push(status);
    }
    if (delivery_status) {
      updates.push(`delivery_status = $${paramIndex++}`);
      values.push(delivery_status);
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: 'No fields to update' });
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    
    const query = `
      UPDATE orders 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex++} AND coach_id = $${paramIndex}
      RETURNING id, status, delivery_status
    `;
    
    values.push(id, coachId);
    
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Order not found or unauthorized' });
    }

    res.json({ message: 'Order updated', order: result.rows[0] });
  } catch (error) {
    next(error);
  }
};
