import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum LuxuryButtonVariant { primary, secondary, ghost }

class LuxuryButton extends StatelessWidget {
  const LuxuryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.fullWidth = true,
    this.variant = LuxuryButtonVariant.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool danger;
  final bool fullWidth;
  final LuxuryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final buttonChild = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: switch (variant) {
        LuxuryButtonVariant.primary => _PrimaryButton(
          label: buttonChild,
          onPressed: onPressed,
          danger: danger,
        ),
        LuxuryButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: danger ? AppColors.danger : AppColors.navy,
            side: BorderSide(
              color: danger ? AppColors.danger : AppColors.borderStrong,
            ),
          ),
          child: buttonChild,
        ),
        LuxuryButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: danger ? AppColors.danger : AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: buttonChild,
        ),
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.danger,
  });

  final Widget label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = danger
        ? [AppColors.danger, const Color(0xFFB53B38)]
        : [AppColors.navy, AppColors.blue];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        child: label,
      ),
    );
  }
}
