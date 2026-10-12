/**
 * UserRepository interface.
 * Defines the contract for user persistence operations.
 */
class UserRepository {
  /**
   * Finds a user by their unique username.
   * @param {string} username
   * @returns {Promise<import('../entities/user.entity')|null>}
   */
  async findByUsername(username) {
    throw new Error('UserRepository.findByUsername() not implemented');
  }
}

module.exports = UserRepository;

