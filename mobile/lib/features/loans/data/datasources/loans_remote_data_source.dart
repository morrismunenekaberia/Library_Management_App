import '../../../../core/api_client/api_client.dart';
import '../models/loan_model.dart';

/// Remote data source contract for Loans.
abstract class LoansRemoteDataSource {
  Future<List<LoanModel>> listLoans({String? status, int? memberId});
  Future<LoanModel> issueLoan(Map<String, dynamic> body);
  Future<LoanModel> returnLoan(int id);
}

/// Implementation of [LoansRemoteDataSource] communicating with the backend REST API.
class LoansRemoteDataSourceImpl implements LoansRemoteDataSource {
  final ApiClient _apiClient;

  const LoansRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<LoanModel>> listLoans({String? status, int? memberId}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (memberId != null) {
      queryParams['memberId'] = memberId.toString();
    }

    final response = await _apiClient.get(
      '/loans',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => LoanModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<LoanModel> issueLoan(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/loans', body: body);
    return LoanModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<LoanModel> returnLoan(int id) async {
    final response = await _apiClient.post('/loans/$id/return');
    return LoanModel.fromJson(response as Map<String, dynamic>);
  }
}
