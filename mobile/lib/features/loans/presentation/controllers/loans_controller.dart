import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/loan.dart';
import '../../domain/usecases/issue_loan.dart';
import '../../domain/usecases/list_loans.dart';
import '../../domain/usecases/return_loan.dart';

/// State management controller for the Loans feature.
class LoansController extends ChangeNotifier {
  final ListLoans listLoansUseCase;
  final IssueLoan issueLoanUseCase;
  final ReturnLoan returnLoanUseCase;

  LoansController({
    required this.listLoansUseCase,
    required this.issueLoanUseCase,
    required this.returnLoanUseCase,
  });

  List<Loan> _loans = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _formErrorMessage;
  String? _statusFilter;

  List<Loan> get loans => List.unmodifiable(_loans);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get statusFilter => _statusFilter;

  /// Loads loans with optional status and member filters.
  Future<void> fetchLoans({
    String? status,
    int? memberId,
    bool isRefresh = false,
  }) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await listLoansUseCase(
        status: status ?? _statusFilter,
        memberId: memberId,
      );
      _loans = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the status filter and re-fetches loans.
  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    await fetchLoans(status: status);
  }

  /// Issues a new loan. Returns the created [Loan] or null on error.
  Future<Loan?> issueLoan({
    required int bookId,
    required int memberId,
    String? dueDate,
  }) async {
    _isSaving = true;
    _formErrorMessage = null;
    notifyListeners();

    try {
      final createdLoan = await issueLoanUseCase(
        bookId: bookId,
        memberId: memberId,
        dueDate: dueDate,
      );
      _loans = [createdLoan, ..._loans];
      return createdLoan;
    } catch (e) {
      _formErrorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Returns a loan by ID. Returns true on success, false on error.
  Future<bool> returnLoan(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await returnLoanUseCase(id);
      _loans.removeWhere((l) => l.id == id);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Clears any active error message.
  void clearError() {
    _errorMessage = null;
    _formErrorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred';
    if (error is AppException) return error.message;
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}
