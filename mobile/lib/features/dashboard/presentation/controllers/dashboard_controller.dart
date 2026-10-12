import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_librarian_dashboard.dart';

enum DashboardStatus { initial, loading, loaded, error }

/// Controller managing state and lifecycle for the librarian dashboard.
class DashboardController extends ChangeNotifier {
  final GetLibrarianDashboard getLibrarianDashboardUseCase;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardStats? _stats;
  String? _errorMessage;

  DashboardController({required this.getLibrarianDashboardUseCase});

  DashboardStatus get status => _status;
  DashboardStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DashboardStatus.loading;

  /// Fetches dashboard statistics. If [isRefresh] is true, avoids setting full loading spinner.
  Future<void> fetchDashboard({bool isRefresh = false}) async {
    if (!isRefresh) {
      _status = DashboardStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _stats = await getLibrarianDashboardUseCase();
      _status = DashboardStatus.loaded;
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = DashboardStatus.error;
    } catch (_) {
      _errorMessage =
          'Cannot reach the server. Check Wi-Fi and that the API is running.';
      _status = DashboardStatus.error;
    } finally {
      notifyListeners();
    }
  }
}
