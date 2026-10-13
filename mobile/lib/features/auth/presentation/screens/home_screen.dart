import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:library_mobile/core/widgets/stat_card.dart';
import 'package:library_mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:library_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:library_mobile/features/loans/domain/entities/loan.dart';
import 'package:library_mobile/features/loans/presentation/controllers/loans_controller.dart';
import '../controllers/auth_controller.dart';

/// Home screen displaying the Librarian Dashboard or Member Overview.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.user?.isLibrarian == true) {
        context.read<DashboardController>().fetchDashboard();
      } else if (authController.user?.isMember == true) {
        context.read<LoansController>().fetchLoans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final dashboardController = context.watch<DashboardController>();
    final loansController = context.watch<LoansController>();
    final user = authController.user;

    final roleLabel = user?.isLibrarian == true
        ? 'Librarian'
        : (user?.isMember == true ? 'Member' : (user?.role ?? 'Unknown'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (user?.isLibrarian == true) {
                context.read<DashboardController>().fetchDashboard(isRefresh: true);
              } else if (user?.isMember == true) {
                context.read<LoansController>().fetchLoans(isRefresh: true);
              }
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthController>().logout();
            },
          ),
        ],
      ),
      body: _buildBody(
        context,
        theme,
        authController,
        dashboardController,
        loansController,
        user,
        roleLabel,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AuthController authController,
    DashboardController dashboardController,
    LoansController loansController,
    dynamic user,
    String roleLabel,
  ) {
    if (authController.status == AuthStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authController.errorMessage != null && user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authController.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuthController>().restoreSession(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Session',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Please sign in to access your library account.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.read<AuthController>().logout(),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Role-specific view: Librarian Dashboard vs Member Overview
    if (user.isLibrarian == true) {
      return _buildLibrarianDashboard(context, theme, dashboardController, user, roleLabel);
    } else {
      return _buildMemberOverview(context, theme, loansController, user, roleLabel);
    }
  }

  /// Builds the complete Librarian Dashboard with 4 StatCards and recent loans.
  Widget _buildLibrarianDashboard(
    BuildContext context,
    ThemeData theme,
    DashboardController dashboardController,
    dynamic user,
    String roleLabel,
  ) {
    if (dashboardController.isLoading && dashboardController.stats == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard metrics...'),
          ],
        ),
      );
    }

    if (dashboardController.errorMessage != null && dashboardController.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load dashboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dashboardController.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => dashboardController.fetchDashboard(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = dashboardController.stats;

    return RefreshIndicator(
      onRefresh: () => dashboardController.fetchDashboard(isRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Welcome Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.username ?? "User"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Role: $roleLabel',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.read<AuthController>().logout(),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Title
          Text(
            'Library Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Four StatCards: total books, active members, active loans, overdue loans (in red)
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    title: 'Total Books',
                    value: '${stats?.totalBooks ?? 0}',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF1E3A8A),
                  ),
                  StatCard(
                    title: 'Active Members',
                    value: '${stats?.activeMembers ?? 0}',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  StatCard(
                    title: 'Active Loans',
                    value: '${stats?.activeLoans ?? 0}',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                  StatCard(
                    title: 'Overdue Loans',
                    value: '${stats?.overdueLoans ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    isDestructive: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Overdue Loans Section (backward compatible with previous dashboard widgets)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overdue Loans',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (stats == null || stats.overdueLoansList.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 36.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Overdue Loans',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All borrowed books are up to date.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...stats.overdueLoansList.map(
              (item) => _OverdueLoanTileItem(item: item),
            ),
          const SizedBox(height: 28),

          // Recent Loans Section
          Text(
            'Recent Loans',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (stats == null || stats.recentLoans.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 36.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 44,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Recent Loans',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No loans have been recorded yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...stats.recentLoans.map(
              (loan) => _RecentLoanItemTile(loan: loan),
            ),
        ],
      ),
    );
  }

  /// Builds the overview for Member role: greeting with name, active & overdue loan counts.
  Widget _buildMemberOverview(
    BuildContext context,
    ThemeData theme,
    LoansController loansController,
    dynamic user,
    String roleLabel,
  ) {
    if (loansController.isLoading && loansController.loans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final memberLoans = loansController.loans;
    final activeCount = memberLoans.where((l) => l.isActive).length;
    final overdueCount = memberLoans.where((l) => l.isOverdue).length;

    return RefreshIndicator(
      onRefresh: () => loansController.fetchLoans(isRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Greeting Card with member's name
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user.username ?? "Member"}!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome to your library portal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Title
          Text(
            'My Loans Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Member Loan Counts: Active and Overdue
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 600 ? 2 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    title: 'Active Loans',
                    value: '$activeCount',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                  StatCard(
                    title: 'Overdue Loans',
                    value: '$overdueCount',
                    icon: Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    isDestructive: overdueCount > 0,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Active/Overdue Loans List summary
          Text(
            'Current Borrowed Books',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (memberLoans.where((l) => !l.isReturned).isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 36.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No Borrowed Books',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You do not have any active or overdue loans at this time.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...memberLoans
                .where((l) => !l.isReturned)
                .map((loan) => _RecentLoanItemTile(loan: loan)),
        ],
      ),
    );
  }
}

class _RecentLoanItemTile extends StatelessWidget {
  final Loan loan;

  const _RecentLoanItemTile({required this.loan});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = loan.isOverdue;
    final isReturned = loan.isReturned;

    final badgeColor = isOverdue
        ? theme.colorScheme.error
        : (isReturned ? theme.colorScheme.outline : theme.colorScheme.primary);
    final badgeText = isOverdue
        ? '${loan.daysOverdue}d overdue'
        : (isReturned ? 'Returned' : 'Active');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.12),
          child: Icon(
            isOverdue
                ? Icons.warning_amber_rounded
                : (isReturned ? Icons.done_all_rounded : Icons.menu_book_rounded),
            color: badgeColor,
            size: 20,
          ),
        ),
        title: Text(
          loan.bookTitle ?? 'Untitled Book',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loan.memberName != null)
              Text(
                'Member: ${loan.memberName}',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              'Due: ${_formatDate(loan.dueDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOverdue ? theme.colorScheme.error : null,
                fontWeight: isOverdue ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueLoanTileItem extends StatelessWidget {
  final OverdueLoanItem item;

  const _OverdueLoanTileItem({required this.item});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: errorColor.withValues(alpha: 0.12),
          child: Icon(
            Icons.warning_amber_rounded,
            color: errorColor,
            size: 20,
          ),
        ),
        title: Text(
          item.bookTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.memberName,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Due: ${_formatDate(item.dueDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.daysOverdue} days overdue',
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
