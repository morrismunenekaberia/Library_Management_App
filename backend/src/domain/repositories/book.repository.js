/**
 * BookRepository interface.
 * Defines persistence contract for books.
 */
class BookRepository {
  /**
   * Finds all books, optionally filtered by a search term.
   * @param {string} [search]
   * @returns {Promise<import('../entities/book.entity')[]>}
   */
  async findAll(search) {
    throw new Error('BookRepository.findAll() not implemented');
  }

  /**
   * Finds a book by primary key ID.
   * @param {number} id
   * @returns {Promise<import('../entities/book.entity')|null>}
   */
  async findById(id) {
    throw new Error('BookRepository.findById() not implemented');
  }

  /**
   * Finds a book by unique ISBN.
   * @param {string} isbn
   * @returns {Promise<import('../entities/book.entity')|null>}
   */
  async findByIsbn(isbn) {
    throw new Error('BookRepository.findByIsbn() not implemented');
  }

  /**
   * Inserts a new book.
   * @param {Object} bookData
   * @returns {Promise<import('../entities/book.entity')>}
   */
  async create(bookData) {
    throw new Error('BookRepository.create() not implemented');
  }

  /**
   * Updates an existing book.
   * @param {number} id
   * @param {Object} bookData
   * @returns {Promise<import('../entities/book.entity')>}
   */
  async update(id, bookData) {
    throw new Error('BookRepository.update() not implemented');
  }

  /**
   * Deletes a book by ID.
   * @param {number} id
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    throw new Error('BookRepository.delete() not implemented');
  }

  /**
   * Checks whether the book has active (unreturned) loans.
   * @param {number} bookId
   * @returns {Promise<boolean>}
   */
  async hasActiveLoans(bookId) {
    throw new Error('BookRepository.hasActiveLoans() not implemented');
  }
}

module.exports = BookRepository;
