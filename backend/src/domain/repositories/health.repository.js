/**
 * Health repository interface.
 * Concrete implementations must override every method.
 */
class HealthRepository {
  /**
   * Pings the database to verify connectivity.
   * @returns {Promise<boolean>} true if the database is reachable
   */
  async checkDatabase() {
    throw new Error('HealthRepository.checkDatabase() not implemented');
  }
}

module.exports = HealthRepository;

