const BookRepository = require('../../domain/repositories/book.repository');
const Book = require('../../domain/entities/book.entity');

/**
 * PostgreSQL implementation of BookRepository.
 */
class PostgresBookRepository extends BookRepository {
  /**
   * @param {import('pg').Pool} pool
   */
  constructor(pool) {
    super();
    this.pool = pool;
  }

  /**
   * Maps a database row to a Book domain entity.
   * @private
   */
  _mapRowToEntity(row) {
    return new Book({
      id: row.id,
      isbn: row.isbn,
      title: row.title,
      author: row.author,
      category: row.category,
      totalCopies: row.total_copies,
      availableCopies: row.available_copies,
    });
  }

  /**
   * Finds all books with optional search by title, author, or ISBN.
   * @param {string} [search]
   * @returns {Promise<Book[]>}
   */
  async findAll(search) {
    if (search && search.trim()) {
      const term = `%${search.trim()}%`;
      const query = `
        SELECT id, isbn, title, author, category, total_copies, available_copies
        FROM books
        WHERE title ILIKE $1 OR author ILIKE $1 OR isbn ILIKE $1
        ORDER BY id ASC
      `;
      const result = await this.pool.query(query, [term]);
      return result.rows.map((row) => this._mapRowToEntity(row));
    }

    const query = `
      SELECT id, isbn, title, author, category, total_copies, available_copies
      FROM books
      ORDER BY id ASC
    `;
    const result = await this.pool.query(query);
    return result.rows.map((row) => this._mapRowToEntity(row));
  }

  /**
   * Finds a book by ID.
   * @param {number} id
   * @returns {Promise<Book|null>}
   */
  async findById(id) {
    const query = `
      SELECT id, isbn, title, author, category, total_copies, available_copies
      FROM books
      WHERE id = $1
    `;
    const result = await this.pool.query(query, [id]);
    if (result.rows.length === 0) {
      return null;
    }
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Finds a book by unique ISBN.
   * @param {string} isbn
   * @returns {Promise<Book|null>}
   */
  async findByIsbn(isbn) {
    const query = `
      SELECT id, isbn, title, author, category, total_copies, available_copies
      FROM books
      WHERE isbn = $1
    `;
    const result = await this.pool.query(query, [isbn]);
    if (result.rows.length === 0) {
      return null;
    }
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Inserts a new book.
   * @param {Object} bookData
   * @returns {Promise<Book>}
   */
  async create({ isbn, title, author, category, totalCopies, availableCopies }) {
    const query = `
      INSERT INTO books (isbn, title, author, category, total_copies, available_copies)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, isbn, title, author, category, total_copies, available_copies
    `;
    const values = [
      isbn,
      title,
      author,
      category || null,
      totalCopies,
      availableCopies,
    ];
    const result = await this.pool.query(query, values);
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Updates an existing book.
   * @param {number} id
   * @param {Object} bookData
   * @returns {Promise<Book>}
   */
  async update(id, { isbn, title, author, category, totalCopies, availableCopies }) {
    const query = `
      UPDATE books
      SET isbn = $1, title = $2, author = $3, category = $4, total_copies = $5, available_copies = $6
      WHERE id = $7
      RETURNING id, isbn, title, author, category, total_copies, available_copies
    `;
    const values = [
      isbn,
      title,
      author,
      category || null,
      totalCopies,
      availableCopies,
      id,
    ];
    const result = await this.pool.query(query, values);
    return this._mapRowToEntity(result.rows[0]);
  }

  /**
   * Deletes a book by ID.
   * @param {number} id
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    const query = 'DELETE FROM books WHERE id = $1';
    const result = await this.pool.query(query, [id]);
    return result.rowCount > 0;
  }

  /**
   * Checks whether the book has active (unreturned) loans.
   * @param {number} bookId
   * @returns {Promise<boolean>}
   */
  async hasActiveLoans(bookId) {
    const query = `
      SELECT 1 FROM loans
      WHERE book_id = $1 AND returned_at IS NULL
      LIMIT 1
    `;
    const result = await this.pool.query(query, [bookId]);
    return result.rows.length > 0;
  }
}

module.exports = PostgresBookRepository;

