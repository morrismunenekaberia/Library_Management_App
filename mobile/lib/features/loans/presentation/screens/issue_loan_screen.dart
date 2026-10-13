import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/controllers/books_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/controllers/members_controller.dart';
import '../controllers/loans_controller.dart';

/// Form screen for issuing a book loan to an active member.
/// Features searchable active member and available book pickers, and a 14-day default due date.
class IssueLoanScreen extends StatefulWidget {
  const IssueLoanScreen({super.key});

  @override
  State<IssueLoanScreen> createState() => _IssueLoanScreenState();
}

class _IssueLoanScreenState extends State<IssueLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  Member? _selectedMember;
  Book? _selectedBook;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    // Due date defaults to 14 days from today
    _dueDate = DateTime.now().add(const Duration(days: 14));

    // Clear form error message and ensure members & books are fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoansController>().clearError();
      final membersController = context.read<MembersController>();
      if (membersController.members.isEmpty) {
        membersController.fetchMembers();
      }
      final booksController = context.read<BooksController>();
      if (booksController.books.isEmpty) {
        booksController.fetchBooks();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final initial = _dueDate.isBefore(tomorrow) ? tomorrow : _dueDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _showMemberPicker() async {
    final membersController = context.read<MembersController>();
    // Filter active members only
    final activeMembers = membersController.members
        .where((m) => m.status == 'active')
        .toList();

    final selected = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return _SearchablePicker<Member>(
          title: 'Select Active Member',
          hintText: 'Search members...',
          items: activeMembers,
          itemTitle: (m) => m.fullName,
          itemSubtitle: (m) => 'Admission No: ${m.admissionNumber}',
          matchesQuery: (m, query) =>
              m.fullName.toLowerCase().contains(query) ||
              m.admissionNumber.toLowerCase().contains(query),
          onSearchBackend: (query) => membersController.fetchMembers(search: query),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedMember = selected;
      });
    }
  }

  Future<void> _showBookPicker() async {
    final booksController = context.read<BooksController>();
    // Filter books with available copies only
    final availableBooks =
        booksController.books.where((b) => b.availableCopies > 0).toList();

    final selected = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return _SearchablePicker<Book>(
          title: 'Select Available Book',
          hintText: 'Search books...',
          items: availableBooks,
          itemTitle: (b) => b.title,
          itemSubtitle: (b) =>
              'By ${b.author} • ${b.availableCopies} available',
          matchesQuery: (b, query) =>
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query) ||
              b.isbn.toLowerCase().contains(query),
          onSearchBackend: (query) => booksController.fetchBooks(search: query),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedBook = selected;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book')),
      );
      return;
    }

    final loansController = context.read<LoansController>();
    final result = await loansController.issueLoan(
      bookId: _selectedBook!.id,
      memberId: _selectedMember!.id,
      dueDate: _formatDate(_dueDate),
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan issued for "${_selectedBook!.title}" to ${_selectedMember!.fullName}',
            ),
          ),
        );
        // Refresh dashboard metrics if controller is available
        try {
          context.read<DashboardController>().fetchDashboard();
        } catch (_) {}
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loansController = context.watch<LoansController>();
    final isSaving = loansController.isSaving;
    final formError = loansController.formErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue New Loan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form error banner
                  if (formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formError,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Member Picker Tile
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedMember == null
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                    child: ListTile(
                      onTap: isSaving ? null : _showMemberPicker,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        _selectedMember != null
                            ? _selectedMember!.fullName
                            : 'Select Member *',
                        style: TextStyle(
                          fontWeight: _selectedMember != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _selectedMember != null
                            ? 'Adm: ${_selectedMember!.admissionNumber} • Active'
                            : 'Active members only',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Book Picker Tile
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedBook == null
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                    child: ListTile(
                      onTap: isSaving ? null : _showBookPicker,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        _selectedBook != null
                            ? _selectedBook!.title
                            : 'Select Book *',
                        style: TextStyle(
                          fontWeight: _selectedBook != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _selectedBook != null
                            ? 'By ${_selectedBook!.author} • ${_selectedBook!.availableCopies} copies available'
                            : 'Available books only',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Due Date Picker Tile
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: isSaving ? null : _selectDueDate,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.tertiaryContainer,
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      title: const Text('Due Date *'),
                      subtitle: Text(
                        '${_formatDate(_dueDate)} (in ${_dueDate.difference(DateTime.now()).inDays + 1} days)',
                      ),
                      trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  FilledButton(
                    onPressed: isSaving ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Issue Loan',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchablePicker<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final List<T> items;
  final String Function(T) itemTitle;
  final String Function(T) itemSubtitle;
  final bool Function(T, String) matchesQuery;
  final Future<void> Function(String)? onSearchBackend;

  const _SearchablePicker({
    required this.title,
    required this.hintText,
    required this.items,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.matchesQuery,
    this.onSearchBackend,
  });

  @override
  State<_SearchablePicker<T>> createState() => _SearchablePickerState<T>();
}

class _SearchablePickerState<T> extends State<_SearchablePicker<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.items.where((item) {
      if (_query.isEmpty) return true;
      return widget.matchesQuery(item, _query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SearchField(
                controller: _searchController,
                hintText: widget.hintText,
                onChanged: (val) {
                  setState(() {
                    _query = val.trim();
                  });
                },
                onSubmitted: (val) {
                  if (widget.onSearchBackend != null) {
                    widget.onSearchBackend!(val);
                  }
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                  if (widget.onSearchBackend != null) {
                    widget.onSearchBackend!('');
                  }
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching results found',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(widget.itemTitle(item)),
                          subtitle: Text(widget.itemSubtitle(item)),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

