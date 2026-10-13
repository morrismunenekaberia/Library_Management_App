import '../../domain/entities/loan.dart';

/// Data model representing a loan with JSON serialization.
class LoanModel extends Loan {
  const LoanModel({
    required super.id,
    required super.bookId,
    required super.memberId,
    required super.issuedAt,
    required super.dueDate,
    super.returnedAt,
    super.bookTitle,
    super.memberName,
  });

  /// Creates a [LoanModel] instance from a JSON map.
  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: (json['id'] as num).toInt(),
      bookId: ((json['bookId'] ?? json['book_id']) as num).toInt(),
      memberId: ((json['memberId'] ?? json['member_id']) as num).toInt(),
      issuedAt: (json['issuedAt'] ?? json['issued_at']) != null
          ? DateTime.parse(
              (json['issuedAt'] ?? json['issued_at']) as String,
            )
          : DateTime.now(),
      dueDate: DateTime.parse(
        (json['dueDate'] ?? json['due_date']) as String,
      ),
      returnedAt: (json['returnedAt'] ?? json['returned_at']) != null
          ? DateTime.parse(
              (json['returnedAt'] ?? json['returned_at']) as String,
            )
          : null,
      bookTitle: (json['bookTitle'] ?? json['book_title']) as String?,
      memberName: (json['memberName'] ?? json['member_name']) as String?,
    );
  }

  /// Converts this [LoanModel] instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'memberId': memberId,
      'issuedAt': issuedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'bookTitle': bookTitle,
      'memberName': memberName,
    };
  }

  /// Factory to convert a domain [Loan] into a [LoanModel].
  factory LoanModel.fromEntity(Loan loan) {
    return LoanModel(
      id: loan.id,
      bookId: loan.bookId,
      memberId: loan.memberId,
      issuedAt: loan.issuedAt,
      dueDate: loan.dueDate,
      returnedAt: loan.returnedAt,
      bookTitle: loan.bookTitle,
      memberName: loan.memberName,
    );
  }
}
