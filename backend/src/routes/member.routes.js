const express = require('express');
const router = express.Router();
const memberController = require('../controllers/member.controller');
const auth = require('../middleware/auth');

router.use(auth); // Protect all member routes

router.get('/dashboard', memberController.getDashboard);
router.get('/attendance', memberController.getAttendanceLogs);
router.post('/attendance/mark', memberController.markSelfAttendance);
router.get('/events', memberController.getEvents);
router.post('/events/:eventId/favourite', memberController.toggleFavourite);
router.post('/payments', memberController.recordPayment);
router.get('/profile', memberController.getProfile);
router.put('/profile', memberController.updateProfile);

module.exports = router;
