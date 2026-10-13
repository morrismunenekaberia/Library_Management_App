import '../../domain/entities/loan.dart';
import '../../domain/repositories/loan_repository.dart';
import '../datasources/loans_remote_data_source.dart';

/// Implementation of [LoanRepository] coordinating with [LoansRemoteDataSource].
class LoanRepositoryImpl implements LoanRepository {
  final LoansRemoteDataSource _remoteDataSource;

  const LoanRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Loan>> listLoans({String? status, int? memberId}) async {
    return _remoteDataSource.listLoans(status: status, memberId: memberId);
  }

  @override
  Future<Loan> issueLoan({
    required int bookId,
    required int memberId,
    String? dueDate,
  }) async {
    final body = <String, dynamic>{
      'bookId': bookId,
      'memberId': memberId,
    };

    if (dueDate != null && dueDate.trim().isNotEmpty) {
      body['dueDate'] = dueDate.trim();
    }

    return _remoteDataSource.issueLoan(body);
  }

  @override
  Future<Loan> returnLoan(int id) async {
    return _remoteDataSource.returnLoan(id);
  }
}
