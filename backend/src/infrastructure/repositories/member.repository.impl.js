const MemberRepository = require('../../domain/repositories/member.repository');
const Member = require('../../domain/entities/member.entity');

/**
 * PostgreSQL implementation of MemberRepository.
 */
class PostgresMemberRepository extends MemberRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /**
   * Maps a database row to a Member domain entity.
   * @private
   */
  _mapRowToEntity(row) {
    return new Member({
      id: row.id,
      fullName: row.full_name,
      admissionNumber: row.admission_number,
      phone: row.phone,
      email: row.email,
      joinedAt: row.joined_at,
      status: row.status,
    });
  }

  /**
   * Finds all members, optionally filtered by search term.
   * @param {string} [search]
   * @returns {Promise<Member[]>}
   */
  async findAll(search) {
    if (search && search.trim()) {
      const term = `%${search.trim()}%`;
      const query = `
        SELECT id, full_name, admission_number, phone, email, joined_at, status
        FROM members
        WHERE full_name ILIKE $1 OR admission_number ILIKE $1 OR email ILIKE $1
        ORDER BY id ASC
      `;
      const result = await this.pool.query(query, [term]);
      return result.rows.map((row) => this._mapRowToEntity(row));
    }

    const query = `
      SELECT id, full_name, admission_number, phone, email, joined_at, status
      FROM members
      ORDER BY id ASC
    `;
    const result = await this.pool.query(query);
    return result.rows.map((row) => this._mapRowToEntity(row));
  }

  /**
   * Finds a member by ID.
   * @param {number} id
   * @returns {Promise<Member|null>}
   */
  async findById(id) {
    const query = `
      SELECT id, full_name, admission_number, phone, email, joined_at, status
      FROM members
      WHERE id = $1
    `;
    const result = await this.pool.query(query, [id]);
    if (result.rows.length === 0) {
      return null;
    }
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Finds a member by admission number.
   * @param {string} admissionNumber
   * @returns {Promise<Member|null>}
   */
  async findByAdmissionNumber(admissionNumber) {
    const query = `
      SELECT id, full_name, admission_number, phone, email, joined_at, status
      FROM members
      WHERE admission_number = $1
    `;
    const result = await this.pool.query(query, [admissionNumber]);
    if (result.rows.length === 0) {
      return null;
    }
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Inserts a new member record.
   * @param {Object} memberData
   * @returns {Promise<Member>}
   */
  async create({ fullName, admissionNumber, phone, email, status = 'active' }) {
    const query = `
      INSERT INTO members (full_name, admission_number, phone, email, status)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, full_name, admission_number, phone, email, joined_at, status
    `;
    const values = [
      fullName,
      admissionNumber,
      phone || null,
      email || null,
      status || 'active',
    ];
    const result = await this.pool.query(query, values);
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Updates an existing member record.
   * @param {number} id
   * @param {Object} memberData
   * @returns {Promise<Member>}
   */
  async update(id, { fullName, admissionNumber, phone, email, status }) {
    const query = `
      UPDATE members
      SET full_name = $1, admission_number = $2, phone = $3, email = $4, status = $5
      WHERE id = $6
      RETURNING id, full_name, admission_number, phone, email, joined_at, status
    `;
    const values = [
      fullName,
      admissionNumber,
      phone || null,
      email || null,
      status || 'active',
      id,
    ];
    const result = await this.pool.query(query, values);
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Deletes a member by ID.
   * @param {number} id
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    const query = 'DELETE FROM members WHERE id = $1';
    const result = await this.pool.query(query, [id]);
    return result.rowCount > 0;
  }

  /**
   * Checks whether the member currently has active (unreturned) loans.
   * @param {number} memberId
   * @returns {Promise<boolean>}
   */
  async hasActiveLoans(memberId) {
    const query = `
      SELECT 1 FROM loans
      WHERE member_id = $1 AND returned_at IS NULL
      LIMIT 1
    `;
    const result = await this.pool.query(query, [memberId]);
    return result.rows.length > 0;
  }
}

module.exports = PostgresMemberRepository;

