import '../entities/loan.dart';
import '../repositories/loan_repository.dart';

/// Use case to return a loan.
class ReturnLoan {
  final LoanRepository _repository;

  const ReturnLoan(this._repository);

  Future<Loan> call(int id) {
    return _repository.returnLoan(id);
  }
}
