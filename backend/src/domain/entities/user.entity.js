/**
 * User domain entity.
 */
class User {
  /**
   * @param {Object} params
   * @param {number} params.id
   * @param {string} params.username
   * @param {string} params.passwordHash
   * @param {'librarian'|'member'} params.role
   * @param {number|null} [params.memberId=null]
   */
  constructor({ id, username, passwordHash, role, memberId = null }) {
    this.id = id;
    this.username = username;
    this.passwordHash = passwordHash;
    this.role = role;
    this.memberId = memberId;
  }
}

module.exports = User;

