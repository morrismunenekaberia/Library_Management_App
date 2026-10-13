import '../entities/member.dart';

/// Result of creating a member, which may include a temporary password.
class CreateMemberResult {
  final Member member;
  final String? temporaryPassword;

  const CreateMemberResult({required this.member, this.temporaryPassword});
}

/// Repository interface for Member domain operations.
abstract class MemberRepository {
  /// Fetches a list of members, optionally filtered by a search query.
  Future<List<Member>> listMembers({String? search});

  /// Fetches a single member by their identifier.
  Future<Member> getMember(int id);

  /// Creates a new member entry.
  Future<CreateMemberResult> createMember({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  });

  /// Updates an existing member.
  Future<Member> updateMember(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  });

  /// Deletes a member by their identifier.
  Future<void> deleteMember(int id);
}
