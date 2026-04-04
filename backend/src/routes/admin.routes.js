const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const paymentController = require('../controllers/payment.controller');
const auth = require('../middleware/auth');
const validate = require('../middleware/validator');
const adminValidation = require('../validations/admin.validation');

router.use(auth); // Protect all admin routes

router.get('/profile', adminController.getProfile);
router.put('/profile', adminController.updateProfile);

router.get('/dashboard', adminController.getDashboardStats);
router.get('/members', adminController.getMembers);
router.get('/members/:id', adminController.getMemberById);
router.get('/payments/pending', paymentController.getPendingPayments);
router.put('/payments/approve/:id', paymentController.updatePaymentStatus);
router.get('/batches', adminController.getBatches);
router.get('/events', adminController.getEvents);
router.get('/attendance', adminController.getAttendance);
router.get('/attendance/marked-days', adminController.getMarkedDays);

router.post('/members', validate(adminValidation.addMember), adminController.addMember);
router.post('/attendance', validate(adminValidation.markAttendance), adminController.markAttendance);
router.post('/events', validate(adminValidation.createEvent), adminController.createEvent);

module.exports = router;

