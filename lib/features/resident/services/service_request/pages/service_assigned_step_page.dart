import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../../widgets/service_status_badge.dart';
import '../service_request_flow_controller.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceAssignedRequestPage extends StatefulWidget {
  const ServiceAssignedRequestPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<ServiceAssignedRequestPage> createState() =>
      _ServiceAssignedRequestPageState();
}

class _ServiceAssignedRequestPageState
    extends State<ServiceAssignedRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTicketLoaded());
  }

  @override
  void didUpdateWidget(ServiceAssignedRequestPage oldWidget) {
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
      onRefresh: () => _refreshAndRedirect(controller),
      child: controller.isLoadingTicketDetail && ticket == null
          ? ServiceRequestLoadingStateCard(
              message: AppLocalizations.of(context).loadingServiceHistory,
            )
          : ServiceAssignedStepPage(
              ticket: ticket,
              onRetry: () => controller.fetchTicketDetail(widget.ticketId),
              onTrackProgress: () =>
                  context.push(ServiceRequestRoutes.progress(widget.ticketId)),
              onViewHistory: () => context.push(ServiceRequestRoutes.history),
              formatDateTime: controller.formatDateTime,
              hasAssignedStaff: controller.hasAssignedStaff,
            ),
    );
  }

  Future<void> _ensureTicketLoaded() async {
    final controller = ServiceRequestFlowScope.of(context);
    if (controller.activeTicket?.id == widget.ticketId ||
        controller.isLoadingTicketDetail) {
      return;
    }
    await _refreshAndRedirect(controller);
  }

  Future<void> _refreshAndRedirect(
    ServiceRequestFlowController controller,
  ) async {
    final detail = await controller.fetchTicketDetail(widget.ticketId);
    if (!mounted || detail == null) {
      return;
    }
    final route = controller.routeForServiceStatus(detail);
    final assignedRoute = ServiceRequestRoutes.assigned(widget.ticketId);
    if (route != assignedRoute) {
      context.go(route);
    }
  }
}

class ServiceAssignedStepPage extends StatelessWidget {
  const ServiceAssignedStepPage({
    super.key,
    required this.ticket,
    required this.onRetry,
    required this.onTrackProgress,
    required this.onViewHistory,
    required this.formatDateTime,
    required this.hasAssignedStaff,
  });

  final ServiceTicketRecord? ticket;
  final VoidCallback onRetry;
  final VoidCallback onTrackProgress;
  final VoidCallback onViewHistory;
  final String Function(String raw) formatDateTime;
  final bool Function(ServiceTicketRecord ticket) hasAssignedStaff;

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

    final assignedName = currentTicket.assignedTo.trim();

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceRequestCardTitle(
            title: l10n.assignedToStaff,
            subtitle: l10n.assignedToStaffSubtitle,
            icon: Icons.engineering_outlined,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  currentTicket.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ServiceStatusBadge(status: currentTicket.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentTicket.description.isEmpty ? '-' : currentTicket.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          ServiceRequestInfoPanel(
            icon: Icons.engineering_outlined,
            title: assignedName.isEmpty
                ? l10n.waitingForAssignment
                : assignedName,
            subtitle: assignedName.isEmpty
                ? l10n.assignedAfterActivation
                : l10n.technicianStaff,
            status: currentTicket.status.isEmpty
                ? l10n.status
                : currentTicket.status,
          ),
          const SizedBox(height: 8),
          ServiceRequestDetailPanel(
            rows: [
              (l10n.ticketNumber, currentTicket.ticketNumber),
              (
                l10n.status,
                currentTicket.status.isEmpty ? '-' : currentTicket.status,
              ),
              (l10n.category, currentTicket.category.displayLabel),
              (l10n.subcategory, currentTicket.subcategory.displayLabel),
              (l10n.unit, currentTicket.unit.displayLabel),
              (
                l10n.priority,
                currentTicket.priority.isEmpty ? '-' : currentTicket.priority,
              ),
              (l10n.createdAt, formatDateTime(currentTicket.createdAt)),
              (
                l10n.operationalTime,
                currentTicket.operationalTimestamp.isEmpty
                    ? '-'
                    : formatDateTime(currentTicket.operationalTimestamp),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasAssignedStaff(currentTicket))
            LuxuryButton(
              label: l10n.trackProgress,
              icon: Icons.route_outlined,
              onPressed: onTrackProgress,
            )
          else
            ServiceRequestProgressLockedNotice(
              message: l10n.assignmentPendingProgressLocked,
            ),
          const SizedBox(height: 10),
          ServiceRequestOutlineActionButton(
            label: l10n.viewHistory,
            icon: Icons.history_outlined,
            onPressed: onViewHistory,
          ),
        ],
      ),
    );
  }
}
