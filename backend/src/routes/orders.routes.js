const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/orders.controller');
const auth = require('../middleware/auth');

router.post('/', auth, ordersController.createOrder);
router.get('/coach', auth, ordersController.getCoachOrders);
router.patch('/:id/status', auth, ordersController.updateOrderStatus);

module.exports = router;
