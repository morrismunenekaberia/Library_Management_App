import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

/// Use case that fetches aggregated dashboard statistics for librarians.
class GetLibrarianDashboard {
  final DashboardRepository repository;

  const GetLibrarianDashboard(this.repository);

  Future<DashboardStats> call() async {
    return await repository.getLibrarianDashboard();
  }
}
