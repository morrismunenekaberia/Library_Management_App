import '../entities/loan.dart';
import '../repositories/loan_repository.dart';

/// Use case to retrieve a list of loans with optional filters.
class ListLoans {
  final LoanRepository _repository;

  const ListLoans(this._repository);

  Future<List<Loan>> call({String? status, int? memberId}) {
    return _repository.listLoans(status: status, memberId: memberId);
  }
}
