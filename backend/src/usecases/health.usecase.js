class HealthUseCase {
  /**
   * @param {import('../domain/repositories/health.repository')} healthRepository
   */
  constructor(healthRepository) {
    this.healthRepository = healthRepository;
  }

  /**
   * Checks overall service health.
   * @returns {Promise<{status: string, database: boolean}>}
   */
  async execute() {
    const dbOk = await this.healthRepository.checkDatabase();
    return { status: 'ok', database: dbOk };
  }
}

module.exports = HealthUseCase;

