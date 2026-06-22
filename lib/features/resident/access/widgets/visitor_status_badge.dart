import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class VisitorStatusBadge extends StatelessWidget {
  const VisitorStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Checked In' => AppColors.success,
      'Checked Out' => AppColors.textMuted,
      'Upcoming' => AppColors.info,
      'Generated' => AppColors.gold,
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
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
