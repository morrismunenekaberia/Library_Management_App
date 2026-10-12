const express = require('express');
const cors = require('cors');

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

// --- Infrastructure (concrete implementations) ---
const HealthRepositoryImpl = require('./infrastructure/repositories/health.repository.impl');
const PostgresUserRepository = require('./infrastructure/repositories/user.repository.impl');
const PostgresBookRepository = require('./infrastructure/repositories/book.repository.impl');

// --- HTTP layer ---
const HealthController = require('./interfaces/http/controllers/health.controller');
const AuthController = require('./interfaces/http/controllers/auth.controller');
const BookController = require('./interfaces/http/controllers/book.controller');
const healthRoutes = require('./interfaces/http/routes/health.routes');
const authRoutes = require('./interfaces/http/routes/auth.routes');
const bookRoutes = require('./interfaces/http/routes/book.routes');
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

// ============================================================
// Express application
// ============================================================
const app = express();

app.use(cors());
app.use(express.json());

// --- Routes ---
app.use('/api', healthRoutes(healthController));
app.use('/api/auth', authRoutes(authController));
app.use('/api/books', bookRoutes(bookController));

// --- Centralized error handler (must be registered last) ---
app.use(errorHandler);

module.exports = app;

