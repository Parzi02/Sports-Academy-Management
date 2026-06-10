const express = require('express');
const router = express.Router();
const memberController = require('../controllers/member.controller');
const paymentController = require('../controllers/payment.controller');
const auth = require('../middleware/auth');
const validate = require('../middleware/validator');
const memberValidation = require('../validations/member.validation');

router.use(auth); // Protect all member routes

router.get('/dashboard', memberController.getDashboard);
router.get('/attendance', memberController.getAttendanceLogs);
router.post('/attendance/mark', validate(memberValidation.markSelfAttendance), memberController.markSelfAttendance);
router.get('/events', memberController.getEvents);
router.post('/events/:eventId/favourite', validate(memberValidation.toggleFavourite), memberController.toggleFavourite);
router.post('/payments/submit', validate(memberValidation.submitPayment), paymentController.submitPayment);
router.get('/payments/history', paymentController.getPaymentHistory);
router.post('/payments', validate(memberValidation.recordPayment), memberController.recordPayment);
router.get('/profile', memberController.getProfile);
router.put('/profile', validate(memberValidation.updateProfile), memberController.updateProfile);

module.exports = router;

