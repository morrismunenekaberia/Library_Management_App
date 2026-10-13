/**
 * Interface for Stats repository.
 */
class StatsRepository {
  /**
   * Retrieves aggregated library stats and recent loans.
   * @returns {Promise<{
   *   totalBooks: number,
   *   activeMembers: number,
   *   activeLoans: number,
   *   overdueLoans: number,
   *   recentLoans: Array<import('../entities/loan.entity')>
   * }>}
   */
  async getStats() {
    throw new Error('Method not implemented');
  }
}

module.exports = StatsRepository;
