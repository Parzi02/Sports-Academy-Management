const prisma = require('../config/prisma');

exports.createOrder = async (req, res, next) => {
  try {
    const memberId = req.user.id;
    const { items, totalAmount, utrNumber, paymentProof } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Order must contain at least one item' });
    }

    const orderId = await prisma.$transaction(async (tx) => {
      // Retrieve coach_id for the member
      const member = await tx.members.findUnique({
        where: { id: memberId },
        select: { coach_id: true }
      });
      const coachId = member?.coach_id || null;

      // Insert order
      const newOrder = await tx.orders.create({
        data: {
          member_id: memberId,
          coach_id: coachId,
          total_amount: totalAmount,
          status: 'pending',
          delivery_status: 'pending',
          items: items,
          utr_number: utrNumber,
          payment_proof: paymentProof
        }
      });
      return newOrder.id;
    });

    res.status(201).json({ message: 'Order created successfully', orderId });
  } catch (error) {
    next(error);
  }
};

exports.getCoachOrders = async (req, res, next) => {
  try {
    const coachId = req.user.id;
    
    const orders = await prisma.orders.findMany({
      where: { coach_id: coachId },
      orderBy: { created_at: 'desc' },
      select: {
        id: true,
        total_amount: true,
        status: true,
        delivery_status: true,
        items: true,
        created_at: true,
        utr_number: true,
        payment_proof: true,
        members: {
          select: {
            name: true,
            member_id: true
          }
        }
      }
    });

    const formattedOrders = orders.map(o => ({
      ...o,
      member_name: o.members?.name,
      member_roll: o.members?.member_id,
      members: undefined
    }));

    res.json(formattedOrders);
  } catch (error) {
    next(error);
  }
};

exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, delivery_status } = req.body;
    const coachId = req.user.id;

    if (!status && !delivery_status) {
      return res.status(400).json({ message: 'No fields to update' });
    }

    const dataToUpdate = { updated_at: new Date() };
    if (status) dataToUpdate.status = status;
    if (delivery_status) dataToUpdate.delivery_status = delivery_status;

    // First check if the order exists and belongs to the coach
    const order = await prisma.orders.findFirst({
      where: { 
        id: parseInt(id, 10),
        coach_id: coachId
      }
    });

    if (!order) {
      return res.status(404).json({ message: 'Order not found or unauthorized' });
    }

    const updatedOrder = await prisma.orders.update({
      where: { id: parseInt(id, 10) },
      data: dataToUpdate,
      select: { id: true, status: true, delivery_status: true }
    });

    res.json({ message: 'Order updated', order: updatedOrder });
  } catch (error) {
    next(error);
  }
};
