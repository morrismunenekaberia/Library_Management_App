const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');

/**
 * Mounts authentication routes.
 * @param {import('../controllers/auth.controller')} authController
 */
function authRoutes(authController) {
  const router = Router();

  router.post('/login', (req, res, next) =>
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

