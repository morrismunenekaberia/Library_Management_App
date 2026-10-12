const { ValidationError } = require('../../../domain/errors');

/**
 * Validation middleware for creating a member.
 */
function validateCreateMember(req, res, next) {
  const body = req.body || {};
  const fullName =
    typeof (body.full_name || body.fullName) === 'string'
      ? (body.full_name || body.fullName).trim()
      : '';

  const admissionNumber =
    typeof (body.admission_number || body.admissionNumber) === 'string'
      ? (body.admission_number || body.admissionNumber).trim()
      : '';

  if (!fullName) {
    return next(new ValidationError('full_name is required and must be a non-empty string'));
  }

  if (!admissionNumber) {
    return next(
      new ValidationError(
        'admission_number is required and must be a non-empty string'
      )
    );
  }

  const phone =
    typeof body.phone === 'string' ? body.phone.trim() : null;
  const email =
    typeof body.email === 'string' ? body.email.trim() : null;

  const status =
    typeof body.status === 'string' ? body.status.trim() : 'active';
  if (status && !['active', 'suspended'].includes(status)) {
    return next(
      new ValidationError('status must be either "active" or "suspended"')
    );
  }

  const createUser = Boolean(
    body.create_user !== undefined ? body.create_user : body.createUser
  );

  req.body = {
    fullName,
    admissionNumber,
    phone,
    email,
    status,
    createUser,
  };

  next();
}

/**
 * Validation middleware for updating a member.
 */
function validateUpdateMember(req, res, next) {
  const body = req.body || {};
  const updates = {};

  const fullNameRaw = body.full_name !== undefined ? body.full_name : body.fullName;
  if (fullNameRaw !== undefined) {
    if (typeof fullNameRaw !== 'string' || !fullNameRaw.trim()) {
      return next(new ValidationError('full_name must be a non-empty string'));
    }
    updates.fullName = fullNameRaw.trim();
  }

  const admRaw =
    body.admission_number !== undefined
      ? body.admission_number
      : body.admissionNumber;
  if (admRaw !== undefined) {
    if (typeof admRaw !== 'string' || !admRaw.trim()) {
      return next(
        new ValidationError('admission_number must be a non-empty string')
      );
    }
    updates.admissionNumber = admRaw.trim();
  }

  if (body.phone !== undefined) {
    updates.phone =
      typeof body.phone === 'string' ? body.phone.trim() : null;
  }

  if (body.email !== undefined) {
    updates.email =
      typeof body.email === 'string' ? body.email.trim() : null;
  }

  if (body.status !== undefined) {
    if (!['active', 'suspended'].includes(body.status)) {
      return next(
        new ValidationError('status must be either "active" or "suspended"')
      );
    }
    updates.status = body.status;
  }

  if (Object.keys(updates).length === 0) {
    return next(
      new ValidationError('At least one field must be provided for update')
    );
  }

  req.body = updates;
  next();
}

module.exports = {
  validateCreateMember,
  validateUpdateMember,
};

