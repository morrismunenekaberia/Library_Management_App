import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Settings screen displaying user profile details, environment configuration, and sign-out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Library Manager?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final user = authController.user;

    final roleLabel = user?.isLibrarian == true
        ? 'Librarian'
        : (user?.isMember == true ? 'Member' : (user?.role ?? 'Unknown'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Card
                AppCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          user?.isLibrarian == true
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user?.username ?? 'Not logged in',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(
                        label: 'Role: $roleLabel',
                        color: user?.isLibrarian == true
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Account & Application Information Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SettingsRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Username',
                        value: user?.username ?? '—',
                      ),
                      const Divider(height: AppSpacing.md),
                      _SettingsRow(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: roleLabel,
                      ),
                      if (user?.memberId != null) ...[
                        const Divider(height: AppSpacing.md),
                        _SettingsRow(
                          icon: Icons.tag_rounded,
                          label: 'Member ID',
                          value: '${user!.memberId}',
                        ),
                      ],
                      if (kDebugMode) ...[
                        const Divider(height: AppSpacing.md),
                        _SettingsRow(
                          icon: Icons.dns_outlined,
                          label: 'API Base URL',
                          value: AppConstants.apiBaseUrl,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sign Out Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

