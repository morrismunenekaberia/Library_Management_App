import '../entities/dashboard_stats.dart';

/// Repository interface for librarian dashboard data.
abstract class DashboardRepository {
  Future<DashboardStats> getLibrarianDashboard();
}

