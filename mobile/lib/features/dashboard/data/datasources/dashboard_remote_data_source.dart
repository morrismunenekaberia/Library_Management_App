import '../../../../core/api_client/api_client.dart';
import '../../../loans/data/models/loan_model.dart';
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
    // Attempt to fetch from optimized GET /stats endpoint first
    try {
      final res = await _apiClient.get('/stats');
      if (res is Map<String, dynamic>) {
        final recentLoansJson = res['recentLoans'] as List<dynamic>? ?? [];
        final recentLoans = recentLoansJson
            .map((json) => LoanModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Also fetch overdue loans if needed for overdue list
        final loansRes = await _apiClient.get('/loans?status=overdue');
        final overdueLoansJson = loansRes as List<dynamic>? ?? [];
        final overdueItems = <OverdueLoanItem>[];
        final now = DateTime.now();

        for (final loanRaw in overdueLoansJson) {
          if (loanRaw is! Map<String, dynamic>) continue;
          final dueDateStr = loanRaw['dueDate'] as String?;
          if (dueDateStr == null) continue;
          final dueDate = DateTime.parse(dueDateStr);
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
        }

        overdueItems.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

        return DashboardStats(
          totalBooks: (res['totalBooks'] as num?)?.toInt() ?? 0,
          activeLoans: (res['activeLoans'] as num?)?.toInt() ?? 0,
          overdueLoans: (res['overdueLoans'] as num?)?.toInt() ?? 0,
          activeMembers: (res['activeMembers'] as num?)?.toInt() ?? 0,
          overdueLoansList: overdueItems,
          recentLoans: recentLoans,
        );
      }
    } catch (_) {
      // Fallback to client-side aggregation across /books, /loans, /members
    }

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
    final recentLoans = <LoanModel>[];
    final now = DateTime.now();

    for (final loanRaw in loansList) {
      if (loanRaw is! Map<String, dynamic>) continue;
      recentLoans.add(LoanModel.fromJson(loanRaw));

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
      activeMembers: totalMembers,
      overdueLoansList: overdueItems,
      recentLoans: recentLoans.take(5).toList(),
    );
  }
}
