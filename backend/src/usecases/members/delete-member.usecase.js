const { NotFoundError, ConflictError } = require('../../domain/errors');

/**
 * Use case: Deletes a member.
 * Prevents deletion if the member has active (unreturned) loans.
 */
class DeleteMember {
  /**
   * @param {import('../../domain/repositories/member.repository')} memberRepository
   */
  constructor(memberRepository) {
    this.memberRepository = memberRepository;
  }

  /**
   * @param {number} id
   * @returns {Promise<{success: boolean}>}
   */
  async execute(id) {
    const member = await this.memberRepository.findById(id);
    if (!member) {
      throw new NotFoundError('Member not found');
    }

    const hasActiveLoans = await this.memberRepository.hasActiveLoans(id);
    if (hasActiveLoans) {
      throw new ConflictError(
        'Cannot delete member because they currently have active unreturned loans'
      );
    }

    await this.memberRepository.delete(id);
    return { success: true };
  }
}

module.exports = DeleteMember;

