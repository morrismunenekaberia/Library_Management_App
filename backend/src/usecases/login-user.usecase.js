const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { UnauthorizedError } = require('../domain/errors');

/**
 * Use case: Authenticates a user and generates a JWT.
 */
class LoginUser {
  /**
   * @param {import('../domain/repositories/user.repository')} userRepository
   * @param {string} jwtSecret
   */
  constructor(userRepository, jwtSecret) {
    this.userRepository = userRepository;
    this.jwtSecret = jwtSecret;
  }

  /**
   * @param {Object} credentials
   * @param {string} credentials.username
   * @param {string} credentials.password
   * @returns {Promise<{token: string, user: {id: number, username: string, role: string, memberId: number|null}}>}
   */
  async execute({ username, password }) {
    const user = await this.userRepository.findByUsername(username);

    // Generic error message to prevent username enumeration
    if (!user) {
      throw new UnauthorizedError('Invalid username or password');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid username or password');
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      this.jwtSecret,
      { expiresIn: '8h' }
    );

    return {
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        memberId: user.memberId,
      },
    };
  }
}

module.exports = LoginUser;

