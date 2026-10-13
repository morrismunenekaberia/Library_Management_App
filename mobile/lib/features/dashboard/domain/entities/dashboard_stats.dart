import '../../../loans/domain/entities/loan.dart';

/// Represents an overdue loan item displayed on the librarian dashboard.
class OverdueLoanItem {
  final int id;
  final int bookId;
  final int memberId;
  final String bookTitle;
  final String memberName;
  final DateTime dueDate;
  final int daysOverdue;

  const OverdueLoanItem({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.bookTitle,
    required this.memberName,
    required this.dueDate,
    required this.daysOverdue,
  });
}

/// Aggregated metrics, recent loans, and overdue loans for the librarian dashboard.
class DashboardStats {
  final int totalBooks;
  final int activeLoans;
  final int overdueLoans;
  final int activeMembers;
  final List<OverdueLoanItem> overdueLoansList;
  final List<Loan> recentLoans;

  const DashboardStats({
    required this.totalBooks,
    required this.activeLoans,
    required this.overdueLoans,
    int? activeMembers,
    int? totalMembers,
    this.overdueLoansList = const [],
    this.recentLoans = const [],
  }) : activeMembers = activeMembers ?? totalMembers ?? 0;

  /// Alias for backward compatibility with widgets and existing tests expecting totalMembers
  int get totalMembers => activeMembers;
}
