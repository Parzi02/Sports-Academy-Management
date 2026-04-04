const Joi = require('joi');

/**
 * Validates request data against a Joi schema.
 * @param {Object} schema - Joi schema (may contain body, query, or params).
 */
const validate = (schema) => (req, res, next) => {
  const validations = ['body', 'query', 'params'].map(key => {
    if (schema[key]) {
      const { error, value } = schema[key].validate(req[key], { abortEarly: false, stripUnknown: true });
      if (error) {
        return { key, error };
      }
      req[key] = value; // Update req with sanitized/validated data
    }
    return null;
  });

  const errors = validations.filter(v => v !== null);

  if (errors.length > 0) {
    const formattedErrors = errors.reduce((acc, current) => {
        acc[current.key] = current.error.details.map(detail => detail.message);
        return acc;
    }, {});

    return res.status(400).json({
      error: true,
      message: 'Validation Failed',
      details: formattedErrors
    });
  }

  next();
};

module.exports = validate;
