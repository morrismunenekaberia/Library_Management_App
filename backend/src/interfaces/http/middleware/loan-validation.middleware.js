const { ValidationError } = require('../../../domain/errors');

/**
 * Validation middleware for issuing a loan.
 */
function validateIssueLoan(req, res, next) {
  const body = req.body || {};

  const bookIdRaw = body.book_id !== undefined ? body.book_id : body.bookId;
  const memberIdRaw =
    body.member_id !== undefined ? body.member_id : body.memberId;
  const dueDateRaw =
    body.due_date !== undefined ? body.due_date : body.dueDate;

  const bookId = parseInt(bookIdRaw, 10);
  if (isNaN(bookId) || bookId <= 0) {
    return next(new ValidationError('book_id is required and must be a positive integer'));
  }

  const memberId = parseInt(memberIdRaw, 10);
  if (isNaN(memberId) || memberId <= 0) {
    return next(
      new ValidationError('member_id is required and must be a positive integer')
    );
  }

  req.body = {
    bookId,
    memberId,
    dueDate: dueDateRaw || undefined,
  };

  next();
}

module.exports = {
  validateIssueLoan,
};

