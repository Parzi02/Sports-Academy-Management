const axios = require('axios');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

exports.sendOtp = async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone number is required.' });

  try {
    if (process.env.USE_MOCK_OTP === 'true') {
      console.log(`[MOCK] OTP for ${phone} is 1234`);
      return res.json({ sessionId: 'mock_session_id' });
    }
    const url = `https://2factor.in/API/V1/${process.env.TWOFACTOR_API_KEY}/SMS/${phone}/AUTOGEN`;
    const response = await axios.get(url);
    res.json({ sessionId: response.data.Details });
  } catch (error) {
    console.error('2factor error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to send OTP.' });
  }
};

exports.verifyOtp = async (req, res) => {
  const { phone, otp, sessionId } = req.body;
  
  if (!phone || !otp || !sessionId) {
    return res.status(400).json({ error: 'Phone, OTP, and SessionId are required.' });
  }

  try {
    if (process.env.USE_MOCK_OTP === 'true') {
      if (otp !== '1234') {
        return res.status(401).json({ error: 'Invalid OTP (Mock mode expects 1234).' });
      }
    } else {
      // 1. Verify OTP with 2factor.in
      const url = `https://2factor.in/API/V1/${process.env.TWOFACTOR_API_KEY}/SMS/VERIFY/${sessionId}/${otp}`;
      const result = await axios.get(url);
      
      if (result.data.Status !== 'Success') {
        return res.status(401).json({ error: 'Invalid OTP.' });
      }
    }

    // 2. Fetch User from DB (Match last 10 digits to handle optional 91 prefix)
    const userRes = await db.query('SELECT * FROM users WHERE RIGHT(phone, 10) = RIGHT($1, 10)', [phone]);
    const user = userRes.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'User not registered.' });
    }

    // 3. Generate JWT
    const token = jwt.sign(
      { id: user.id, role: user.role, branch_id: user.branch_id, phone: user.phone, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({ token, user });
  } catch (error) {
    console.error('OTP verification error:', error.message);
    res.status(500).json({ error: error.message || 'Authentication failed.' });
  }
};
