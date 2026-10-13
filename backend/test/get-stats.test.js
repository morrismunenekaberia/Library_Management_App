const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const GetStats = require('../src/usecases/stats/get-stats.usecase');

describe('GetStats Use Case', () => {
  it('returns statistics and recent loans from the repository', async () => {
    const mockStats = {
      totalBooks: 10,
      activeMembers: 5,
      activeLoans: 3,
      overdueLoans: 1,
      recentLoans: [
        {
          id: 1,
          bookId: 1,
          memberId: 1,
          issuedAt: new Date(),
          dueDate: new Date(),
          returnedAt: null,
          bookTitle: 'Test Book',
          memberName: 'Test Member',
        },
      ],
    };

    const mockStatsRepository = {
      getStats: async () => mockStats,
    };

    const useCase = new GetStats(mockStatsRepository);
    const result = await useCase.execute();

    assert.equal(result.totalBooks, 10);
    assert.equal(result.activeMembers, 5);
    assert.equal(result.activeLoans, 3);
    assert.equal(result.overdueLoans, 1);
    assert.equal(result.recentLoans.length, 1);
  });
});
