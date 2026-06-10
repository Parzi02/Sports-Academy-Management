const prisma = require('../config/prisma');
const logger = require('../config/logger');

// Member Dashboard
exports.getDashboard = async (req, res, next) => {
    try {
        const totalSessions = await prisma.attendance.count({
            where: { member_id: req.user.id }
        });
        
        const attendedSessions = await prisma.attendance.count({
            where: { member_id: req.user.id, status: 'present' }
        });
        
        const attendancePercentage = totalSessions > 0 ? (attendedSessions / totalSessions) * 100 : 0;

        const enrollment = await prisma.enrollments.findFirst({
            where: { member_id: req.user.id },
            include: {
                batches: {
                    include: {
                        coaches: true
                    }
                }
            }
        });
        
        const batchName = enrollment?.batches?.name;
        const sport = enrollment?.batches?.sport;
        const startTime = enrollment?.batches?.start_time;
        const endTime = enrollment?.batches?.end_time;
        const coachName = enrollment?.batches?.coaches?.name;
        const coachUpiId = enrollment?.batches?.coaches?.upi_id;

        const formatTime = (dateObj) => {
            if (!dateObj) return '';
            return dateObj.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'UTC' });
        };

        const todaySchedule = batchName ? [{
            title: batchName,
            start_time: formatTime(startTime),
            end_time: formatTime(endTime),
            coach: coachName || 'Assigned',
            venue: 'Academy Training Ground'
        }] : [];

        const now = new Date();
        const todayUtc = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));

        const todayAttendance = await prisma.attendance.count({
            where: {
                member_id: req.user.id,
                date: todayUtc
            }
        });
        const isAttendanceMarkedToday = todayAttendance > 0;

        const pendingPayment = await prisma.payments.count({
            where: { member_id: req.user.id, status: 'pending' }
        });
        const isPaymentPending = pendingPayment > 0;

        res.json({
            isAttendanceMarkedToday: isAttendanceMarkedToday,
            isPaymentPending: isPaymentPending,
            attendancePercentage: attendancePercentage.toFixed(2),
            attendedSessions: attendedSessions,
            totalSessions: totalSessions,
            feeStatus: enrollment?.payment_status || 'due',
            membershipType: enrollment?.membership_type || 'standard',
            dueDate: enrollment?.end_date,
            batchName: batchName || 'No Batch',
            sport: sport || 'Academy Training',
            coachName: coachName || 'Assigned',
            coachUpiId: coachUpiId || null,
            batchTime: startTime ? `${formatTime(startTime)} - ${formatTime(endTime)}` : 'TBD',
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
        const enrollment = await prisma.enrollments.findFirst({
            where: { member_id: req.user.id },
            select: { batch_id: true }
        });

        if (!enrollment) {
            const error = new Error('No active enrollment found to mark attendance');
            error.statusCode = 404;
            return next(error);
        }

        const now = new Date();
        const todayUtc = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));

        await prisma.attendance.upsert({
            where: {
                member_id_batch_id_date: {
                    member_id: req.user.id,
                    batch_id: enrollment.batch_id,
                    date: todayUtc
                }
            },
            update: {
                status: 'present',
                marked_at: new Date(),
                selfie_base64: imageBase64
            },
            create: {
                member_id: req.user.id,
                batch_id: enrollment.batch_id,
                date: todayUtc,
                status: 'present',
                selfie_base64: imageBase64
            }
        });

        res.json({ message: 'Attendance marked successfully' });
    } catch (error) {
        next(error);
    }
};

// Attendance Logs
exports.getAttendanceLogs = async (req, res, next) => {
    try {
        const logs = await prisma.attendance.findMany({
            where: { member_id: req.user.id },
            orderBy: { date: 'desc' },
            select: { date: true, status: true }
        });
        res.json(logs.map(l => ({
            date: l.date.toISOString().split('T')[0],
            status: l.status
        })));
    } catch (error) {
        next(error);
    }
};

// Events
exports.getEvents = async (req, res, next) => {
    try {
        const events = await prisma.events.findMany({
            where: { branch_id: req.branchId },
            orderBy: { date: 'desc' },
            select: { id: true, title: true, sport_category: true, event_category: true, date: true, venue: true, status: true }
        });
        res.json(events.map(e => ({
            ...e,
            date: e.date.toISOString().split('T')[0]
        })));
    } catch (error) {
        next(error);
    }
};

exports.toggleFavourite = async (req, res, next) => {
    const { eventId } = req.params;
    try {
        const check = await prisma.event_favourites.findFirst({
            where: { member_id: req.user.id, event_id: eventId }
        });

        if (check) {
            await prisma.event_favourites.delete({ where: { id: check.id } });
            res.json({ isFavourite: false });
        } else {
            await prisma.event_favourites.create({
                data: { member_id: req.user.id, event_id: eventId }
            });
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
        await prisma.$transaction(async (tx) => {
            await tx.payments.create({
                data: {
                    member_id: req.user.id,
                    amount: amount,
                    payment_method: paymentMethod,
                    utr_number: upiTransactionId,
                    status: 'success'
                }
            });

            await tx.enrollments.updateMany({
                where: { member_id: req.user.id },
                data: { payment_status: 'paid' }
            });
        });
        res.json({ message: 'Payment recorded successfully' });
    } catch (error) {
        next(error);
    }
};

// Profile
exports.getProfile = async (req, res, next) => {
    try {
        const member = await prisma.members.findUnique({
            where: { id: req.user.id },
            include: {
                enrollments: {
                    include: {
                        batches: {
                            include: { coaches: true }
                        }
                    }
                }
            }
        });

        if (!member) {
            const error = new Error('Profile not found');
            error.statusCode = 404;
            throw error;
        }

        const enrollment = member.enrollments[0];
        
        res.json({
            name: member.name,
            phone: member.phone,
            email: member.email,
            dob: member.dob,
            gender: member.gender,
            address: member.address,
            member_id: member.member_id,
            profile_photo_base64: member.profile_photo_base64,
            date_of_joining: enrollment?.start_date,
            sport: enrollment?.batches?.sport,
            coach_name: enrollment?.batches?.coaches?.name
        });
    } catch (error) {
        next(error);
    }
};

// Update Profile
exports.updateProfile = async (req, res, next) => {
    const { name, phone, address, profilePhotoBase64 } = req.body;
    try {
        const member = await prisma.members.update({
            where: { id: req.user.id },
            data: {
                name,
                phone,
                address,
                profile_photo_base64: profilePhotoBase64
            },
            include: {
                enrollments: {
                    include: {
                        batches: { include: { coaches: true } }
                    }
                }
            }
        });

        const enrollment = member.enrollments[0];

        res.json({
            name: member.name,
            phone: member.phone,
            email: member.email,
            dob: member.dob,
            gender: member.gender,
            address: member.address,
            member_id: member.member_id,
            profile_photo_base64: member.profile_photo_base64,
            date_of_joining: enrollment?.start_date,
            sport: enrollment?.batches?.sport,
            coach_name: enrollment?.batches?.coaches?.name
        });
    } catch (error) {
        next(error);
    }
};

