/**
 * Controller handling stats endpoints.
 */
class StatsController {
  /**
   * @param {import('../../usecases/stats/get-stats.usecase')} getStatsUseCase
   */
  constructor(getStatsUseCase) {
    this.getStatsUseCase = getStatsUseCase;
  }

  /**
   * GET /api/stats
   */
  async getStats(req, res, next) {
    try {
      const stats = await this.getStatsUseCase.execute();
      return res.status(200).json(stats);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = StatsController;
