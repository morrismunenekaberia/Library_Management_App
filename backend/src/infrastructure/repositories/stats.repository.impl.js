const StatsRepository = require('../../domain/repositories/stats.repository');
const Loan = require('../../domain/entities/loan.entity');

/**
 * PostgreSQL implementation of StatsRepository.
 */
class PostgresStatsRepository extends StatsRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /**
   * Retrieves aggregated library stats and recent loans.
   */
  async getStats() {
    const countsQuery = `
      SELECT
        (SELECT COUNT(*)::int FROM books) AS total_books,
        (SELECT COUNT(*)::int FROM members WHERE status = 'active') AS active_members,
        (SELECT COUNT(*)::int FROM loans WHERE returned_at IS NULL AND due_date >= NOW()) AS active_loans,
        (SELECT COUNT(*)::int FROM loans WHERE returned_at IS NULL AND due_date < NOW()) AS overdue_loans
    `;

    const recentLoansQuery = `
      SELECT l.id, l.book_id, l.member_id, l.issued_at, l.due_date, l.returned_at,
             b.title AS book_title,
             m.full_name AS member_name
      FROM loans l
      JOIN books b ON l.book_id = b.id
      JOIN members m ON l.member_id = m.id
      ORDER BY l.issued_at DESC
      LIMIT 5
    `;

    const [countsRes, recentRes] = await Promise.all([
      this.pool.query(countsQuery),
      this.pool.query(recentLoansQuery),
    ]);

    const counts = countsRes.rows[0];
    const recentLoans = recentRes.rows.map(
      (row) =>
        new Loan({
          id: row.id,
          bookId: row.book_id,
          memberId: row.member_id,
          issuedAt: row.issued_at,
          dueDate: row.due_date,
          returnedAt: row.returned_at,
          bookTitle: row.book_title || null,
          memberName: row.member_name || null,
        })
    );

    return {
      totalBooks: counts.total_books,
      activeMembers: counts.active_members,
      activeLoans: counts.active_loans,
      overdueLoans: counts.overdue_loans,
      recentLoans,
    };
  }
}

module.exports = PostgresStatsRepository;
