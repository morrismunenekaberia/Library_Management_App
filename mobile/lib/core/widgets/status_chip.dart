import 'package:flutter/material.dart';

/// Small chip indicating a status (e.g. Active, Suspended, Overdue).
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
  });

  /// Predefined chip for 'active' status.
  const StatusChip.active({super.key})
      : label = 'Active',
        color = const Color(0xFF16A34A);

  /// Predefined chip for 'suspended' status.
  const StatusChip.suspended({super.key})
      : label = 'Suspended',
        color = const Color(0xFFDC2626);

  /// Predefined chip for 'overdue' status.
  const StatusChip.overdue({super.key})
      : label = 'Overdue',
        color = const Color(0xFFDC2626);

  /// Predefined chip for 'returned' status.
  const StatusChip.returned({super.key})
      : label = 'Returned',
        color = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

