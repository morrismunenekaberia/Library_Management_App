import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:library_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:library_mobile/features/dashboard/presentation/widgets/dashboard_metric_card.dart';
import 'package:library_mobile/features/dashboard/presentation/widgets/overdue_loan_tile.dart';
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final dashboardController = context.watch<DashboardController>();
    final user = authController.user;

    final roleLabel = user?.isLibrarian == true
        ? 'Librarian'
        : (user?.isMember == true ? 'Member' : (user?.role ?? 'Unknown'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Manager'),
        actions: [
          if (user?.isLibrarian == true)
            IconButton(
              tooltip: 'Refresh Dashboard',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<DashboardController>().fetchDashboard();
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
      body: _buildBody(context, theme, authController, dashboardController, user, roleLabel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AuthController authController,
    DashboardController dashboardController,
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
      return _buildMemberOverview(context, theme, user, roleLabel);
    }
  }

  /// Builds the complete Librarian Dashboard with metric cards and overdue loans.
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

          // 2x2 Metrics Grid
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
                  DashboardMetricCard(
                    title: 'Total Books',
                    count: '${stats?.totalBooks ?? 0}',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF1E3A8A),
                  ),
                  DashboardMetricCard(
                    title: 'Active Loans',
                    count: '${stats?.activeLoans ?? 0}',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                  DashboardMetricCard(
                    title: 'Overdue Loans',
                    count: '${stats?.overdueLoans ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    isDestructive: true,
                  ),
                  DashboardMetricCard(
                    title: 'Members',
                    count: '${stats?.totalMembers ?? 0}',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Overdue Loans Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Overdue Loans',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stats != null && stats.overdueLoansList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stats.overdueLoansList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overdue Loans List or Empty State
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
              (loan) => OverdueLoanTile(loan: loan),
            ),
        ],
      ),
    );
  }

  /// Builds the overview for non-librarian member users.
  Widget _buildMemberOverview(
    BuildContext context,
    ThemeData theme,
    dynamic user,
    String roleLabel,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome, ${user.username ?? "User"}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Role: $roleLabel',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to Library Manager. Browse our book catalogue to view available titles.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go('/books'),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Browse Books Catalogue'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.read<AuthController>().logout(),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
