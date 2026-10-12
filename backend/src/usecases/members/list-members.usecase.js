/**
 * Use case: Retrieves all members, optionally filtered by a search term.
 */
class ListMembers {
  /**
   * @param {import('../../domain/repositories/member.repository')} memberRepository
   */
  constructor(memberRepository) {
    this.memberRepository = memberRepository;
  }

  /**
   * @param {string} [search]
   * @returns {Promise<import('../../domain/entities/member.entity')[]>}
   */
  async execute(search) {
    return this.memberRepository.findAll(search);
  }
}

module.exports = ListMembers;

