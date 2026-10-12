const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

const BookRepository = require('../src/domain/repositories/book.repository');
const Book = require('../src/domain/entities/book.entity');
const CreateBook = require('../src/usecases/books/create-book.usecase');
const DeleteBook = require('../src/usecases/books/delete-book.usecase');
const {
  ConflictError,
  ValidationError,
  NotFoundError,
} = require('../src/domain/errors');

/**
 * Fake in-memory implementation of BookRepository for lightweight unit testing.
 */
class FakeBookRepository extends BookRepository {
  constructor() {
    super();
    this.books = [];
    this.activeLoans = new Set();
    this.nextId = 1;
  }

  async findAll() {
    return [...this.books];
  }

  async findById(id) {
    return this.books.find((b) => b.id === id) || null;
  }

  async findByIsbn(isbn) {
    return this.books.find((b) => b.isbn === isbn) || null;
  }

  async create(data) {
    const book = new Book({
      id: this.nextId++,
      isbn: data.isbn,
      title: data.title,
      author: data.author,
      category: data.category || null,
      totalCopies: data.totalCopies,
      availableCopies: data.availableCopies,
    });
    this.books.push(book);
    return book;
  }

  async update(id, data) {
    const index = this.books.findIndex((b) => b.id === id);
    if (index === -1) return null;
    const updated = new Book({ id, ...data });
    this.books[index] = updated;
    return updated;
  }

  async delete(id) {
    const index = this.books.findIndex((b) => b.id === id);
    if (index === -1) return false;
    this.books.splice(index, 1);
    return true;
  }

  async hasActiveLoans(bookId) {
    return this.activeLoans.has(bookId);
  }
}

describe('CreateBook Use Case', () => {
  let fakeRepo;
  let createBook;

  beforeEach(() => {
    fakeRepo = new FakeBookRepository();
    createBook = new CreateBook(fakeRepo);
  });

  test('successfully creates a book with valid data and sets availableCopies = totalCopies', async () => {
    const result = await createBook.execute({
      isbn: '978-0132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Software',
      totalCopies: 5,
    });

    assert.equal(result.id, 1);
    assert.equal(result.isbn, '978-0132350884');
    assert.equal(result.title, 'Clean Code');
    assert.equal(result.totalCopies, 5);
    assert.equal(result.availableCopies, 5);
    assert.equal(fakeRepo.books.length, 1);
  });

  test('throws ConflictError (409) when creating a book with duplicate ISBN', async () => {
    await createBook.execute({
      isbn: '978-0132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      totalCopies: 3,
    });

    await assert.rejects(
      async () => {
        await createBook.execute({
          isbn: '978-0132350884',
          title: 'Another Book with Same ISBN',
          author: 'Some Author',
          totalCopies: 2,
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.equal(err.message, 'A book with this ISBN already exists');
        return true;
      }
    );
  });

  test('throws ValidationError (400) when totalCopies is negative', async () => {
    await assert.rejects(
      async () => {
        await createBook.execute({
          isbn: '978-1111111111',
          title: 'Invalid Book',
          author: 'Author',
          totalCopies: -1,
        });
      },
      (err) => {
        assert(err instanceof ValidationError);
        assert.equal(err.statusCode, 400);
        assert.equal(err.message, 'Total copies cannot be negative');
        return true;
      }
    );
  });

  test('throws ValidationError (400) when availableCopies exceeds totalCopies', async () => {
    await assert.rejects(
      async () => {
        await createBook.execute({
          isbn: '978-1111111111',
          title: 'Invalid Book',
          author: 'Author',
          totalCopies: 2,
          availableCopies: 5,
        });
      },
      (err) => {
        assert(err instanceof ValidationError);
        assert.equal(err.statusCode, 400);
        return true;
      }
    );
  });
});

describe('DeleteBook Use Case', () => {
  let fakeRepo;
  let deleteBook;

  beforeEach(async () => {
    fakeRepo = new FakeBookRepository();
    deleteBook = new DeleteBook(fakeRepo);

    // Seed one book
    await fakeRepo.create({
      isbn: '978-0132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      totalCopies: 3,
      availableCopies: 3,
    });
  });

  test('successfully deletes a book when there are no active loans', async () => {
    const result = await deleteBook.execute(1);

    assert.deepEqual(result, { success: true });
    assert.equal(fakeRepo.books.length, 0);
  });

  test('throws NotFoundError (404) when deleting non-existent book', async () => {
    await assert.rejects(
      async () => {
        await deleteBook.execute(999);
      },
      (err) => {
        assert(err instanceof NotFoundError);
        assert.equal(err.statusCode, 404);
        assert.equal(err.message, 'Book not found');
        return true;
      }
    );
  });

  test('throws ConflictError (409) when book has active unreturned loans', async () => {
    // Mark book id 1 as having an active unreturned loan
    fakeRepo.activeLoans.add(1);

    await assert.rejects(
      async () => {
        await deleteBook.execute(1);
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert(err.message.includes('active unreturned loans'));
        return true;
      }
    );

    // Book should NOT be deleted
    assert.equal(fakeRepo.books.length, 1);
  });
});

