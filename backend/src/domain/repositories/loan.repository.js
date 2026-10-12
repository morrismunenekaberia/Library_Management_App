/**
 * LoanRepository interface.
 * Defines persistence contract for library loans.
 */
class LoanRepository {
  /**
   * Issues a loan atomically decrementing available_copies using SELECT ... FOR UPDATE.
   * @param {Object} params
   * @param {number} params.bookId
   * @param {number} params.memberId
   * @param {Date|string} params.dueDate
   * @returns {Promise<import('../entities/loan.entity')>}
   */
  async issueLoan(params) {
    throw new Error('LoanRepository.issueLoan() not implemented');
  }

  /**
   * Marks a loan as returned and increments available_copies atomically.
   * @param {number} loanId
   * @returns {Promise<import('../entities/loan.entity')>}
   */
  async returnLoan(loanId) {
    throw new Error('LoanRepository.returnLoan() not implemented');
  }

  /**
   * Finds a loan by ID.
   * @param {number} id
   * @returns {Promise<import('../entities/loan.entity')|null>}
   */
  async findById(id) {
    throw new Error('LoanRepository.findById() not implemented');
  }

  /**
   * Counts currently active (unreturned) loans for a given member.
   * @param {number} memberId
   * @returns {Promise<number>}
   */
  async countActiveByMember(memberId) {
    throw new Error('LoanRepository.countActiveByMember() not implemented');
  }

  /**
   * Finds loans matching status and optional memberId.
   * @param {Object} [filter]
   * @param {'active'|'overdue'|'returned'} [filter.status]
   * @param {number} [filter.memberId]
   * @returns {Promise<import('../entities/loan.entity')[]>}
   */
  async findAll(filter) {
    throw new Error('LoanRepository.findAll() not implemented');
  }
}

module.exports = LoanRepository;

