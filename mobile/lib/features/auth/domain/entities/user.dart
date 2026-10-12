/// User domain entity representing an authenticated account.
class User {
  final int id;
  final String username;
  final String role;
  final int? memberId;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.memberId,
  });

  /// Convenience helper to check if user has librarian privileges.
  bool get isLibrarian => role.toLowerCase() == 'librarian';

  /// Convenience helper to check if user is a standard member.
  bool get isMember => role.toLowerCase() == 'member';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          role == other.role &&
          memberId == other.memberId;

  @override
  int get hashCode => Object.hash(id, username, role, memberId);
}
