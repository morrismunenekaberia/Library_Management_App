/// Member domain entity.
class Member {
  final int id;
  final String fullName;
  final String admissionNumber;
  final String? phone;
  final String? email;
  final DateTime joinedAt;
  final String status;

  const Member({
    required this.id,
    required this.fullName,
    required this.admissionNumber,
    this.phone,
    this.email,
    required this.joinedAt,
    required this.status,
  });

  Member copyWith({
    int? id,
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    DateTime? joinedAt,
    String? status,
  }) {
    return Member(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          admissionNumber == other.admissionNumber &&
          phone == other.phone &&
          email == other.email &&
          joinedAt == other.joinedAt &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      admissionNumber.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      joinedAt.hashCode ^
      status.hashCode;
}
