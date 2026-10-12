const { Router } = require('express');
const {
  authenticate,
  requireRole,
} = require('../middleware/auth.middleware');
const {
  validateCreateBook,
  validateUpdateBook,
} = require('../middleware/book-validation.middleware');

/**
 * Mounts books routes.
 * @param {import('../controllers/book.controller')} bookController
 */
function bookRoutes(bookController) {
  const router = Router();

  // Read: accessible to all authenticated users (librarian and member)
  router.get('/', authenticate, (req, res, next) =>
    bookController.list(req, res, next)
  );

  router.get('/:id', authenticate, (req, res, next) =>
    bookController.getById(req, res, next)
  );

  // Write: restricted to librarians only
  router.post(
    '/',
    authenticate,
    requireRole('librarian'),
    validateCreateBook,
    (req, res, next) => bookController.create(req, res, next)
  );

  router.put(
    '/:id',
    authenticate,
    requireRole('librarian'),
    validateUpdateBook,
    (req, res, next) => bookController.update(req, res, next)
  );

  router.delete(
    '/:id',
    authenticate,
    requireRole('librarian'),
    (req, res, next) => bookController.delete(req, res, next)
  );

  return router;
}

module.exports = bookRoutes;

