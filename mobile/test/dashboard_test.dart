import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/core/api_client/api_client.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:library_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:library_mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:library_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:library_mobile/features/dashboard/domain/usecases/get_librarian_dashboard.dart';
import 'package:library_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:library_mobile/main.dart';

import 'widget_test.dart';

class MockDashboardApiClient extends ApiClient {
  final List<dynamic> booksResponse;
  final List<dynamic> loansResponse;
  final List<dynamic> membersResponse;

  MockDashboardApiClient({
    required this.booksResponse,
    required this.loansResponse,
    required this.membersResponse,
  });

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, Map<String, String>? headers}) async {
    if (path == '/books') return booksResponse;
    if (path == '/loans') return loansResponse;
    if (path == '/members') return membersResponse;
    throw Exception('Unexpected endpoint: $path');
  }
}

class FakeDashboardRepository implements DashboardRepository {
  DashboardStats stats;

  FakeDashboardRepository(this.stats);

  @override
  Future<DashboardStats> getLibrarianDashboard() async => stats;
}

void main() {
  group('DashboardRemoteDataSourceImpl Unit Tests', () {
    test('Correctly computes metrics and categorizes active vs overdue loans', () async {
      final now = DateTime.now();
      final mockClient = MockDashboardApiClient(
        booksResponse: [
          {'id': 1, 'title': 'Book 1'},
          {'id': 2, 'title': 'Book 2'},
          {'id': 3, 'title': 'Book 3'},
        ],
        loansResponse: [
          // Active loan (due tomorrow)
          {
            'id': 1,
            'bookId': 1,
            'memberId': 10,
            'dueDate': now.add(const Duration(days: 1)).toIso8601String(),
            'returnedAt': null,
            'bookTitle': 'Active Book',
            'memberName': 'Alice',
          },
          // Overdue loan (due 3 days ago)
          {
            'id': 2,
            'bookId': 2,
            'memberId': 11,
            'dueDate': now.subtract(const Duration(days: 3)).toIso8601String(),
            'returnedAt': null,
            'bookTitle': 'Overdue Book',
            'memberName': 'Bob',
          },
          // Returned loan (should not count as active or overdue)
          {
            'id': 3,
            'bookId': 3,
            'memberId': 12,
            'dueDate': now.subtract(const Duration(days: 5)).toIso8601String(),
            'returnedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
            'bookTitle': 'Returned Book',
            'memberName': 'Charlie',
          },
        ],
        membersResponse: [
          {'id': 10, 'fullName': 'Alice'},
          {'id': 11, 'fullName': 'Bob'},
        ],
      );

      final dataSource = DashboardRemoteDataSourceImpl(mockClient);
      final stats = await dataSource.getDashboardStats();

      expect(stats.totalBooks, 3);
      expect(stats.totalMembers, 2);
      expect(stats.activeLoans, 1);
      expect(stats.overdueLoans, 1);
      expect(stats.overdueLoansList.length, 1);
      expect(stats.overdueLoansList.first.bookTitle, 'Overdue Book');
      expect(stats.overdueLoansList.first.memberName, 'Bob');
      expect(stats.overdueLoansList.first.daysOverdue, greaterThanOrEqualTo(3));
    });
  });

  group('Librarian Dashboard Widget Tests', () {
    testWidgets('Displays all 4 metric cards and overdue loans in red', (tester) async {
      final fakeAuth = FakeAuthRepository();
      fakeAuth.currentUser = const User(
        id: 1,
        username: 'admin',
        role: 'librarian',
      );

      final authController = AuthController(
        loginUserUseCase: LoginUser(fakeAuth),
        logoutUserUseCase: LogoutUser(fakeAuth),
        restoreSessionUseCase: RestoreSession(fakeAuth),
      );
      await authController.restoreSession();

      final overdueItem = OverdueLoanItem(
        id: 1,
        bookId: 101,
        memberId: 201,
        bookTitle: 'Introduction to Algorithms',
        memberName: 'John Doe',
        dueDate: DateTime.now().subtract(const Duration(days: 4)),
        daysOverdue: 4,
      );

      final fakeStats = DashboardStats(
        totalBooks: 42,
        activeLoans: 7,
        overdueLoans: 1,
        totalMembers: 15,
        overdueLoansList: [overdueItem],
      );

      final fakeDashboardRepo = FakeDashboardRepository(fakeStats);
      final dashboardController = DashboardController(
        getLibrarianDashboardUseCase: GetLibrarianDashboard(fakeDashboardRepo),
      );

      await tester.pumpWidget(
        LibraryApp(
          authController: authController,
          dashboardController: dashboardController,
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and titles
      expect(find.text('Library Manager'), findsWidgets);
      expect(find.text('Library Overview'), findsOneWidget);

      // Verify metric card counts
      expect(find.text('Total Books'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Active Loans'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Overdue Loans'), findsWidgets);
      expect(find.text('Members'), findsWidgets);
      expect(find.text('15'), findsOneWidget);

      // Verify overdue loan details
      expect(find.text('Introduction to Algorithms'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('4 days overdue'), findsOneWidget);
    });

    testWidgets('Displays empty state when there are no overdue loans', (tester) async {
      final fakeAuth = FakeAuthRepository();
      fakeAuth.currentUser = const User(
        id: 1,
        username: 'admin',
        role: 'librarian',
      );

      final authController = AuthController(
        loginUserUseCase: LoginUser(fakeAuth),
        logoutUserUseCase: LogoutUser(fakeAuth),
        restoreSessionUseCase: RestoreSession(fakeAuth),
      );
      await authController.restoreSession();

      final fakeStats = const DashboardStats(
        totalBooks: 10,
        activeLoans: 2,
        overdueLoans: 0,
        totalMembers: 5,
        overdueLoansList: [],
      );

      final fakeDashboardRepo = FakeDashboardRepository(fakeStats);
      final dashboardController = DashboardController(
        getLibrarianDashboardUseCase: GetLibrarianDashboard(fakeDashboardRepo),
      );

      await tester.pumpWidget(
        LibraryApp(
          authController: authController,
          dashboardController: dashboardController,
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No Overdue Loans'), findsOneWidget);
      expect(find.text('All borrowed books are up to date.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });
  });
}

