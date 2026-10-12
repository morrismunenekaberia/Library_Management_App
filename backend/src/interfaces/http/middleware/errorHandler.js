const { AppError } = require('../../../domain/errors');

/**
 * Centralized error-handling middleware.
 * - AppError subclasses carry their own statusCode (400, 401, 403, 404, 409).
 * - Anything else is treated as an unexpected 500 error.
 */
// eslint-disable-next-line no-unused-vars -- Express requires the 4-param signature
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  console.error('Unexpected error:', err);
  return res.status(500).json({ error: 'Internal server error' });
}

module.exports = errorHandler;

