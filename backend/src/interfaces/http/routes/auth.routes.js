const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const { createLoginRateLimiter } = require('../middleware/rate-limiter.middleware');

const loginLimiter = createLoginRateLimiter({
  windowMs: 15 * 60 * 1000,
  maxAttempts: 10,
});

/**
 * Mounts authentication routes.
 * @param {import('../controllers/auth.controller')} authController
 */
function authRoutes(authController) {
  const router = Router();

  router.post('/login', loginLimiter, (req, res, next) =>
    authController.login(req, res, next)
  );

  router.post('/logout', (req, res, next) =>
    authController.logout(req, res, next)
  );

  router.get('/me', authenticate, (req, res, next) =>
    authController.getProfile(req, res, next)
  );

  return router;
}

module.exports = authRoutes;

