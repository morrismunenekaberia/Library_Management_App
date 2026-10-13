import '../entities/member.dart';
import '../repositories/member_repository.dart';

/// Use case to retrieve a list of members with optional search query.
class ListMembers {
  final MemberRepository _repository;

  const ListMembers(this._repository);

  Future<List<Member>> call({String? search}) {
    return _repository.listMembers(search: search);
  }
}
