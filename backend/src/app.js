const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

// --- Config ---
const env = require('./config/env');
const pool = require('./config/database');

// --- Domain / Use Cases ---
const HealthUseCase = require('./usecases/health.usecase');
const LoginUser = require('./usecases/login-user.usecase');
const ListBooks = require('./usecases/books/list-books.usecase');
const GetBook = require('./usecases/books/get-book.usecase');
const CreateBook = require('./usecases/books/create-book.usecase');
const UpdateBook = require('./usecases/books/update-book.usecase');
const DeleteBook = require('./usecases/books/delete-book.usecase');
const ListMembers = require('./usecases/members/list-members.usecase');
const GetMember = require('./usecases/members/get-member.usecase');
const CreateMember = require('./usecases/members/create-member.usecase');
const UpdateMember = require('./usecases/members/update-member.usecase');
const DeleteMember = require('./usecases/members/delete-member.usecase');
const IssueLoan = require('./usecases/loans/issue-loan.usecase');
const ReturnLoan = require('./usecases/loans/return-loan.usecase');
const ListLoans = require('./usecases/loans/list-loans.usecase');

// --- Infrastructure (concrete implementations) ---
const HealthRepositoryImpl = require('./infrastructure/repositories/health.repository.impl');
const PostgresUserRepository = require('./infrastructure/repositories/user.repository.impl');
const PostgresBookRepository = require('./infrastructure/repositories/book.repository.impl');
const PostgresMemberRepository = require('./infrastructure/repositories/member.repository.impl');
const PostgresLoanRepository = require('./infrastructure/repositories/loan.repository.impl');

// --- HTTP layer ---
const HealthController = require('./interfaces/http/controllers/health.controller');
const AuthController = require('./interfaces/http/controllers/auth.controller');
const BookController = require('./interfaces/http/controllers/book.controller');
const MemberController = require('./interfaces/http/controllers/member.controller');
const LoanController = require('./interfaces/http/controllers/loan.controller');
const healthRoutes = require('./interfaces/http/routes/health.routes');
const authRoutes = require('./interfaces/http/routes/auth.routes');
const bookRoutes = require('./interfaces/http/routes/book.routes');
const memberRoutes = require('./interfaces/http/routes/member.routes');
const loanRoutes = require('./interfaces/http/routes/loan.routes');
const errorHandler = require('./interfaces/http/middleware/errorHandler');

// ============================================================
// Dependency wiring (poor-man's DI — simple and explicit)
// ============================================================
const healthRepository = new HealthRepositoryImpl(pool);
const healthUseCase = new HealthUseCase(healthRepository);
const healthController = new HealthController(healthUseCase);

const userRepository = new PostgresUserRepository(pool);
const loginUserUseCase = new LoginUser(userRepository, env.jwtSecret);
const authController = new AuthController(loginUserUseCase);

const bookRepository = new PostgresBookRepository(pool);
const listBooksUseCase = new ListBooks(bookRepository);
const getBookUseCase = new GetBook(bookRepository);
const createBookUseCase = new CreateBook(bookRepository);
const updateBookUseCase = new UpdateBook(bookRepository);
const deleteBookUseCase = new DeleteBook(bookRepository);
const bookController = new BookController({
  listBooks: listBooksUseCase,
  getBook: getBookUseCase,
  createBook: createBookUseCase,
  updateBook: updateBookUseCase,
  deleteBook: deleteBookUseCase,
});

const memberRepository = new PostgresMemberRepository(pool);
const listMembersUseCase = new ListMembers(memberRepository);
const getMemberUseCase = new GetMember(memberRepository);
const createMemberUseCase = new CreateMember(memberRepository, userRepository);
const updateMemberUseCase = new UpdateMember(memberRepository);
const deleteMemberUseCase = new DeleteMember(memberRepository);
const memberController = new MemberController({
  listMembers: listMembersUseCase,
  getMember: getMemberUseCase,
  createMember: createMemberUseCase,
  updateMember: updateMemberUseCase,
  deleteMember: deleteMemberUseCase,
});

const loanRepository = new PostgresLoanRepository(pool);
const issueLoanUseCase = new IssueLoan({
  loanRepository,
  bookRepository,
  memberRepository,
});
const returnLoanUseCase = new ReturnLoan(loanRepository);
const listLoansUseCase = new ListLoans(loanRepository);
const loanController = new LoanController({
  issueLoan: issueLoanUseCase,
  returnLoan: returnLoanUseCase,
  listLoans: listLoansUseCase,
});

// ============================================================
// Express application
// ============================================================
const app = express();

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://10.0.2.2:3000'];

const corsOptions = {
  origin: (origin, callback) => {
    // Allow non-browser clients (Flutter ApiClient, curl, mobile native) with no origin header
    if (!origin) return callback(null, true);
    if (
      allowedOrigins.includes(origin) ||
      process.env.NODE_ENV !== 'production'
    ) {
      return callback(null, true);
    }
    return callback(new Error('Not allowed by CORS policy'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json());

// --- Routes ---
app.use('/api', healthRoutes(healthController));
app.use('/api/auth', authRoutes(authController));
app.use('/api/books', bookRoutes(bookController));
app.use('/api/members', memberRoutes(memberController));
app.use('/api/loans', loanRoutes(loanController));

// --- Centralized error handler (must be registered last) ---
app.use(errorHandler);

module.exports = app;

