const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

const LoanRepository = require('../src/domain/repositories/loan.repository');
const BookRepository = require('../src/domain/repositories/book.repository');
const MemberRepository = require('../src/domain/repositories/member.repository');
const Loan = require('../src/domain/entities/loan.entity');
const Book = require('../src/domain/entities/book.entity');
const Member = require('../src/domain/entities/member.entity');
const IssueLoan = require('../src/usecases/loans/issue-loan.usecase');
const { ConflictError, NotFoundError } = require('../src/domain/errors');

/**
 * In-memory fake repositories for unit testing IssueLoan business rules.
 */
class FakeBookRepository extends BookRepository {
  constructor() {
    super();
    this.books = [];
  }

  async findById(id) {
    return this.books.find((b) => b.id === id) || null;
  }
}

class FakeMemberRepository extends MemberRepository {
  constructor() {
    super();
    this.members = [];
  }

  async findById(id) {
    return this.members.find((m) => m.id === id) || null;
  }
}

class FakeLoanRepository extends LoanRepository {
  constructor() {
    super();
    this.loans = [];
    this.nextId = 1;
    this.activeLoanCounts = new Map();
  }

  async countActiveByMember(memberId) {
    return this.activeLoanCounts.get(memberId) || 0;
  }

  async issueLoan({ bookId, memberId, dueDate }) {
    const loan = new Loan({
      id: this.nextId++,
      bookId,
      memberId,
      issuedAt: new Date(),
      dueDate,
      returnedAt: null,
    });
    this.loans.push(loan);
    const currentCount = this.activeLoanCounts.get(memberId) || 0;
    this.activeLoanCounts.set(memberId, currentCount + 1);
    return loan;
  }
}

describe('IssueLoan Use Case – Business Rules', () => {
  let fakeBookRepo;
  let fakeMemberRepo;
  let fakeLoanRepo;
  let issueLoan;

  beforeEach(() => {
    fakeBookRepo = new FakeBookRepository();
    fakeMemberRepo = new FakeMemberRepository();
    fakeLoanRepo = new FakeLoanRepository();

    issueLoan = new IssueLoan({
      loanRepository: fakeLoanRepo,
      bookRepository: fakeBookRepo,
      memberRepository: fakeMemberRepo,
    });

    // Seed default active member
    fakeMemberRepo.members.push(
      new Member({
        id: 1,
        fullName: 'Active Member',
        admissionNumber: 'ADM-001',
        status: 'active',
      })
    );

    // Seed default available book
    fakeBookRepo.books.push(
      new Book({
        id: 1,
        isbn: '978-0132350884',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        totalCopies: 3,
        availableCopies: 2,
      })
    );
  });

  test('RULE 1: Throws ConflictError (409) when book has available_copies <= 0', async () => {
    // Book with 0 copies available
    fakeBookRepo.books.push(
      new Book({
        id: 2,
        isbn: '978-0000000000',
        title: 'Unavailable Book',
        author: 'Author',
        totalCopies: 1,
        availableCopies: 0,
      })
    );

    await assert.rejects(
      async () => {
        await issueLoan.execute({
          bookId: 2,
          memberId: 1,
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.equal(err.message, 'No available copies for this book');
        return true;
      }
    );
  });

  test('RULE 2: Throws ConflictError (409) when member is not active (e.g. suspended)', async () => {
    // Suspended member
    fakeMemberRepo.members.push(
      new Member({
        id: 2,
        fullName: 'Suspended Member',
        admissionNumber: 'ADM-002',
        status: 'suspended',
      })
    );

    await assert.rejects(
      async () => {
        await issueLoan.execute({
          bookId: 1,
          memberId: 2,
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.equal(err.message, 'Member is not active');
        return true;
      }
    );
  });

  test('RULE 3: Throws ConflictError (409) when member already holds 3 unreturned loans', async () => {
    // Member currently holds 3 active loans
    fakeLoanRepo.activeLoanCounts.set(1, 3);

    await assert.rejects(
      async () => {
        await issueLoan.execute({
          bookId: 1,
          memberId: 1,
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.match(err.message, /cannot hold more than 3 unreturned loans/);
        return true;
      }
    );
  });

  test('SUCCESS: Successfully issues loan when all business rules are satisfied', async () => {
    fakeLoanRepo.activeLoanCounts.set(1, 1); // 1 active loan, < 3

    const loan = await issueLoan.execute({
      bookId: 1,
      memberId: 1,
    });

    assert.equal(loan.id, 1);
    assert.equal(loan.bookId, 1);
    assert.equal(loan.memberId, 1);
    assert.equal(loan.returnedAt, null);
    assert.ok(loan.dueDate instanceof Date);

    // Default duration should be approximately 14 days in the future
    const fourteenDaysMs = 14 * 24 * 60 * 60 * 1000;
    const diff = loan.dueDate.getTime() - Date.now();
    assert.ok(diff > fourteenDaysMs - 10000 && diff <= fourteenDaysMs + 1000);
  });
});

