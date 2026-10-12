/**
 * Use case: Retrieves all books, optionally filtered by a search term.
 */
class ListBooks {
  /**
   * @param {import('../../domain/repositories/book.repository')} bookRepository
   */
  constructor(bookRepository) {
    this.bookRepository = bookRepository;
  }

  /**
   * @param {string} [search]
   * @returns {Promise<import('../../domain/entities/book.entity')[]>}
   */
  async execute(search) {
    return this.bookRepository.findAll(search);
  }
}

module.exports = ListBooks;
