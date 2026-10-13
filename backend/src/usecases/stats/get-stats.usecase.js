/**
 * Use case to retrieve library statistics and recent loans.
 */
class GetStats {
  /**
   * @param {import('../../domain/repositories/stats.repository')} statsRepository
   */
  constructor(statsRepository) {
    this.statsRepository = statsRepository;
  }

  /**
   * Executes the use case.
   */
  async execute() {
    return this.statsRepository.getStats();
  }
}

module.exports = GetStats;

