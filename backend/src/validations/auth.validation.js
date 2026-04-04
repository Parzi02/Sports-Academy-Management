const Joi = require('joi');

const sendOtp = {
  body: Joi.object().keys({
    phone: Joi.string().required(),
  }),
};

const verifyOtp = {
  body: Joi.object().keys({
    phone: Joi.string().required(),
    otp: Joi.string().required(), // or length(4) or length(6)
    sessionId: Joi.string().required(),
  }),
};

module.exports = {
  sendOtp,
  verifyOtp,
};
