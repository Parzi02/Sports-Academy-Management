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

    membership_type: Joi.string().required(),
    profile_photo_base64: Joi.string().allow('', null),
  }),
};

const markAttendance = {
  body: Joi.object().keys({
    batchId: Joi.number().integer().required(),
    date: Joi.string().required(),
    attendanceList: Joi.array().items(
      Joi.object().keys({
        memberId: Joi.number().integer().required(),
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

module.exports = {
  addMember,
  markAttendance,
  createEvent,
};
