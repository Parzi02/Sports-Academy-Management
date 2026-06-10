const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/orders.controller');
const auth = require('../middleware/auth');

const ordersValidation = require('../validations/orders.validation');
const validate = require('../middleware/validator');

router.post('/', auth, validate(ordersValidation.createOrder), ordersController.createOrder);
router.get('/coach', auth, ordersController.getCoachOrders);
router.patch('/:id/status', auth, validate(ordersValidation.updateOrderStatus), ordersController.updateOrderStatus);

module.exports = router;
