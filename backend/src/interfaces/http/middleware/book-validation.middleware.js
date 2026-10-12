const { ValidationError } = require('../../../domain/errors');

/**
 * Validation middleware for creating a book.
 */
function validateCreateBook(req, res, next) {
  const body = req.body || {};
  const isbn = typeof body.isbn === 'string' ? body.isbn.trim() : '';
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const author = typeof body.author === 'string' ? body.author.trim() : '';
  const category =
    typeof body.category === 'string' ? body.category.trim() : null;

  const totalCopiesRaw =
    body.total_copies !== undefined ? body.total_copies : body.totalCopies;

  if (!isbn) {
    return next(new ValidationError('ISBN is required and must be a non-empty string'));
  }
  if (!title) {
    return next(new ValidationError('Title is required and must be a non-empty string'));
  }
  if (!author) {
    return next(new ValidationError('Author is required and must be a non-empty string'));
  }
  if (
    totalCopiesRaw === undefined ||
    typeof totalCopiesRaw !== 'number' ||
    !Number.isInteger(totalCopiesRaw) ||
    totalCopiesRaw < 0
  ) {
    return next(
      new ValidationError(
        'total_copies is required and must be a non-negative integer'
      )
    );
  }

  let availableCopies;
  const availableCopiesRaw =
    body.available_copies !== undefined
      ? body.available_copies
      : body.availableCopies;

  if (availableCopiesRaw !== undefined) {
    if (
      typeof availableCopiesRaw !== 'number' ||
      !Number.isInteger(availableCopiesRaw) ||
      availableCopiesRaw < 0 ||
      availableCopiesRaw > totalCopiesRaw
    ) {
      return next(
        new ValidationError(
          'available_copies must be an integer between 0 and total_copies'
        )
      );
    }
    availableCopies = availableCopiesRaw;
  }

  // Attach normalized payload
  req.body = {
    isbn,
    title,
    author,
    category,
    totalCopies: totalCopiesRaw,
    availableCopies,
  };

  next();
}

/**
 * Validation middleware for updating a book.
 */
function validateUpdateBook(req, res, next) {
  const body = req.body || {};
  const updates = {};

  if (body.isbn !== undefined) {
    if (typeof body.isbn !== 'string' || !body.isbn.trim()) {
      return next(new ValidationError('ISBN must be a non-empty string'));
    }
    updates.isbn = body.isbn.trim();
  }

  if (body.title !== undefined) {
    if (typeof body.title !== 'string' || !body.title.trim()) {
      return next(new ValidationError('Title must be a non-empty string'));
    }
    updates.title = body.title.trim();
  }

  if (body.author !== undefined) {
    if (typeof body.author !== 'string' || !body.author.trim()) {
      return next(new ValidationError('Author must be a non-empty string'));
    }
    updates.author = body.author.trim();
  }

  if (body.category !== undefined) {
    updates.category =
      typeof body.category === 'string' ? body.category.trim() : null;
  }

  const totalCopiesRaw =
    body.total_copies !== undefined ? body.total_copies : body.totalCopies;

  if (totalCopiesRaw !== undefined) {
    if (
      typeof totalCopiesRaw !== 'number' ||
      !Number.isInteger(totalCopiesRaw) ||
      totalCopiesRaw < 0
    ) {
      return next(
        new ValidationError('total_copies must be a non-negative integer')
      );
    }
    updates.totalCopies = totalCopiesRaw;
  }

  if (Object.keys(updates).length === 0) {
    return next(new ValidationError('At least one field must be provided for update'));
  }

  req.body = updates;
  next();
}

module.exports = {
  validateCreateBook,
  validateUpdateBook,
};

