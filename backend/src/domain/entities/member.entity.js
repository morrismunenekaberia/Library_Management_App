/**
 * Member domain entity.
 */
class Member {
  /**
   * @param {Object} params
   * @param {number} params.id
   * @param {string} params.fullName
   * @param {string} params.admissionNumber
   * @param {string|null} [params.phone=null]
   * @param {string|null} [params.email=null]
   * @param {Date|string} [params.joinedAt]
   * @param {'active'|'suspended'} [params.status='active']
   */
  constructor({
    id,
    fullName,
    admissionNumber,
    phone = null,
    email = null,
    joinedAt = new Date(),
    status = 'active',
  }) {
    this.id = id;
    this.fullName = fullName;
    this.admissionNumber = admissionNumber;
    this.phone = phone;
    this.email = email;
    this.joinedAt = joinedAt;
    this.status = status;
  }
}

module.exports = Member;

