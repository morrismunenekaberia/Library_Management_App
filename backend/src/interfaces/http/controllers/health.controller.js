class HealthController {
  /**
   * @param {import('../../../usecases/health.usecase')} healthUseCase
   */
  constructor(healthUseCase) {
    this.healthUseCase = healthUseCase;
  }

  /**
   * GET /api/health
   * Delegates entirely to the use case—no business logic here.
   */
  async getHealth(req, res, next) {
    try {
      const result = await this.healthUseCase.execute();
      return res.json(result);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = HealthController;

