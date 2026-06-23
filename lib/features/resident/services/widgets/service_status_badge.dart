import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ServiceStatusBadge extends StatelessWidget {
  const ServiceStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim();
    final color = switch (normalizedStatus) {
      'Submitted' => AppColors.info,
      'Open' => AppColors.info,
      'Assigned' => AppColors.warning,
      'In Progress' => AppColors.gold,
      'Progress' => AppColors.gold,
      'Completed' => AppColors.success,
      'Done' => AppColors.success,
      'Emergency' => AppColors.danger,
      'Over SLA' => AppColors.danger,
      'Cancelled' => AppColors.textMuted,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        normalizedStatus,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
