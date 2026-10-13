import '../entities/member.dart';
import '../repositories/member_repository.dart';

/// Use case to update an existing member.
class UpdateMember {
  final MemberRepository _repository;

  const UpdateMember(this._repository);

  Future<Member> call(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  }) {
    return _repository.updateMember(
      id,
      fullName: fullName,
      admissionNumber: admissionNumber,
      phone: phone,
      email: email,
      status: status,
    );
  }
}
