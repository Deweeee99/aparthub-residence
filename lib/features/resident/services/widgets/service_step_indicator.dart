import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ServiceStepIndicator extends StatelessWidget {
  const ServiceStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.onStepSelected,
  });

  final int currentStep;
  final List<String> steps;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, _) => const _StepConnector(),
        itemBuilder: (context, index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          return _StepNode(
            label: steps[index],
            number: index + 1,
            isActive: isActive,
            isCompleted: isCompleted,
            onTap: () => onStepSelected(index),
          );
        },
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 20,
        height: 1.2,
        color: AppColors.gold.withValues(alpha: 0.32),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.number,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final String label;
  final int number;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isActive
        ? AppColors.gold
        : isCompleted
        ? AppColors.goldSoft
        : AppColors.surfaceMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? Colors.white : AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
