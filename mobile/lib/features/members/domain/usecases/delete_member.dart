import '../repositories/member_repository.dart';

/// Use case to delete a member by ID.
class DeleteMember {
  final MemberRepository _repository;

  const DeleteMember(this._repository);

  Future<void> call(int id) {
    return _repository.deleteMember(id);
  }
}
