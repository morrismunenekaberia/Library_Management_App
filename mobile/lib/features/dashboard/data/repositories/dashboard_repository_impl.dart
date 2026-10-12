import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

/// Implementation of [DashboardRepository] that delegates to [DashboardRemoteDataSource].
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<DashboardStats> getLibrarianDashboard() async {
    return await remoteDataSource.getDashboardStats();
  }
}

