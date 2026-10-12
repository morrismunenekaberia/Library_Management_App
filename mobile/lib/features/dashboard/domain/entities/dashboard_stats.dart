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

/// Aggregated metrics and overdue loans for the librarian dashboard.
class DashboardStats {
  final int totalBooks;
  final int activeLoans;
  final int overdueLoans;
  final int totalMembers;
  final List<OverdueLoanItem> overdueLoansList;

  const DashboardStats({
    required this.totalBooks,
    required this.activeLoans,
    required this.overdueLoans,
    required this.totalMembers,
    required this.overdueLoansList,
  });
}
