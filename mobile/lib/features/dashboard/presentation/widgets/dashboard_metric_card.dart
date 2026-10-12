import 'package:flutter/material.dart';

/// Reusable Material 3 metric card displaying key library counts.
class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color? color;
  final bool isDestructive;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.color,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isDestructive
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.7)
        : theme.colorScheme.surfaceContainerHigh;
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : (color ?? theme.colorScheme.primary);
    final countColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final titleColor = isDestructive
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDestructive
            ? BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

