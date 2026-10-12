const { ValidationError } = require('../../domain/errors');

/**
 * Use case: Retrieves loans filtered by status and/or memberId.
 */
class ListLoans {
  /**
   * @param {import('../../domain/repositories/loan.repository')} loanRepository
   */
  constructor(loanRepository) {
    this.loanRepository = loanRepository;
  }

  /**
   * @param {Object} [filter]
   * @param {'active'|'overdue'|'returned'} [filter.status]
   * @param {number} [filter.memberId]
   * @returns {Promise<import('../../domain/entities/loan.entity')[]>}
   */
  async execute({ status, memberId } = {}) {
    if (status && !['active', 'overdue', 'returned'].includes(status)) {
      throw new ValidationError(
        'status filter must be one of: "active", "overdue", "returned"'
      );
    }

    return this.loanRepository.findAll({ status, memberId });
  }
}

module.exports = ListLoans;

