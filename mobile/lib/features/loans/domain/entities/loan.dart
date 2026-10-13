/// Loan domain entity.
class Loan {
  final int id;
  final int bookId;
  final int memberId;
  final DateTime issuedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String? bookTitle;
  final String? memberName;

  const Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.issuedAt,
    required this.dueDate,
    this.returnedAt,
    this.bookTitle,
    this.memberName,
  });

  /// Returns true if the loan is past due and has not been returned.
  bool get isOverdue => returnedAt == null && dueDate.isBefore(DateTime.now());

  /// Returns true if the loan is still active (not returned, not overdue).
  bool get isActive => returnedAt == null && !dueDate.isBefore(DateTime.now());

  /// Returns true if the book has been returned.
  bool get isReturned => returnedAt != null;

  /// Number of days the loan is overdue, clamped to at least 1 when overdue.
  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays.clamp(1, 9999) : 0;

  Loan copyWith({
    int? id,
    int? bookId,
    int? memberId,
    DateTime? issuedAt,
    DateTime? dueDate,
    DateTime? returnedAt,
    String? bookTitle,
    String? memberName,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      memberId: memberId ?? this.memberId,
      issuedAt: issuedAt ?? this.issuedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      bookTitle: bookTitle ?? this.bookTitle,
      memberName: memberName ?? this.memberName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Loan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bookId == other.bookId &&
          memberId == other.memberId &&
          issuedAt == other.issuedAt &&
          dueDate == other.dueDate &&
          returnedAt == other.returnedAt &&
          bookTitle == other.bookTitle &&
          memberName == other.memberName;

  @override
  int get hashCode =>
      id.hashCode ^
      bookId.hashCode ^
      memberId.hashCode ^
      issuedAt.hashCode ^
      dueDate.hashCode ^
      returnedAt.hashCode ^
      bookTitle.hashCode ^
      memberName.hashCode;
}
