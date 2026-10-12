const { Router } = require('express');

/**
 * Mounts health-check routes.
 * @param {import('../controllers/health.controller')} healthController
 */
function healthRoutes(healthController) {
  const router = Router();

  router.get('/health', (req, res, next) =>
    healthController.getHealth(req, res, next)
  );

  return router;
}

module.exports = healthRoutes;

