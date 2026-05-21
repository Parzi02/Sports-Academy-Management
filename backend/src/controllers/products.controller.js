const db = require('../config/db');

exports.getAllProducts = async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM products ORDER BY id ASC');
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
};
