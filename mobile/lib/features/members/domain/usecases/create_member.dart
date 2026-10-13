import '../repositories/member_repository.dart';

/// Use case to create a new member.
class CreateMember {
  final MemberRepository _repository;

  const CreateMember(this._repository);

  Future<CreateMemberResult> call({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  }) {
    return _repository.createMember(
      fullName: fullName,
      admissionNumber: admissionNumber,
      phone: phone,
      email: email,
      status: status,
      createUser: createUser,
    );
  }
}
