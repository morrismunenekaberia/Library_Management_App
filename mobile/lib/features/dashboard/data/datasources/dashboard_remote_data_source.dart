import '../../../../core/api_client/api_client.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Remote data source interface for dashboard metrics and overdue loans.
abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getDashboardStats();
}

/// Concrete implementation of [DashboardRemoteDataSource] fetching from the backend API.
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<DashboardStats> getDashboardStats() async {
    final results = await Future.wait([
      _apiClient.get('/books'),
      _apiClient.get('/loans'),
      _apiClient.get('/members'),
    ]);

    final booksList = results[0] as List<dynamic>;
    final loansList = results[1] as List<dynamic>;
    final membersList = results[2] as List<dynamic>;

    final totalBooks = booksList.length;
    final totalMembers = membersList.length;

    int activeLoans = 0;
    int overdueLoans = 0;
    final overdueItems = <OverdueLoanItem>[];
    final now = DateTime.now();

    for (final loanRaw in loansList) {
      if (loanRaw is! Map<String, dynamic>) continue;
      final returnedAt = loanRaw['returnedAt'];
      if (returnedAt != null) {
        continue; // Already returned
      }

      final dueDateStr = loanRaw['dueDate'] as String?;
      if (dueDateStr == null) continue;
      final dueDate = DateTime.parse(dueDateStr);

      if (dueDate.isBefore(now)) {
        overdueLoans++;
        final diff = now.difference(dueDate);
        final days = diff.inDays > 0 ? diff.inDays : 1;
        overdueItems.add(
          OverdueLoanItem(
            id: (loanRaw['id'] as num).toInt(),
            bookId: (loanRaw['bookId'] as num).toInt(),
            memberId: (loanRaw['memberId'] as num).toInt(),
            bookTitle: loanRaw['bookTitle'] as String? ?? 'Untitled Book',
            memberName: loanRaw['memberName'] as String? ?? 'Unknown Member',
            dueDate: dueDate,
            daysOverdue: days,
          ),
        );
      } else {
        activeLoans++;
      }
    }

    // Sort overdue items by greatest days overdue first
    overdueItems.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    return DashboardStats(
      totalBooks: totalBooks,
      activeLoans: activeLoans,
      overdueLoans: overdueLoans,
      totalMembers: totalMembers,
      overdueLoansList: overdueItems,
    );
  }
}
