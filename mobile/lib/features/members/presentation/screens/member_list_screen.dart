import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/member.dart';
import '../controllers/members_controller.dart';
import 'member_form_screen.dart';

/// Screen displaying the list of library members with search, pull-to-refresh,
/// add, edit, and delete functionality (Librarian only).
class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MembersController>();
      if (controller.members.isEmpty) {
        controller.fetchMembers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    context.read<MembersController>().search(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<MembersController>().clearSearch();
  }

  Future<void> _confirmDeleteMember(Member member) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
          'Are you sure you want to delete member "${member.fullName}" (${member.admissionNumber})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = context.read<MembersController>();
      final success = await controller.deleteMember(member.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member "${member.fullName}" deleted successfully'),
            ),
          );
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
    final membersController = context.watch<MembersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MemberFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search members by name or admission no...',
              onChanged: (value) {
                if (value.isEmpty) {
                  _onClearSearch();
                }
              },
              onSubmitted: _onSearchSubmitted,
              onClear: _onClearSearch,
            ),
          ),

          // Main Content Area
          Expanded(
            child: _buildBody(context, membersController, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MembersController controller,
    ThemeData theme,
  ) {
    if (controller.isLoading) {
      return const LoadingIndicator(message: 'Loading members...');
    }

    if (controller.errorMessage != null && controller.members.isEmpty) {
      return ErrorState(
        message: controller.errorMessage!,
        onRetry: () => controller.fetchMembers(isRefresh: true),
      );
    }

    if (controller.members.isEmpty) {
      final isSearching = controller.searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () => controller.fetchMembers(isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: isSearching
                    ? Icons.person_search_rounded
                    : Icons.people_outline_rounded,
                title: isSearching ? 'No matching members' : 'No members found',
                message: isSearching
                    ? 'No members found matching "${controller.searchQuery}".'
                    : 'There are currently no registered library members.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchMembers(isRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: controller.members.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final member = controller.members[index];
          return _MemberCard(
            member: member,
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemberFormScreen(
                    memberId: member.id,
                    initialMember: member,
                  ),
                ),
              );
            },
            onDelete: () => _confirmDeleteMember(member),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = member.status == 'active';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adm No: ${member.admissionNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  const StatusChip.active()
                else
                  const StatusChip.suspended(),
              ],
            ),
            if (member.email != null || member.phone != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (member.email != null && member.email!.isNotEmpty) ...[
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        member.email!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (member.phone != null && member.phone!.isNotEmpty) ...[
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
