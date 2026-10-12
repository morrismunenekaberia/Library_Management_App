const { NotFoundError } = require('../../domain/errors');

/**
 * Use case: Retrieves a member by ID.
 */
class GetMember {
  /**
   * @param {import('../../domain/repositories/member.repository')} memberRepository
   */
  constructor(memberRepository) {
    this.memberRepository = memberRepository;
  }

  /**
   * @param {number} id
   * @returns {Promise<import('../../domain/entities/member.entity')>}
   */
  async execute(id) {
    const member = await this.memberRepository.findById(id);
    if (!member) {
      throw new NotFoundError('Member not found');
    }
    return member;
  }
}

module.exports = GetMember;

