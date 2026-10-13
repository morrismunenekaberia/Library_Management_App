import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/usecases/create_member.dart';
import '../../domain/usecases/delete_member.dart';
import '../../domain/usecases/get_member.dart';
import '../../domain/usecases/list_members.dart';
import '../../domain/usecases/update_member.dart';

/// State management controller for the Members feature.
class MembersController extends ChangeNotifier {
  final ListMembers listMembersUseCase;
  final GetMember getMemberUseCase;
  final CreateMember createMemberUseCase;
  final UpdateMember updateMemberUseCase;
  final DeleteMember deleteMemberUseCase;

  MembersController({
    required this.listMembersUseCase,
    required this.getMemberUseCase,
    required this.createMemberUseCase,
    required this.updateMemberUseCase,
    required this.deleteMemberUseCase,
  });

  List<Member> _members = [];
  Member? _selectedMember;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _formErrorMessage;
  String _searchQuery = '';

  List<Member> get members => List.unmodifiable(_members);
  Member? get selectedMember => _selectedMember;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String get searchQuery => _searchQuery;

  /// Loads members list with optional search filter.
  Future<void> fetchMembers({String? search, bool isRefresh = false}) async {
    _searchQuery = search ?? _searchQuery;
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await listMembersUseCase(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _members = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Searches members by query string.
  Future<void> search(String query) async {
    _searchQuery = query.trim();
    await fetchMembers(search: _searchQuery);
  }

  /// Clears search filter and reloads all members.
  Future<void> clearSearch() async {
    _searchQuery = '';
    await fetchMembers(search: '');
  }

  /// Fetches a specific member's details by ID.
  Future<Member?> fetchMemberDetails(int id) async {
    _isDetailLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final member = await getMemberUseCase(id);
      _selectedMember = member;
      return member;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new member entry.
  Future<CreateMemberResult?> createMember({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  }) async {
    _isSaving = true;
    _formErrorMessage = null;
    notifyListeners();

    try {
      final result = await createMemberUseCase(
        fullName: fullName,
        admissionNumber: admissionNumber,
        phone: phone,
        email: email,
        status: status,
        createUser: createUser,
      );
      _members = [result.member, ..._members];
      return result;
    } catch (e) {
      _formErrorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates an existing member.
  Future<Member?> updateMember(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  }) async {
    _isSaving = true;
    _formErrorMessage = null;
    notifyListeners();

    try {
      final updated = await updateMemberUseCase(
        id,
        fullName: fullName,
        admissionNumber: admissionNumber,
        phone: phone,
        email: email,
        status: status,
      );

      // Update in local cache
      final index = _members.indexWhere((m) => m.id == id);
      if (index != -1) {
        _members[index] = updated;
      }
      if (_selectedMember?.id == id) {
        _selectedMember = updated;
      }
      return updated;
    } catch (e) {
      _formErrorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes a member by ID.
  Future<bool> deleteMember(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deleteMemberUseCase(id);
      _members.removeWhere((m) => m.id == id);
      if (_selectedMember?.id == id) {
        _selectedMember = null;
      }
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isDeleting = false;
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
