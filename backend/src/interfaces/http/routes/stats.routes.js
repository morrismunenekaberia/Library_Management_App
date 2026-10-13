const { Router } = require('express');
const {
  authenticate,
  requireRole,
} = require('../middleware/auth.middleware');

/**
 * Mounts stats routes.
 * @param {import('../controllers/stats.controller')} statsController
 */
function statsRoutes(statsController) {
  const router = Router();

  // GET /api/stats (librarian only)
  router.get(
    '/',
    authenticate,
    requireRole('librarian'),
    (req, res, next) => statsController.getStats(req, res, next)
  );

  return router;
}

module.exports = statsRoutes;

