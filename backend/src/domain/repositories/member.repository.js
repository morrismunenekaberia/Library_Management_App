/**
 * MemberRepository interface.
 * Defines the contract for member persistence operations.
 */
class MemberRepository {
  /**
   * Finds all members, optionally filtered by a search term.
   * @param {string} [search]
   * @returns {Promise<import('../entities/member.entity')[]>}
   */
  async findAll(search) {
    throw new Error('MemberRepository.findAll() not implemented');
  }

  /**
   * Finds a member by primary key ID.
   * @param {number} id
   * @returns {Promise<import('../entities/member.entity')|null>}
   */
  async findById(id) {
    throw new Error('MemberRepository.findById() not implemented');
  }

  /**
   * Finds a member by admission number.
   * @param {string} admissionNumber
   * @returns {Promise<import('../entities/member.entity')|null>}
   */
  async findByAdmissionNumber(admissionNumber) {
    throw new Error('MemberRepository.findByAdmissionNumber() not implemented');
  }

  /**
   * Inserts a new member record.
   * @param {Object} memberData
   * @returns {Promise<import('../entities/member.entity')>}
   */
  async create(memberData) {
    throw new Error('MemberRepository.create() not implemented');
  }

  /**
   * Updates an existing member record.
   * @param {number} id
   * @param {Object} memberData
   * @returns {Promise<import('../entities/member.entity')>}
   */
  async update(id, memberData) {
    throw new Error('MemberRepository.update() not implemented');
  }

  /**
   * Deletes a member by ID.
   * @param {number} id
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    throw new Error('MemberRepository.delete() not implemented');
  }

  /**
   * Checks whether the member currently has active (unreturned) loans.
   * @param {number} memberId
   * @returns {Promise<boolean>}
   */
  async hasActiveLoans(memberId) {
    throw new Error('MemberRepository.hasActiveLoans() not implemented');
  }
}

module.exports = MemberRepository;

