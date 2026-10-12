const HealthRepository = require('../../domain/repositories/health.repository');

/**
 * PostgreSQL implementation of HealthRepository.
 */
class HealthRepositoryImpl extends HealthRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /** @inheritdoc */
  async checkDatabase() {
    await this.pool.query('SELECT 1');
    return true;
  }
}

module.exports = HealthRepositoryImpl;

