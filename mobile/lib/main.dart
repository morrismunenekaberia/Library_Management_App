import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client/api_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/token_storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/books/data/datasources/books_remote_data_source.dart';
import 'features/books/data/repositories/book_repository_impl.dart';
import 'features/books/domain/entities/book.dart';
import 'features/books/domain/repositories/book_repository.dart';
import 'features/books/domain/usecases/create_book.dart';
import 'features/books/domain/usecases/delete_book.dart';
import 'features/books/domain/usecases/get_book.dart';
import 'features/books/domain/usecases/list_books.dart';
import 'features/books/domain/usecases/update_book.dart';
import 'features/books/presentation/controllers/books_controller.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/entities/dashboard_stats.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_librarian_dashboard.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/loans/data/datasources/loans_remote_data_source.dart';
import 'features/loans/data/repositories/loan_repository_impl.dart';
import 'features/loans/domain/entities/loan.dart';
import 'features/loans/domain/repositories/loan_repository.dart';
import 'features/loans/domain/usecases/issue_loan.dart';
import 'features/loans/domain/usecases/list_loans.dart';
import 'features/loans/domain/usecases/return_loan.dart';
import 'features/loans/presentation/controllers/loans_controller.dart';
import 'features/members/data/datasources/members_remote_data_source.dart';
import 'features/members/data/repositories/member_repository_impl.dart';
import 'features/members/domain/entities/member.dart';
import 'features/members/domain/repositories/member_repository.dart';
import 'features/members/domain/usecases/create_member.dart';
import 'features/members/domain/usecases/delete_member.dart';
import 'features/members/domain/usecases/get_member.dart';
import 'features/members/domain/usecases/list_members.dart';
import 'features/members/domain/usecases/update_member.dart';
import 'features/members/presentation/controllers/members_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core singletons
  const tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  // Auth feature dependency wiring
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    tokenStorage: tokenStorage,
  );
  final loginUser = LoginUser(authRepository);
  final logoutUser = LogoutUser(authRepository);
  final restoreSession = RestoreSession(authRepository);

  final authController = AuthController(
    loginUserUseCase: loginUser,
    logoutUserUseCase: logoutUser,
    restoreSessionUseCase: restoreSession,
  );

  // Automatically log user out when API returns 401 Unauthorized
  apiClient.onUnauthorized = () {
    authController.handleSessionExpired();
  };

  // Books feature dependency wiring
  final booksRemoteDataSource = BooksRemoteDataSourceImpl(apiClient);
  final bookRepository = BookRepositoryImpl(booksRemoteDataSource);
  final listBooks = ListBooks(bookRepository);
  final getBook = GetBook(bookRepository);
  final createBook = CreateBook(bookRepository);
  final updateBook = UpdateBook(bookRepository);
  final deleteBook = DeleteBook(bookRepository);

  final booksController = BooksController(
    listBooksUseCase: listBooks,
    getBookUseCase: getBook,
    createBookUseCase: createBook,
    updateBookUseCase: updateBook,
    deleteBookUseCase: deleteBook,
  );

  // Members feature dependency wiring
  final membersRemoteDataSource = MembersRemoteDataSourceImpl(apiClient);
  final memberRepository = MemberRepositoryImpl(membersRemoteDataSource);
  final listMembers = ListMembers(memberRepository);
  final getMember = GetMember(memberRepository);
  final createMember = CreateMember(memberRepository);
  final updateMember = UpdateMember(memberRepository);
  final deleteMember = DeleteMember(memberRepository);

  final membersController = MembersController(
    listMembersUseCase: listMembers,
    getMemberUseCase: getMember,
    createMemberUseCase: createMember,
    updateMemberUseCase: updateMember,
    deleteMemberUseCase: deleteMember,
  );

  // Loans feature dependency wiring
  final loansRemoteDataSource = LoansRemoteDataSourceImpl(apiClient);
  final loanRepository = LoanRepositoryImpl(loansRemoteDataSource);
  final listLoans = ListLoans(loanRepository);
  final issueLoan = IssueLoan(loanRepository);
  final returnLoan = ReturnLoan(loanRepository);

  final loansController = LoansController(
    listLoansUseCase: listLoans,
    issueLoanUseCase: issueLoan,
    returnLoanUseCase: returnLoan,
  );

  // Dashboard feature dependency wiring
  final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl(apiClient);
  final dashboardRepository = DashboardRepositoryImpl(dashboardRemoteDataSource);
  final getLibrarianDashboard = GetLibrarianDashboard(dashboardRepository);
  final dashboardController = DashboardController(
    getLibrarianDashboardUseCase: getLibrarianDashboard,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<BookRepository>.value(value: bookRepository),
        Provider<MemberRepository>.value(value: memberRepository),
        Provider<LoanRepository>.value(value: loanRepository),
        Provider<DashboardRepository>.value(value: dashboardRepository),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<BooksController>.value(value: booksController),
        ChangeNotifierProvider<MembersController>.value(value: membersController),
        ChangeNotifierProvider<LoansController>.value(value: loansController),
        ChangeNotifierProvider<DashboardController>.value(value: dashboardController),
      ],
      child: LibraryApp(
        authController: authController,
        booksController: booksController,
        membersController: membersController,
        loansController: loansController,
        dashboardController: dashboardController,
      ),
    ),
  );
}

class LibraryApp extends StatefulWidget {
  final AuthController authController;
  final BooksController? booksController;
  final MembersController? membersController;
  final LoansController? loansController;
  final DashboardController? dashboardController;

  const LibraryApp({
    super.key,
    required this.authController,
    this.booksController,
    this.membersController,
    this.loansController,
    this.dashboardController,
  });

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final _router = AppRouter.createRouter(widget.authController);
  late final BooksController _effectiveBooksController;
  late final MembersController _effectiveMembersController;
  late final LoansController _effectiveLoansController;
  late final DashboardController _effectiveDashboardController;

