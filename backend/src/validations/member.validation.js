const Joi = require('joi');

const markSelfAttendance = {
  body: Joi.object().keys({
    imageBase64: Joi.string().required(),
  }),
};

const recordPayment = {
  body: Joi.object().keys({
    amount: Joi.number().required(),
    paymentMethod: Joi.string().required(),
    upiTransactionId: Joi.string().required(),
  }),
};

const updateProfile = {
  body: Joi.object().keys({
    name: Joi.string().required(),
    phone: Joi.string().required(),
    address: Joi.string().allow('', null),
    profilePhotoBase64: Joi.string().allow('', null),
  }),
};

module.exports = {
  markSelfAttendance,
  recordPayment,
  updateProfile,
};
