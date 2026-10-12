const { Router } = require('express');
const {
  authenticate,
  requireRole,
} = require('../middleware/auth.middleware');
const {
  validateIssueLoan,
} = require('../middleware/loan-validation.middleware');

/**
 * Mounts loan routes.
 * @param {import('../controllers/loan.controller')} loanController
 */
function loanRoutes(loanController) {
  const router = Router();

  // All loan endpoints require authentication
  router.use(authenticate);

  // Read: librarians see all loans (with optional filters); members see only their own
  router.get('/', (req, res, next) =>
    loanController.list(req, res, next)
  );

  // Write: restricted to librarians only
  router.post(
    '/',
    requireRole('librarian'),
    validateIssueLoan,
    (req, res, next) => loanController.issue(req, res, next)
  );

  router.post(
    '/:id/return',
    requireRole('librarian'),
    (req, res, next) => loanController.returnBook(req, res, next)
  );

  return router;
}

module.exports = loanRoutes;

