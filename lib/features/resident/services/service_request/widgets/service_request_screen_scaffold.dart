import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../service_request_routes.dart';

class ServiceRequestScreenScaffold extends StatelessWidget {
  const ServiceRequestScreenScaffold({
    super.key,
    required this.child,
    required this.onRefresh,
    this.onBack,
    this.interceptSystemBack = false,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final VoidCallback? onBack;
  final bool interceptSystemBack;

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      key: const ValueKey('service-refresh-indicator'),
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('service-request-page'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
        children: [
          _ServiceRequestHeader(onBack: onBack ?? () => _defaultBack(context)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );

    if (!interceptSystemBack) {
      return content;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        (onBack ?? () => context.go(ServiceRequestRoutes.services)).call();
      },
      child: content,
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(ServiceRequestRoutes.services);
  }
}

class _ServiceRequestHeader extends StatelessWidget {
  const _ServiceRequestHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n.back,
          onPressed: onBack,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          alignment: Alignment.centerLeft,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.serviceRequest,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fast, transparent, and efficient issue resolution.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}
