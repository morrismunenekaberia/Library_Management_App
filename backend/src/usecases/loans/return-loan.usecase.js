const { NotFoundError, ConflictError } = require('../../domain/errors');

/**
 * Use case: Marks a borrowed book as returned.
 * Increments available copies of the book in an atomic transaction.
 */
class ReturnLoan {
  /**
   * @param {import('../../domain/repositories/loan.repository')} loanRepository
   */
  constructor(loanRepository) {
    this.loanRepository = loanRepository;
  }

  /**
   * @param {number} loanId
   * @returns {Promise<import('../../domain/entities/loan.entity')>}
   */
  async execute(loanId) {
    const existingLoan = await this.loanRepository.findById(loanId);
    if (!existingLoan) {
      throw new NotFoundError('Loan not found');
    }

    if (existingLoan.returnedAt !== null) {
      throw new ConflictError('Loan has already been returned');
    }

    return this.loanRepository.returnLoan(loanId);
  }
}

module.exports = ReturnLoan;

