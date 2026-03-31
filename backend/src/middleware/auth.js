const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;           // { id, role, branch_id, phone }
    req.branchId = decoded.branch_id; // Inject branch isolation
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
};
