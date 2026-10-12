const { ValidationError } = require('../../../domain/errors');

class BookController {
  /**
   * @param {Object} usecases
   * @param {import('../../../usecases/books/list-books.usecase')} usecases.listBooks
   * @param {import('../../../usecases/books/get-book.usecase')} usecases.getBook
   * @param {import('../../../usecases/books/create-book.usecase')} usecases.createBook
   * @param {import('../../../usecases/books/update-book.usecase')} usecases.updateBook
   * @param {import('../../../usecases/books/delete-book.usecase')} usecases.deleteBook
   */
  constructor({ listBooks, getBook, createBook, updateBook, deleteBook }) {
    this.listBooks = listBooks;
    this.getBook = getBook;
    this.createBook = createBook;
    this.updateBook = updateBook;
    this.deleteBook = deleteBook;
  }

  /**
   * Helper to parse integer ID parameter.
   */
  _parseId(param) {
    const id = parseInt(param, 10);
    if (isNaN(id) || id <= 0) {
      throw new ValidationError('Invalid book ID parameter');
    }
    return id;
  }

  /**
   * GET /api/books?search=
   */
  async list(req, res, next) {
    try {
      const search = req.query.search;
      const books = await this.listBooks.execute(search);
      return res.status(200).json(books);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/books/:id
   */
  async getById(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      const book = await this.getBook.execute(id);
      return res.status(200).json(book);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/books
   */
  async create(req, res, next) {
    try {
      const book = await this.createBook.execute(req.body);
      return res.status(201).json(book);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PUT /api/books/:id
   */
  async update(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      const updatedBook = await this.updateBook.execute(id, req.body);
      return res.status(200).json(updatedBook);
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/books/:id
   */
  async delete(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      await this.deleteBook.execute(id);
      return res.status(200).json({ message: 'Book deleted successfully' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = BookController;

