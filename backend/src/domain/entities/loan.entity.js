/**
 * Loan domain entity.
 */
class Loan {
  /**
   * @param {Object} params
   * @param {number} params.id
   * @param {number} params.bookId
   * @param {number} params.memberId
   * @param {Date|string} params.issuedAt
   * @param {Date|string} params.dueDate
   * @param {Date|string|null} [params.returnedAt=null]
   * @param {string} [params.bookTitle]
   * @param {string} [params.memberName]
   */
  constructor({
    id,
    bookId,
    memberId,
    issuedAt = new Date(),
    dueDate,
    returnedAt = null,
    bookTitle = null,
    memberName = null,
  }) {
    this.id = id;
    this.bookId = bookId;
    this.memberId = memberId;
    this.issuedAt = issuedAt;
    this.dueDate = dueDate;
    this.returnedAt = returnedAt;
    this.bookTitle = bookTitle;
    this.memberName = memberName;
  }
}

module.exports = Loan;

