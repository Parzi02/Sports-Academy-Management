const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const validate = require('../middleware/validator');
const authValidation = require('../validations/auth.validation');

router.post('/send-otp', validate(authValidation.sendOtp), authController.sendOtp);
router.post('/verify-otp', validate(authValidation.verifyOtp), authController.verifyOtp);

module.exports = router;