  @override
  void initState() {
    super.initState();
    _effectiveBooksController = widget.booksController ??
        BooksController(
          listBooksUseCase: const ListBooks(_NoopBookRepository()),
          getBookUseCase: const GetBook(_NoopBookRepository()),
          createBookUseCase: const CreateBook(_NoopBookRepository()),
          updateBookUseCase: const UpdateBook(_NoopBookRepository()),
          deleteBookUseCase: const DeleteBook(_NoopBookRepository()),
        );

    _effectiveMembersController = widget.membersController ??
        MembersController(
          listMembersUseCase: const ListMembers(_NoopMemberRepository()),
          getMemberUseCase: const GetMember(_NoopMemberRepository()),
          createMemberUseCase: const CreateMember(_NoopMemberRepository()),
          updateMemberUseCase: const UpdateMember(_NoopMemberRepository()),
          deleteMemberUseCase: const DeleteMember(_NoopMemberRepository()),
        );

    _effectiveLoansController = widget.loansController ??
        LoansController(
          listLoansUseCase: const ListLoans(_NoopLoanRepository()),
          issueLoanUseCase: const IssueLoan(_NoopLoanRepository()),
          returnLoanUseCase: const ReturnLoan(_NoopLoanRepository()),
        );

    _effectiveDashboardController = widget.dashboardController ??
        DashboardController(
          getLibrarianDashboardUseCase: const GetLibrarianDashboard(_NoopDashboardRepository()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(
          value: widget.authController,
        ),
        ChangeNotifierProvider<BooksController>.value(
          value: _effectiveBooksController,
        ),
        ChangeNotifierProvider<MembersController>.value(
          value: _effectiveMembersController,
        ),
        ChangeNotifierProvider<LoansController>.value(
          value: _effectiveLoansController,
        ),
        ChangeNotifierProvider<DashboardController>.value(
          value: _effectiveDashboardController,
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

/// Fallback repository used only if [LibraryApp] is constructed without [DashboardController] in tests.
class _NoopDashboardRepository implements DashboardRepository {
  const _NoopDashboardRepository();

  @override
  Future<DashboardStats> getLibrarianDashboard() async => const DashboardStats(
        totalBooks: 0,
        activeLoans: 0,
        overdueLoans: 0,
        totalMembers: 0,
        overdueLoansList: [],
      );
}

/// Fallback repository used only if [LibraryApp] is constructed without [BooksController] in tests.
class _NoopBookRepository implements BookRepository {
  const _NoopBookRepository();

  @override
  Future<List<Book>> listBooks({String? search}) async => const [];

  @override
  Future<Book> getBook(int id) async => Book(
        id: id,
        isbn: '000',
        title: 'Untitled',
        author: 'Unknown',
        totalCopies: 1,
        availableCopies: 1,
      );

  @override
  Future<Book> createBook({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  }) async =>
      Book(
        id: 1,
        isbn: isbn,
        title: title,
        author: author,
        category: category,
        totalCopies: totalCopies,
        availableCopies: availableCopies ?? totalCopies,
      );

  @override
  Future<Book> updateBook(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  }) async =>
      Book(
        id: id,
        isbn: isbn ?? '000',
        title: title ?? 'Untitled',
        author: author ?? 'Unknown',
        category: category,
        totalCopies: totalCopies ?? 1,
        availableCopies: totalCopies ?? 1,
      );

  @override
  Future<void> deleteBook(int id) async {}
}

/// Fallback repository used only if [LibraryApp] is constructed without [MembersController] in tests.
class _NoopMemberRepository implements MemberRepository {
  const _NoopMemberRepository();

  @override
  Future<List<Member>> listMembers({String? search}) async => const [];

  @override
  Future<Member> getMember(int id) async => Member(
        id: id,
        fullName: 'Unknown',
        admissionNumber: '000',
        joinedAt: DateTime(2026, 1, 1),
        status: 'active',
      );

  @override
  Future<CreateMemberResult> createMember({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  }) async =>
      CreateMemberResult(
        member: Member(
          id: 1,
          fullName: fullName,
          admissionNumber: admissionNumber,
          phone: phone,
          email: email,
          joinedAt: DateTime.now(),
          status: status ?? 'active',
        ),
        temporaryPassword: createUser ? 'Tmp#12345678' : null,
      );

  @override
  Future<Member> updateMember(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  }) async =>
      Member(
        id: id,
        fullName: fullName ?? 'Unknown',
        admissionNumber: admissionNumber ?? '000',
        phone: phone,
        email: email,
        joinedAt: DateTime(2026, 1, 1),
        status: status ?? 'active',
      );

  @override
  Future<void> deleteMember(int id) async {}
}

/// Fallback repository used only if [LibraryApp] is constructed without [LoansController] in tests.
class _NoopLoanRepository implements LoanRepository {
  const _NoopLoanRepository();

  @override
  Future<List<Loan>> listLoans({String? status, int? memberId}) async => const [];

  @override
  Future<Loan> issueLoan({
    required int bookId,
    required int memberId,
    String? dueDate,
  }) async =>
      Loan(
        id: 1,
        bookId: bookId,
        memberId: memberId,
        issuedAt: DateTime.now(),
        dueDate: dueDate != null ? DateTime.parse(dueDate) : DateTime.now().add(const Duration(days: 14)),
      );

  @override
  Future<Loan> returnLoan(int id) async => Loan(
        id: id,
        bookId: 1,
        memberId: 1,
        issuedAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 9)),
        returnedAt: DateTime.now(),
      );
}


