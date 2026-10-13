import '../entities/member.dart';
import '../repositories/member_repository.dart';

/// Use case to retrieve a single member by ID.
class GetMember {
  final MemberRepository _repository;

  const GetMember(this._repository);

  Future<Member> call(int id) {
    return _repository.getMember(id);
  }
}
