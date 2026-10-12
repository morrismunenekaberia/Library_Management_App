const { ConflictError, ValidationError } = require('../../domain/errors');

/**
 * Use case: Creates a new book in the library catalogue.
 */
class CreateBook {
  /**
   * @param {import('../../domain/repositories/book.repository')} bookRepository
   */
  constructor(bookRepository) {
    this.bookRepository = bookRepository;
  }

  /**
   * @param {Object} data
   * @param {string} data.isbn
   * @param {string} data.title
   * @param {string} data.author
   * @param {string|null} [data.category]
   * @param {number} data.totalCopies
   * @param {number} [data.availableCopies]
   * @returns {Promise<import('../../domain/entities/book.entity')>}
   */
  async execute({ isbn, title, author, category, totalCopies, availableCopies }) {
    if (totalCopies < 0) {
      throw new ValidationError('Total copies cannot be negative');
    }

    const existingBook = await this.bookRepository.findByIsbn(isbn);
    if (existingBook) {
      throw new ConflictError('A book with this ISBN already exists');
    }

    // Newly added books have all copies available unless specified
    const initialAvailable =
      availableCopies !== undefined ? availableCopies : totalCopies;

    if (initialAvailable < 0 || initialAvailable > totalCopies) {
      throw new ValidationError(
        'Available copies must be between 0 and total copies'
      );
    }

    return this.bookRepository.create({
      isbn,
      title,
      author,
      category: category || null,
      totalCopies,
      availableCopies: initialAvailable,
    });
  }
}

module.exports = CreateBook;

