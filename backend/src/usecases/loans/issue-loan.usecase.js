const {
  NotFoundError,
  ConflictError,
  ValidationError,
} = require('../../domain/errors');

const MAX_ACTIVE_LOANS_PER_MEMBER = 3;
const DEFAULT_LOAN_DURATION_DAYS = 14;

/**
 * Use case: Issues a book loan to a member.
 *
 * Business Rules:
 * 1. Book must have available_copies > 0.
 * 2. Member must be active.
 * 3. Member can hold at most 3 unreturned loans.
 * 4. due_date must be in the future (default 14 days if not provided).
 */
class IssueLoan {
  /**
   * @param {Object} repos
   * @param {import('../../domain/repositories/loan.repository')} repos.loanRepository
   * @param {import('../../domain/repositories/book.repository')} repos.bookRepository
   * @param {import('../../domain/repositories/member.repository')} repos.memberRepository
   */
  constructor({ loanRepository, bookRepository, memberRepository }) {
    this.loanRepository = loanRepository;
    this.bookRepository = bookRepository;
    this.memberRepository = memberRepository;
  }

  /**
   * @param {Object} params
   * @param {number} params.bookId
   * @param {number} params.memberId
   * @param {string|Date} [params.dueDate]
   * @returns {Promise<import('../../domain/entities/loan.entity')>}
   */
  async execute({ bookId, memberId, dueDate }) {
    if (!bookId || typeof bookId !== 'number') {
      throw new ValidationError('book_id is required');
    }
    if (!memberId || typeof memberId !== 'number') {
      throw new ValidationError('member_id is required');
    }

    // 1. Verify member exists and is active
    const member = await this.memberRepository.findById(memberId);
    if (!member) {
      throw new NotFoundError('Member not found');
    }
    if (member.status !== 'active') {
      throw new ConflictError('Member is not active');
    }

    // 2. Verify member does not exceed active loan limit
    const activeLoans = await this.loanRepository.countActiveByMember(memberId);
    if (activeLoans >= MAX_ACTIVE_LOANS_PER_MEMBER) {
      throw new ConflictError(
        `Member cannot hold more than ${MAX_ACTIVE_LOANS_PER_MEMBER} unreturned loans`
      );
    }

    // 3. Verify book exists and has available copies
    const book = await this.bookRepository.findById(bookId);
    if (!book) {
      throw new NotFoundError('Book not found');
    }
    if (book.availableCopies <= 0) {
      throw new ConflictError('No available copies for this book');
    }

    // 4. Validate or calculate due date
    let targetDueDate;
    if (dueDate) {
      const parsed = new Date(dueDate);
      if (isNaN(parsed.getTime())) {
        throw new ValidationError('Invalid due_date format');
      }
      if (parsed <= new Date()) {
        throw new ValidationError('due_date must be in the future');
      }
      targetDueDate = parsed;
    } else {
      targetDueDate = new Date(
        Date.now() + DEFAULT_LOAN_DURATION_DAYS * 24 * 60 * 60 * 1000
      );
    }

    // 5. Persist loan and decrement available copies in atomic transaction
    return this.loanRepository.issueLoan({
      bookId,
      memberId,
      dueDate: targetDueDate,
    });
  }
}

module.exports = IssueLoan;

