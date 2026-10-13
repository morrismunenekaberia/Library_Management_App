import '../../../../core/api_client/api_client.dart';
import '../models/member_model.dart';

/// Result of a create-member operation, which may include a temporary password.
class CreateMemberDataResult {
  final MemberModel member;
  final String? temporaryPassword;

  const CreateMemberDataResult({required this.member, this.temporaryPassword});
}

/// Remote data source contract for Members.
abstract class MembersRemoteDataSource {
  Future<List<MemberModel>> listMembers({String? search});
  Future<MemberModel> getMember(int id);
  Future<CreateMemberDataResult> createMember(Map<String, dynamic> body);
  Future<MemberModel> updateMember(int id, Map<String, dynamic> body);
  Future<void> deleteMember(int id);
}

/// Implementation of [MembersRemoteDataSource] communicating with the backend REST API.
class MembersRemoteDataSourceImpl implements MembersRemoteDataSource {
  final ApiClient _apiClient;

  const MembersRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<MemberModel>> listMembers({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      '/members',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => MemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<MemberModel> getMember(int id) async {
    final response = await _apiClient.get('/members/$id');
    return MemberModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CreateMemberDataResult> createMember(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/members', body: body);
    final json = response as Map<String, dynamic>;
    return CreateMemberDataResult(
      member: MemberModel.fromJson(json),
      temporaryPassword: json['temporaryPassword'] as String?,
    );
  }

  @override
  Future<MemberModel> updateMember(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/members/$id', body: body);
    return MemberModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMember(int id) async {
    await _apiClient.delete('/members/$id');
  }
}
