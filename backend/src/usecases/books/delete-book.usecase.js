const { NotFoundError, ConflictError } = require('../../domain/errors');

/**
 * Use case: Deletes a book from the library catalogue.
 * Blocks deletion if the book currently has active (unreturned) loans.
 */
class DeleteBook {
  /**
   * @param {import('../../domain/repositories/book.repository')} bookRepository
   */
  constructor(bookRepository) {
    this.bookRepository = bookRepository;
  }

  /**
   * @param {number} id
   * @returns {Promise<{success: boolean}>}
   */
  async execute(id) {
    const book = await this.bookRepository.findById(id);
    if (!book) {
      throw new NotFoundError('Book not found');
    }

    const hasActiveLoans = await this.bookRepository.hasActiveLoans(id);
    if (hasActiveLoans) {
      throw new ConflictError(
        'Cannot delete book because it currently has active unreturned loans'
      );
    }

    await this.bookRepository.delete(id);
    return { success: true };
  }
}

module.exports = DeleteBook;

