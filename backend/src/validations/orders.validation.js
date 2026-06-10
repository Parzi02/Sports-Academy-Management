const Joi = require('joi');

const createOrder = {
  body: Joi.object().keys({
    items: Joi.array().items(Joi.object()).min(1).required(),
    totalAmount: Joi.number().required(),
    utrNumber: Joi.string().allow('', null),
    paymentProof: Joi.string().allow('', null)
  })
};

const updateOrderStatus = {
  params: Joi.object().keys({
    id: Joi.number().required()
  }),
  body: Joi.object().keys({
    status: Joi.string().allow('', null),
    delivery_status: Joi.string().allow('', null)
  }).min(1) // require at least one field to be updated
};

module.exports = {
  createOrder,
  updateOrderStatus
};
