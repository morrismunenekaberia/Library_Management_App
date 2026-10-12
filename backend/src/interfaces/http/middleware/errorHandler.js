const { AppError } = require('../../../domain/errors');

/**
 * Centralized error-handling middleware.
 * - AppError subclasses carry their own statusCode (400, 401, 403, 404, 409).
 * - Anything else is treated as an unexpected 500 error.
 */
// eslint-disable-next-line no-unused-vars -- Express requires the 4-param signature
function errorHandler(err, req, res, next) {
  // Handle express JSON body-parser syntax errors (malformed JSON payloads)
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ error: 'Invalid JSON payload' });
  }

  // Handle CORS policy rejection
  if (err.message && err.message.includes('CORS')) {
    return res.status(403).json({ error: 'Request origin not allowed by CORS policy' });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // Unexpected errors: logged on the server, return a clean generic 500 without stack trace
  console.error('Unexpected server error:', err);
  return res.status(500).json({ error: 'Internal server error' });
}

module.exports = errorHandler;

