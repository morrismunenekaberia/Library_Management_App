const { Router } = require('express');
const {
  authenticate,
  requireRole,
} = require('../middleware/auth.middleware');
const {
  validateCreateMember,
  validateUpdateMember,
} = require('../middleware/member-validation.middleware');

/**
 * Mounts member routes (restricted to librarians only).
 * @param {import('../controllers/member.controller')} memberController
 */
function memberRoutes(memberController) {
  const router = Router();

  // All member management endpoints are restricted to librarians
  router.use(authenticate, requireRole('librarian'));

  router.get('/', (req, res, next) =>
    memberController.list(req, res, next)
  );

  router.get('/:id', (req, res, next) =>
    memberController.getById(req, res, next)
  );

  router.post('/', validateCreateMember, (req, res, next) =>
    memberController.create(req, res, next)
  );

  router.put('/:id', validateUpdateMember, (req, res, next) =>
    memberController.update(req, res, next)
  );

  router.delete('/:id', (req, res, next) =>
    memberController.delete(req, res, next)
  );

  return router;
}

module.exports = memberRoutes;

