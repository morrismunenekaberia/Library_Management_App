import '../entities/loan.dart';
import '../repositories/loan_repository.dart';

/// Use case to issue a new loan.
class IssueLoan {
  final LoanRepository _repository;

  const IssueLoan(this._repository);

  Future<Loan> call({
    required int bookId,
    required int memberId,
    String? dueDate,
  }) {
    return _repository.issueLoan(
      bookId: bookId,
      memberId: memberId,
      dueDate: dueDate,
    );
  }
}
