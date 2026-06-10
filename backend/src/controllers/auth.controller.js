const axios = require('axios');
const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');
const logger = require('../config/logger');

exports.sendOtp = async (req, res, next) => {
  const { phone } = req.body;

  try {
    if (process.env.USE_MOCK_OTP === 'true') {
      logger.info(`[MOCK] OTP for ${phone} is 1234`);
      return res.json({ sessionId: 'mock_session_id' });
    }
    const url = `https://2factor.in/API/V1/${process.env.TWOFACTOR_API_KEY}/SMS/${phone}/AUTOGEN`;
    const response = await axios.get(url);
    res.json({ sessionId: response.data.Details });
  } catch (error) {
    next(error);
  }
};

exports.verifyOtp = async (req, res, next) => {
  const { phone, otp, sessionId } = req.body;

  try {
    if (process.env.USE_MOCK_OTP === 'true') {
      if (otp !== '1234') {
        const error = new Error('Invalid OTP (Mock mode expects 1234).');
        error.statusCode = 401;
        throw error;
      }
    } else {
      // 1. Verify OTP with 2factor.in
      const url = `https://2factor.in/API/V1/${process.env.TWOFACTOR_API_KEY}/SMS/VERIFY/${sessionId}/${otp}`;
      const result = await axios.get(url);
      
      if (result.data.Status !== 'Success') {
        const error = new Error('Invalid OTP.');
        error.statusCode = 401;
        throw error;
      }
    }

    // 2. Fetch User from DB (Check coaches first, then members)
    const phoneSuffix = phone.slice(-10);

    let user = await prisma.coaches.findFirst({
      where: { phone: { endsWith: phoneSuffix } }
    });

    if (user) {
      user.role = 'admin';
    } else {
      user = await prisma.members.findFirst({
        where: { phone: { endsWith: phoneSuffix } }
      });
      if (user) user.role = 'member';
    }

    if (!user) {
      const error = new Error('User not registered.');
      error.statusCode = 404;
      throw error;
    }

    // 3. Generate JWT
    const token = jwt.sign(
      { id: user.id, role: user.role, branch_id: user.branch_id, phone: user.phone, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({ token, user });
  } catch (error) {
    next(error);
  }
};

