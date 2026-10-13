import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/members_remote_data_source.dart';

/// Implementation of [MemberRepository] coordinating with [MembersRemoteDataSource].
class MemberRepositoryImpl implements MemberRepository {
  final MembersRemoteDataSource _remoteDataSource;

  const MemberRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Member>> listMembers({String? search}) async {
    return _remoteDataSource.listMembers(search: search);
  }

  @override
  Future<Member> getMember(int id) async {
    return _remoteDataSource.getMember(id);
  }

  @override
  Future<CreateMemberResult> createMember({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'admissionNumber': admissionNumber,
      'createUser': createUser,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      body['status'] = status.trim();
    }

    final result = await _remoteDataSource.createMember(body);
    return CreateMemberResult(
      member: result.member,
      temporaryPassword: result.temporaryPassword,
    );
  }

  @override
  Future<Member> updateMember(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['fullName'] = fullName.trim();
    }
    if (admissionNumber != null && admissionNumber.trim().isNotEmpty) {
      body['admissionNumber'] = admissionNumber.trim();
    }
    if (phone != null) {
      body['phone'] = phone.trim().isEmpty ? null : phone.trim();
    }
    if (email != null) {
      body['email'] = email.trim().isEmpty ? null : email.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      body['status'] = status.trim();
    }

    return _remoteDataSource.updateMember(id, body);
  }

  @override
  Future<void> deleteMember(int id) async {
    return _remoteDataSource.deleteMember(id);
  }
}
