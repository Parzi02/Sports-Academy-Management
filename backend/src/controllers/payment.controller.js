const prisma = require('../config/prisma');
const logger = require('../config/logger');
const ocrService = require('../services/ocr.service');

// Member: Submit Payment Proof
exports.submitPayment = async (req, res, next) => {
    const { amount, planType, utrNumber, screenshotBase64 } = req.body;
    
    try {
        // Check for duplicate UTR
        const checkUtr = await prisma.payments.findUnique({
            where: { utr_number: utrNumber }
        });
        if (checkUtr) {
            const error = new Error('Duplicate Submission: This UTR is already recorded.');
            error.statusCode = 400;
            throw error;
        }

        // Detect payment app from screenshot
        const paymentMethod = await ocrService.detectPaymentApp(screenshotBase64);
        logger.info(`Detected payment method: ${paymentMethod}`);

        // Insert new payment with pending status
        const newPayment = await prisma.payments.create({
            data: {
                member_id: req.user.id,
                amount: amount,
                plan_type: planType,
                utr_number: utrNumber,
                screenshot_base64: screenshotBase64,
                status: 'pending',
                payment_method: paymentMethod
            },
            select: { id: true, amount: true, plan_type: true, status: true, payment_method: true }
        });

        res.status(201).json({ 
            message: 'Payment proof submitted for verification',
            payment: newPayment
        });
    } catch (error) {
        next(error);
    }
};

// Member: Get Payment History
exports.getPaymentHistory = async (req, res, next) => {
    try {
        const payments = await prisma.payments.findMany({
            where: { member_id: req.user.id },
            orderBy: { created_at: 'desc' },
            select: { id: true, amount: true, plan_type: true, utr_number: true, status: true, created_at: true }
        });
        res.json(payments);
    } catch (error) {
        next(error);
    }
};

// Admin: Get Pending Payments
exports.getPendingPayments = async (req, res, next) => {
    try {
        const payments = await prisma.payments.findMany({
            where: {
                status: 'pending',
                members: {
                    branch_id: req.branchId,
                    coach_id: req.user.id
                }
            },
            orderBy: { created_at: 'asc' },
            select: {
                id: true,
                amount: true,
                plan_type: true,
                utr_number: true,
                status: true,
                created_at: true,
                screenshot_base64: true,
                members: {
                    select: { name: true, phone: true, member_id: true }
                }
            }
        });

        const formattedPayments = payments.map(p => ({
            ...p,
            member_name: p.members?.name,
            member_phone: p.members?.phone,
            member_sid: p.members?.member_id,
            members: undefined
        }));

        res.json(formattedPayments);
    } catch (error) {
        next(error);
    }
};

// Admin: Approve or Reject a payment
exports.updatePaymentStatus = async (req, res, next) => {
    const { id } = req.params;
    const { status } = req.body;

    if (!['success', 'failed'].includes(status)) {
        const error = new Error('Invalid status. Use success or failed.');
        error.statusCode = 400;
        return next(error);
    }

    try {
        await prisma.$transaction(async (tx) => {
            const payment = await tx.payments.findFirst({
                where: {
                    id: id,
                    members: { branch_id: req.branchId }
                },
                include: { members: true }
            });

            if (!payment) {
                const error = new Error('Payment not found or access denied');
                error.statusCode = 404;
                throw error;
            }

            const { member_id, plan_type } = payment;

            await tx.payments.update({
                where: { id: id },
                data: { status: status }
            });

            if (status === 'success') {
                let daysToAdd = 30;
                const type = (plan_type || '').toLowerCase();
                if (type.includes('quarterly')) daysToAdd = 90;
                else if (type.includes('yearly')) daysToAdd = 365;

                const enrollments = await tx.enrollments.findMany({
                    where: { member_id: member_id }
                });

                for (const enr of enrollments) {
                    let newEndDate = new Date();
                    if (enr.end_date && enr.end_date > newEndDate) {
                        newEndDate = new Date(enr.end_date);
                    }
                    newEndDate.setDate(newEndDate.getDate() + daysToAdd);

                    await tx.enrollments.update({
                        where: { id: enr.id },
                        data: {
                            end_date: newEndDate,
                            payment_status: 'paid'
                        }
                    });
                }
            }
        });

        res.json({ message: `Payment ${status === 'success' ? 'approved' : 'rejected'} successfully` });
    } catch (error) {
        next(error);
    }
};


