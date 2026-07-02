import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceSubmittedRequestPage extends StatelessWidget {
  const ServiceSubmittedRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ServiceRequestFlowScope.of(context);

    return ServiceRequestScreenScaffold(
      interceptSystemBack: true,
      onRefresh: () async {
        final detail = await controller.refreshActiveTicket();
        if (detail == null || !context.mounted) {
          return;
        }
        final route = controller.routeForServiceStatus(detail);
        if (route != ServiceRequestRoutes.submitted) {
          context.go(route);
        }
      },
      onBack: () => context.go(ServiceRequestRoutes.services),
      child: ServiceSubmittedStepPage(
        ticket: controller.createdTicket,
        onRetry: () => context.go(ServiceRequestRoutes.services),
        onBackToServices: () => context.go(ServiceRequestRoutes.services),
        formatDateTime: controller.formatDateTime,
      ),
    );
  }
}

class ServiceSubmittedStepPage extends StatelessWidget {
  const ServiceSubmittedStepPage({
    super.key,
    required this.ticket,
    required this.onRetry,
    required this.onBackToServices,
    required this.formatDateTime,
  });

  final ServiceTicketRecord? ticket;
  final VoidCallback onRetry;
  final VoidCallback onBackToServices;
  final String Function(String raw) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentTicket = ticket;
    if (currentTicket == null) {
      return ServiceRequestErrorStateCard(
        message: l10n.serviceRequestUnavailable,
        onRetry: onRetry,
      );
    }

    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ServiceRequestSuccessIcon(icon: Icons.send_outlined),
          const SizedBox(height: 18),
          Text(
            l10n.ticketCreated,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ticketSubmittedSuccess,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ServiceRequestDetailPanel(
            rows: [
              (l10n.ticketNumber, currentTicket.ticketNumber),
              (l10n.status, currentTicket.status),
              (l10n.priority, currentTicket.priority),
              (l10n.category, currentTicket.category.displayLabel),
              (l10n.subcategory, currentTicket.subcategory.displayLabel),
              if (currentTicket.slaState.isNotEmpty)
                (l10n.slaState, currentTicket.slaState),
              if (currentTicket.slaDueAt.isNotEmpty)
                (l10n.slaDue, formatDateTime(currentTicket.slaDueAt)),
            ],
          ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: l10n.backToServices,
            icon: Icons.arrow_back_rounded,
            onPressed: onBackToServices,
          ),
        ],
      ),
    );
  }
}
