import '../entities/loan.dart';

/// Repository interface for Loan domain operations.
abstract class LoanRepository {
  /// Fetches a list of loans, optionally filtered by status or member.
  Future<List<Loan>> listLoans({String? status, int? memberId});

  /// Issues a new loan for a book to a member.
  Future<Loan> issueLoan({
    required int bookId,
    required int memberId,
    String? dueDate,
  });

  /// Records the return of a loan by its identifier.
  Future<Loan> returnLoan(int id);
}
