const {
  NotFoundError,
  ConflictError,
  ValidationError,
} = require('../../domain/errors');

/**
 * Use case: Updates an existing book.
 * Ensures consistent adjustment of available_copies when total_copies changes.
 */
class UpdateBook {
  /**
   * @param {import('../../domain/repositories/book.repository')} bookRepository
   */
  constructor(bookRepository) {
    this.bookRepository = bookRepository;
  }

  /**
   * @param {number} id
   * @param {Object} data
   * @returns {Promise<import('../../domain/entities/book.entity')>}
   */
  async execute(id, data) {
    const existingBook = await this.bookRepository.findById(id);
    if (!existingBook) {
      throw new NotFoundError('Book not found');
    }

    // Check unique ISBN if being updated
    const targetIsbn = data.isbn !== undefined ? data.isbn : existingBook.isbn;
    if (targetIsbn !== existingBook.isbn) {
      const bookWithIsbn = await this.bookRepository.findByIsbn(targetIsbn);
      if (bookWithIsbn && bookWithIsbn.id !== id) {
        throw new ConflictError('A book with this ISBN already exists');
      }
    }

    const title = data.title !== undefined ? data.title : existingBook.title;
    const author = data.author !== undefined ? data.author : existingBook.author;
    const category =
      data.category !== undefined ? data.category : existingBook.category;

    let totalCopies = existingBook.totalCopies;
    let availableCopies = existingBook.availableCopies;

    if (data.totalCopies !== undefined) {
      if (data.totalCopies < 0) {
        throw new ValidationError('Total copies cannot be negative');
      }

      // Delta adjustment: loaned copies = total - available
      const currentlyLoaned =
        existingBook.totalCopies - existingBook.availableCopies;
      const delta = data.totalCopies - existingBook.totalCopies;
      const adjustedAvailable = existingBook.availableCopies + delta;

      if (adjustedAvailable < 0) {
        throw new ValidationError(
          `Cannot reduce total copies to ${data.totalCopies}. There are ${currentlyLoaned} copies currently on loan.`
        );
      }

      totalCopies = data.totalCopies;
      availableCopies = adjustedAvailable;
    }

    return this.bookRepository.update(id, {
      isbn: targetIsbn,
      title,
      author,
      category,
      totalCopies,
      availableCopies,
    });
  }
}

module.exports = UpdateBook;

