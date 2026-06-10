const Joi = require('joi');

const addMember = {
  body: Joi.object().keys({
    name: Joi.string().required(),
    phone: Joi.string().required(),
    email: Joi.string().email().allow('', null),
    dob: Joi.date().allow(null),
    gender: Joi.string().valid('male', 'female', 'other').allow('', null),
    address: Joi.string().allow('', null),
    batch_id: Joi.string().required(),
    coach_id: Joi.string().required(),

    membership_type: Joi.string().required(),
    profile_photo_base64: Joi.string().allow('', null),
  }),
};

const markAttendance = {
  body: Joi.object().keys({
    batchId: Joi.string().required(),
    date: Joi.string().required(),
    attendanceList: Joi.array().items(
      Joi.object().keys({
        memberId: Joi.string().required(),
        status: Joi.string().valid('present', 'absent', 'late').required(),
      })
    ).required(),
  }),
};

const createEvent = {
  body: Joi.object().keys({
    title: Joi.string().required(),
    description: Joi.string().allow('', null),
    sport_category: Joi.string().required(),
    event_category: Joi.string().required(),
    date: Joi.string().required(),
    start_time: Joi.string().required(),
    end_time: Joi.string().required(),
    venue: Joi.string().required(),
    image_base64: Joi.string().allow('', null),
  }),
};

const updateProfile = {
  body: Joi.object().keys({
    name: Joi.string().required(),
    email: Joi.string().email().allow('', null),
    phone: Joi.string().required(),
    address: Joi.string().allow('', null),
    profile_photo_base64: Joi.string().allow('', null),
  }),
};

const recordCashPayment = {
  params: Joi.object().keys({
    id: Joi.string().uuid().required()
  }),
  body: Joi.object().keys({
    amount: Joi.number().required(),
    planType: Joi.string().required()
  })
};

const updateMemberEnrollment = {
  params: Joi.object().keys({
    id: Joi.string().uuid().required()
  }),
  body: Joi.object().keys({
    batch_id: Joi.string().uuid().allow('', null),
    membership_type: Joi.string().allow('', null)
  }).min(1)
};

const updatePaymentStatus = {
  params: Joi.object().keys({
    id: Joi.string().uuid().required()
  }),
  body: Joi.object().keys({
    status: Joi.string().valid('success', 'failed').required()
  })
};

module.exports = {
  addMember,
  markAttendance,
  createEvent,
  updateProfile,
  recordCashPayment,
  updateMemberEnrollment,
  updatePaymentStatus
};
