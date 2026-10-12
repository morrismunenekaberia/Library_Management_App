const jwt = require('jsonwebtoken');
const env = require('../../../config/env');
const { UnauthorizedError, ForbiddenError } = require('../../../domain/errors');

/**
 * Middleware: Verifies the JWT Bearer token and attaches decoded user to req.user.
 */
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new UnauthorizedError('Authentication token missing or invalid'));
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return next(new UnauthorizedError('Authentication token missing'));
  }

  try {
    const decoded = jwt.verify(token, env.jwtSecret);
    req.user = {
      id: decoded.id,
      username: decoded.username || null,
      role: decoded.role,
      memberId: decoded.memberId !== undefined ? decoded.memberId : null,
    };
    next();
  } catch (err) {
    return next(new UnauthorizedError('Invalid or expired token'));
  }
}

/**
 * Middleware factory: Ensures the authenticated user has one of the required roles.
 * @param  {...string} roles
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError('Authentication required'));
    }

    if (!roles.includes(req.user.role)) {
      return next(new ForbiddenError('Forbidden: insufficient permissions'));
    }

    next();
  };
}

module.exports = {
  authenticate,
  requireRole,
};

