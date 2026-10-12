const UserRepository = require('../../domain/repositories/user.repository');
const User = require('../../domain/entities/user.entity');

/**
 * PostgreSQL implementation of UserRepository.
 */
class PostgresUserRepository extends UserRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /**
   * @param {string} username
   * @returns {Promise<User|null>}
   */
  async findByUsername(username) {
    const query = `
      SELECT id, username, password_hash, role, member_id
      FROM users
      WHERE username = $1
    `;
    const result = await this.pool.query(query, [username]);

    if (result.rows.length === 0) {
      return null;
    }

    const row = result.rows[0];
    return new User({
      id: row.id,
      username: row.username,
      passwordHash: row.password_hash,
      role: row.role,
      memberId: row.member_id,
    });
  }

  /**
   * @param {Object} userData
   * @param {string} userData.username
   * @param {string} userData.passwordHash
   * @param {string} userData.role
   * @param {number|null} [userData.memberId=null]
   * @returns {Promise<User>}
   */
  async create({ username, passwordHash, role, memberId = null }) {
    const query = `
      INSERT INTO users (username, password_hash, role, member_id)
      VALUES ($1, $2, $3, $4)
      RETURNING id, username, password_hash, role, member_id
    `;
    const result = await this.pool.query(query, [
      username,
      passwordHash,
      role,
      memberId,
    ]);
    const row = result.rows[0];
    return new User({
      id: row.id,
      username: row.username,
      passwordHash: row.password_hash,
      role: row.role,
      memberId: row.member_id,
    });
  }
}

module.exports = PostgresUserRepository;

