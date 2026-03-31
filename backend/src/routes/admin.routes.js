const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const auth = require('../middleware/auth');

router.use(auth); // Protect all admin routes

router.get('/profile', adminController.getProfile);
router.put('/profile', adminController.updateProfile);

router.get('/dashboard', adminController.getDashboardStats);
router.get('/members', adminController.getMembers);
router.get('/members/:id', adminController.getMemberById);
router.get('/batches', adminController.getBatches);
router.get('/events', adminController.getEvents);
router.get('/attendance', adminController.getAttendance);
router.get('/attendance/marked-days', adminController.getMarkedDays);
router.post('/members', adminController.addMember);
router.post('/attendance', adminController.markAttendance);
router.post('/events', adminController.createEvent);

module.exports = router;
