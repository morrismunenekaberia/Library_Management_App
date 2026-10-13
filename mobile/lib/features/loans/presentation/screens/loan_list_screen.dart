import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/loan.dart';
import '../controllers/loans_controller.dart';
import 'issue_loan_screen.dart';

/// Screen displaying the list of loans with ChoiceChips filter (Active, Overdue, Returned),
/// pull-to-refresh, overdue highlights, and optional book return / issue actions.
class LoanListScreen extends StatefulWidget {
  final bool? isReadOnly;
  final String? title;

  const LoanListScreen({
    super.key,
    this.isReadOnly,
    this.title,
  });

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Selected filter: null means All (or default 'active')
  String _selectedFilter = 'active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<LoansController>();
      controller.fetchLoans(status: _selectedFilter);
    });
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    context.read<LoansController>().setStatusFilter(filter);
  }

  Future<void> _confirmReturnLoan(Loan loan) async {
    final theme = Theme.of(context);
    final bookName = loan.bookTitle ?? 'this book';
    final memberName = loan.memberName ?? 'the member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return Book'),
        content: Text(
          'Confirm return of "$bookName" borrowed by $memberName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Return Book'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = context.read<LoansController>();
      final success = await controller.returnLoan(loan.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$bookName" has been marked as returned.'),
            ),
          );
          // Refresh list after returning
          await controller.fetchLoans(
            status: _selectedFilter,
            isRefresh: true,
          );
          // Refresh dashboard stats if mounted
          if (mounted) {
            try {
              context.read<DashboardController>().fetchDashboard(isRefresh: true);
            } catch (_) {}
          }
        } else if (controller.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final loansController = context.watch<LoansController>();

    final isLibrarian = authController.user?.isLibrarian ?? false;
    final isReadOnly = widget.isReadOnly ?? !isLibrarian;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? (isReadOnly ? 'My Loans' : 'Loans')),
      ),
      floatingActionButton: (!isReadOnly && isLibrarian)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final controller = context.read<LoansController>();
                final issued = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const IssueLoanScreen(),
                  ),
                );
                if (issued == true) {
                  controller.fetchLoans(
                    status: _selectedFilter,
                    isRefresh: true,
                  );
                }
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Issue Loan'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Row with ChoiceChips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _selectedFilter == 'active',
                  onSelected: (selected) {
                    if (selected) _onFilterChanged('active');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Overdue'),
                  selected: _selectedFilter == 'overdue',
                  onSelected: (selected) {
                    if (selected) _onFilterChanged('overdue');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Returned'),
                  selected: _selectedFilter == 'returned',
                  onSelected: (selected) {
                    if (selected) _onFilterChanged('returned');
                  },
                ),
              ],
            ),
          ),

          // Main list area
          Expanded(
            child: _buildBody(context, loansController, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LoansController controller,
    ThemeData theme,
  ) {
    if (controller.isLoading) {
      return const LoadingIndicator(message: 'Loading loans...');
    }

    if (controller.errorMessage != null && controller.loans.isEmpty) {
      return ErrorState(
        message: controller.errorMessage!,
        onRetry: () => controller.fetchLoans(
          status: _selectedFilter,
          isRefresh: true,
        ),
      );
    }

    if (controller.loans.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.fetchLoans(
          status: _selectedFilter,
          isRefresh: true,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No $_selectedFilter loans',
                message: 'There are currently no $_selectedFilter loans found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchLoans(
        status: _selectedFilter,
        isRefresh: true,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: controller.loans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final loan = controller.loans[index];
          return _LoanCard(
            loan: loan,
            isReadOnly: isReadOnly,
            onReturn: () => _confirmReturnLoan(loan),
            isReturning: controller.isSaving,
          );
        },
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final bool isReadOnly;
  final VoidCallback onReturn;
  final bool isReturning;

  const _LoanCard({
    required this.loan,
    this.isReadOnly = false,
    required this.onReturn,
    required this.isReturning,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = loan.isOverdue;
    final isReturned = loan.isReturned;

    final borderColor = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.outlineVariant;
    final cardBackgroundColor = isOverdue
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.15)
        : theme.colorScheme.surface;

    return Card(
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Book title and status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    loan.bookTitle ?? 'Book #${loan.bookId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isOverdue)
                  StatusChip.overdue()
                else if (isReturned)
                  const StatusChip.returned()
                else
                  const StatusChip.active(),
              ],
            ),
            const SizedBox(height: 6),

            // Member Name
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loan.memberName ?? 'Member #${loan.memberId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dates Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Issued: ${_formatDate(loan.issuedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Due: ${_formatDate(loan.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),

            // Overdue days alert badge
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${loan.daysOverdue} days overdue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Return book button for active or overdue loans (librarian only / not read-only)
            if (!isReturned && !isReadOnly) ...[
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: isOverdue
                      ? FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        )
                      : null,
                  onPressed: isReturning ? null : onReturn,
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: const Text('Return book'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

