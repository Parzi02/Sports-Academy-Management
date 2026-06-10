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

const submitPayment = {
  body: Joi.object().keys({
    amount: Joi.number().required(),
    planType: Joi.string().required(),
    utrNumber: Joi.string().required(),
    screenshotBase64: Joi.string().required(),
  }),
};

const toggleFavourite = {
  params: Joi.object().keys({
    eventId: Joi.string().uuid().required()
  })
};

module.exports = {
  markSelfAttendance,
  recordPayment,
  updateProfile,
  submitPayment,
  toggleFavourite
};
