import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../service_request_flow_controller.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceCompletedRequestPage extends StatefulWidget {
  const ServiceCompletedRequestPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<ServiceCompletedRequestPage> createState() =>
      _ServiceCompletedRequestPageState();
}

class _ServiceCompletedRequestPageState
    extends State<ServiceCompletedRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTicketLoaded());
  }

  @override
  void didUpdateWidget(ServiceCompletedRequestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureTicketLoaded(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ServiceRequestFlowScope.of(context);
    final ticket = controller.activeTicket?.id == widget.ticketId
        ? controller.activeTicket
        : null;

    return ServiceRequestScreenScaffold(
      onRefresh: () => _refresh(controller),
      child: controller.isLoadingTicketDetail && ticket == null
          ? ServiceRequestLoadingStateCard(
              message: AppLocalizations.of(context).loadingServiceHistory,
            )
          : ServiceCompletedStepPage(
              ticket: ticket,
              onRetry: () => controller.fetchTicketDetail(widget.ticketId),
              onViewHistory: () => context.push(ServiceRequestRoutes.history),
              formatDateTime: controller.formatDateTime,
              isCompletedTicket: controller.isCompletedTicket,
            ),
    );
  }

  Future<void> _ensureTicketLoaded() async {
    final controller = ServiceRequestFlowScope.of(context);
    if (controller.activeTicket?.id == widget.ticketId ||
        controller.isLoadingTicketDetail) {
      return;
    }
    await _refresh(controller);
  }

  Future<void> _refresh(ServiceRequestFlowController controller) async {
    await controller.fetchTicketDetail(widget.ticketId);
  }
}

class ServiceCompletedStepPage extends StatelessWidget {
  const ServiceCompletedStepPage({
    super.key,
    required this.ticket,
    required this.onRetry,
    required this.onViewHistory,
    required this.formatDateTime,
    required this.isCompletedTicket,
  });

  final ServiceTicketRecord? ticket;
  final VoidCallback onRetry;
  final VoidCallback onViewHistory;
  final String Function(String raw) formatDateTime;
  final bool Function(ServiceTicketRecord ticket) isCompletedTicket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentTicket = ticket;
    if (currentTicket == null) {
      return ServiceRequestErrorStateCard(
        message: l10n.ticketDetailUnavailable,
        onRetry: onRetry,
      );
    }

    final completed = isCompletedTicket(currentTicket);

    return Column(
      children: [
        WhitePremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ServiceRequestSuccessIcon(
                icon: completed
                    ? Icons.check_rounded
                    : Icons.hourglass_bottom_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.requestCompleted,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: completed ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                completed
                    ? l10n.requestCompletedSubtitle
                    : l10n.workNotCompletedYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ServiceRequestDetailPanel(
                rows: [
                  (l10n.ticketNumber, currentTicket.ticketNumber),
                  (
                    l10n.status,
                    currentTicket.status.isEmpty ? '-' : currentTicket.status,
                  ),
                  (
                    l10n.assignedTo,
                    currentTicket.assignedTo.isEmpty
                        ? '-'
                        : currentTicket.assignedTo,
                  ),
                  (l10n.createdAt, formatDateTime(currentTicket.createdAt)),
                  (
                    l10n.completedAt,
                    currentTicket.completedAt.isEmpty
                        ? '-'
                        : formatDateTime(currentTicket.completedAt),
                  ),
                  (
                    l10n.slaState,
                    currentTicket.slaState.isEmpty
                        ? '-'
                        : currentTicket.slaState,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.timeline,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (currentTicket.timeline.isEmpty)
                ServiceRequestEmptyStateText(text: l10n.noTimelineUpdates)
              else
                for (final item in currentTicket.timeline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceRequestTimelineCard(item: item),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LuxuryButton(
          label: l10n.viewHistory,
          icon: Icons.history_outlined,
          onPressed: onViewHistory,
        ),
      ],
    );
  }
}
