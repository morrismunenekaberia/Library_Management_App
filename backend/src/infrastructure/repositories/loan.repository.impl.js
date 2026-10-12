const LoanRepository = require('../../domain/repositories/loan.repository');
const Loan = require('../../domain/entities/loan.entity');
const {
  NotFoundError,
  ConflictError,
} = require('../../domain/errors');

/**
 * PostgreSQL implementation of LoanRepository.
 */
class PostgresLoanRepository extends LoanRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /**
   * Maps a DB row to a Loan entity.
   * @private
   */
  _mapRowToEntity(row) {
    return new Loan({
      id: row.id,
      bookId: row.book_id,
      memberId: row.member_id,
      issuedAt: row.issued_at,
      dueDate: row.due_date,
      returnedAt: row.returned_at,
      bookTitle: row.book_title || null,
      memberName: row.member_name || null,
    });
  }

  /**
   * Issues a loan atomically with a transaction and SELECT ... FOR UPDATE.
   */
  async issueLoan({ bookId, memberId, dueDate }) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Lock the book row to prevent concurrent race condition on available_copies
      const bookRes = await client.query(
        'SELECT id, title, available_copies FROM books WHERE id = $1 FOR UPDATE',
        [bookId]
      );

      if (bookRes.rows.length === 0) {
        throw new NotFoundError('Book not found');
      }

      const book = bookRes.rows[0];
      if (book.available_copies <= 0) {
        throw new ConflictError('No available copies for this book');
      }

      // Decrement available copies
      await client.query(
        'UPDATE books SET available_copies = available_copies - 1 WHERE id = $1',
        [bookId]
      );

      // Insert loan record
      const loanRes = await client.query(
        `INSERT INTO loans (book_id, member_id, due_date)
         VALUES ($1, $2, $3)
         RETURNING id, book_id, member_id, issued_at, due_date, returned_at`,
        [bookId, memberId, dueDate]
      );

      // Fetch member full name
      const memberRes = await client.query(
        'SELECT full_name FROM members WHERE id = $1',
        [memberId]
      );

      await client.query('COMMIT');

      const loanRow = loanRes.rows[0];
      return new Loan({
        id: loanRow.id,
        bookId: loanRow.book_id,
        memberId: loanRow.member_id,
        issuedAt: loanRow.issued_at,
        dueDate: loanRow.due_date,
        returnedAt: loanRow.returned_at,
        bookTitle: book.title,
        memberName: memberRes.rows[0]?.full_name || null,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Returns a loan atomically with a transaction.
   */
  async returnLoan(loanId) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Lock loan row
      const loanRes = await client.query(
        `SELECT l.id, l.book_id, l.member_id, l.issued_at, l.due_date, l.returned_at,
                b.title AS book_title,
                m.full_name AS member_name
         FROM loans l
         JOIN books b ON l.book_id = b.id
         JOIN members m ON l.member_id = m.id
         WHERE l.id = $1
         FOR UPDATE OF l`,
        [loanId]
      );

      if (loanRes.rows.length === 0) {
        throw new NotFoundError('Loan not found');
      }

      const loan = loanRes.rows[0];
      if (loan.returned_at !== null) {
        throw new ConflictError('Loan has already been returned');
      }

      // Set returned_at
      const updatedLoanRes = await client.query(
        `UPDATE loans
         SET returned_at = NOW()
         WHERE id = $1
         RETURNING id, book_id, member_id, issued_at, due_date, returned_at`,
        [loanId]
      );

      // Increment available copies of book
      await client.query(
        'UPDATE books SET available_copies = available_copies + 1 WHERE id = $1',
        [loan.book_id]
      );

      await client.query('COMMIT');

      const updatedRow = updatedLoanRes.rows[0];
      return new Loan({
        id: updatedRow.id,
        bookId: updatedRow.book_id,
        memberId: updatedRow.member_id,
        issuedAt: updatedRow.issued_at,
        dueDate: updatedRow.due_date,
        returnedAt: updatedRow.returned_at,
        bookTitle: loan.book_title,
        memberName: loan.member_name,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Finds a loan by ID with book and member information.
   */
  async findById(id) {
    const query = `
      SELECT l.id, l.book_id, l.member_id, l.issued_at, l.due_date, l.returned_at,
             b.title AS book_title,
             m.full_name AS member_name
      FROM loans l
      JOIN books b ON l.book_id = b.id
      JOIN members m ON l.member_id = m.id
      WHERE l.id = $1
    `;
    const result = await this.pool.query(query, [id]);
    if (result.rows.length === 0) {
      return null;
    }
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Counts active (unreturned) loans for a given member.
   */
  async countActiveByMember(memberId) {
    const query = `
      SELECT COUNT(*)::int AS count
      FROM loans
      WHERE member_id = $1 AND returned_at IS NULL
    `;
    const result = await this.pool.query(query, [memberId]);
    return result.rows[0].count;
  }

  /**
   * Finds all loans matching status and optional memberId.
   */
  async findAll({ status, memberId } = {}) {
    const conditions = [];
    const values = [];

    if (status === 'active') {
      conditions.push('l.returned_at IS NULL AND l.due_date >= NOW()');
    } else if (status === 'overdue') {
      conditions.push('l.returned_at IS NULL AND l.due_date < NOW()');
    } else if (status === 'returned') {
      conditions.push('l.returned_at IS NOT NULL');
    }

    if (memberId !== undefined && memberId !== null) {
      values.push(memberId);
      conditions.push(`l.member_id = $${values.length}`);
    }

    const whereClause =
      conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const query = `
      SELECT l.id, l.book_id, l.member_id, l.issued_at, l.due_date, l.returned_at,
             b.title AS book_title,
             m.full_name AS member_name
      FROM loans l
      JOIN books b ON l.book_id = b.id
      JOIN members m ON l.member_id = m.id
      ${whereClause}
      ORDER BY l.issued_at DESC
    `;

    const result = await this.pool.query(query, values);
    return result.rows.map((row) => this._mapRowToEntity(row));
  }
}

module.exports = PostgresLoanRepository;

