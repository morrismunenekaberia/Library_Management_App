/**
 * Book domain entity.
 */
class Book {
  /**
   * @param {Object} params
   * @param {number} params.id
   * @param {string} params.isbn
   * @param {string} params.title
   * @param {string} params.author
   * @param {string|null} [params.category=null]
   * @param {number} params.totalCopies
   * @param {number} params.availableCopies
   */
  constructor({
    id,
    isbn,
    title,
    author,
    category = null,
    totalCopies,
    availableCopies,
  }) {
    this.id = id;
    this.isbn = isbn;
    this.title = title;
    this.author = author;
    this.category = category;
    this.totalCopies = totalCopies;
    this.availableCopies = availableCopies;
  }
}

module.exports = Book;
