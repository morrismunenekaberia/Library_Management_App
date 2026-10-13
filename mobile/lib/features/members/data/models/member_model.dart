import '../../domain/entities/member.dart';

/// Data model representing a member with JSON serialization.
class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.fullName,
    required super.admissionNumber,
    super.phone,
    super.email,
    required super.joinedAt,
    required super.status,
  });

  /// Creates a [MemberModel] instance from a JSON map.
  /// Handles both camelCase and snake_case backend keys gracefully.
  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: (json['id'] as num).toInt(),
      fullName: (json['fullName'] ?? json['full_name']) as String,
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number']) as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      joinedAt: DateTime.parse(
          (json['joinedAt'] ?? json['joined_at']) as String),
      status: json['status'] as String,
    );
  }

  /// Converts this [MemberModel] instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'admissionNumber': admissionNumber,
      'phone': phone,
      'email': email,
      'joinedAt': joinedAt.toIso8601String(),
      'status': status,
    };
  }

  /// Factory to convert a domain [Member] into a [MemberModel].
  factory MemberModel.fromEntity(Member member) {
    return MemberModel(
      id: member.id,
      fullName: member.fullName,
      admissionNumber: member.admissionNumber,
      phone: member.phone,
      email: member.email,
      joinedAt: member.joinedAt,
      status: member.status,
    );
  }
}
