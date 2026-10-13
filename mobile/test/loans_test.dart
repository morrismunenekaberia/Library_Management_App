import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/core/errors/app_exceptions.dart';
import 'package:library_mobile/features/loans/domain/entities/loan.dart';
import 'package:library_mobile/features/loans/domain/repositories/loan_repository.dart';
import 'package:library_mobile/features/loans/domain/usecases/issue_loan.dart';
import 'package:library_mobile/features/loans/domain/usecases/list_loans.dart';
import 'package:library_mobile/features/loans/domain/usecases/return_loan.dart';
import 'package:library_mobile/features/loans/presentation/controllers/loans_controller.dart';

class FakeLoanRepository implements LoanRepository {
  final List<Loan> loans = [
    Loan(
      id: 1,
      bookId: 101,
      memberId: 201,
      bookTitle: 'Clean Code',
      memberName: 'John Doe',
      issuedAt: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 9)),
      returnedAt: null,
    ),
    Loan(
      id: 2,
      bookId: 102,
      memberId: 202,
      bookTitle: 'Design Patterns',
      memberName: 'Jane Smith',
      issuedAt: DateTime.now().subtract(const Duration(days: 20)),
      dueDate: DateTime.now().subtract(const Duration(days: 6)),
      returnedAt: null,
    ),
    Loan(
      id: 3,
      bookId: 103,
      memberId: 203,
      bookTitle: 'Refactoring',
      memberName: 'Bob Wilson',
      issuedAt: DateTime.now().subtract(const Duration(days: 30)),
      dueDate: DateTime.now().subtract(const Duration(days: 16)),
      returnedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  bool shouldThrow = false;
  Exception? customException;

  @override
  Future<List<Loan>> listLoans({String? status, int? memberId}) async {
    if (shouldThrow) {
      throw customException ?? Exception('Failed to load loans');
    }
    var result = List.of(loans);
    if (status == 'active') {
      result = result.where((l) => l.isActive).toList();
    } else if (status == 'overdue') {
      result = result.where((l) => l.isOverdue).toList();
    } else if (status == 'returned') {
      result = result.where((l) => l.isReturned).toList();
    }
    if (memberId != null) {
      result = result.where((l) => l.memberId == memberId).toList();
    }
    return result;
  }

  @override
  Future<Loan> issueLoan({
    required int bookId,
    required int memberId,
    String? dueDate,
  }) async {
    if (shouldThrow) {
      throw customException ?? const ConflictException('No available copies');
    }
    final created = Loan(
      id: loans.length + 1,
      bookId: bookId,
      memberId: memberId,
      issuedAt: DateTime.now(),
      dueDate: dueDate != null ? DateTime.parse(dueDate) : DateTime.now().add(const Duration(days: 14)),
    );
    loans.insert(0, created);
    return created;
  }

  @override
  Future<Loan> returnLoan(int id) async {
    if (shouldThrow) {
      throw customException ??
          const ConflictException('Loan has already been returned');
    }
    final index = loans.indexWhere((l) => l.id == id);
    if (index == -1) throw const NotFoundException('Loan not found');
    final updated = loans[index].copyWith(returnedAt: DateTime.now());
    loans[index] = updated;
    return updated;
  }
}

void main() {
  late FakeLoanRepository repository;
  late LoansController controller;

  setUp(() {
    repository = FakeLoanRepository();
    controller = LoansController(
      listLoansUseCase: ListLoans(repository),
      issueLoanUseCase: IssueLoan(repository),
      returnLoanUseCase: ReturnLoan(repository),
    );
  });

  group('Loans Feature Tests', () {
    test('fetchLoans loads all loans or filtered by status', () async {
      await controller.fetchLoans();
      expect(controller.loans.length, 3);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);

      // Filter by active
      await controller.setStatusFilter('active');
      expect(controller.loans.length, 1);
      expect(controller.loans.first.id, 1);

      // Filter by overdue
      await controller.setStatusFilter('overdue');
      expect(controller.loans.length, 1);
      expect(controller.loans.first.id, 2);
      expect(controller.loans.first.isOverdue, isTrue);

      // Filter by returned
      await controller.setStatusFilter('returned');
      expect(controller.loans.length, 1);
      expect(controller.loans.first.id, 3);
      expect(controller.loans.first.isReturned, isTrue);
    });

    test('returnLoan successfully calls use case and updates state', () async {
      await controller.fetchLoans();
      expect(controller.loans.length, 3);

      final success = await controller.returnLoan(1);
      expect(success, isTrue);
      expect(controller.loans.any((l) => l.id == 1), isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('returnLoan captures 409 already returned error in plain English', () async {
      repository.shouldThrow = true;
      repository.customException =
          const ConflictException('Loan has already been returned');

      final success = await controller.returnLoan(3);
      expect(success, isFalse);
      expect(controller.errorMessage, 'Loan has already been returned');
    });

    test('Loan entity overdue calculations are accurate', () {
      final activeLoan = repository.loans[0];
      expect(activeLoan.isActive, isTrue);
      expect(activeLoan.isOverdue, isFalse);
      expect(activeLoan.daysOverdue, 0);

      final overdueLoan = repository.loans[1];
      expect(overdueLoan.isActive, isFalse);
      expect(overdueLoan.isOverdue, isTrue);
      expect(overdueLoan.daysOverdue, greaterThanOrEqualTo(5));

      final returnedLoan = repository.loans[2];
      expect(returnedLoan.isReturned, isTrue);
      expect(returnedLoan.isActive, isFalse);
      expect(returnedLoan.isOverdue, isFalse);
    });
  });
}

