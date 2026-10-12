import '../../domain/entities/user.dart';

/// Data model representing a user with JSON serialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.role,
    super.memberId,
  });

  /// Factory constructor to parse JSON received from the API or local storage.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: (json['username'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      memberId: json['memberId'] ?? json['member_id'],
    );
  }

  /// Converts the user instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role, 'memberId': memberId};
  }

  /// Creates a [UserModel] from a domain [User] instance.
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      role: user.role,
      memberId: user.memberId,
    );
  }
}
