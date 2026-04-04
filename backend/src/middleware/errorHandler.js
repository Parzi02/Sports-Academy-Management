const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
  logger.error(`${err.message} - ${req.method} ${req.url} - ${req.ip}`);
  logger.debug(err.stack);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    success: false,
    message: message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
};

module.exports = errorHandler;
