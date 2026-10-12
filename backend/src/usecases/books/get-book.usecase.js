const { NotFoundError } = require('../../domain/errors');

/**
 * Use case: Retrieves a single book by ID.
 */
class GetBook {
  /**
   * @param {import('../../domain/repositories/book.repository')} bookRepository
   */
  constructor(bookRepository) {
    this.bookRepository = bookRepository;
  }

  /**
   * @param {number} id
   * @returns {Promise<import('../../domain/entities/book.entity')>}
   */
  async execute(id) {
    const book = await this.bookRepository.findById(id);
    if (!book) {
      throw new NotFoundError('Book not found');
    }
    return book;
  }
}

module.exports = GetBook;

