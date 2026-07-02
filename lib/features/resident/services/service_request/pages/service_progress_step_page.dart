import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../../widgets/service_attachment_section.dart';
import '../../widgets/service_status_badge.dart';
import '../service_request_flow_controller.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceProgressRequestPage extends StatefulWidget {
  const ServiceProgressRequestPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<ServiceProgressRequestPage> createState() =>
      _ServiceProgressRequestPageState();
}

class _ServiceProgressRequestPageState
    extends State<ServiceProgressRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTicketLoaded());
  }

  @override
  void didUpdateWidget(ServiceProgressRequestPage oldWidget) {
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
          : ServiceProgressStepPage(
              ticket: ticket,
              onRetry: () => controller.fetchTicketDetail(widget.ticketId),
              onViewCompletion: () =>
                  context.push(ServiceRequestRoutes.completed(widget.ticketId)),
              onViewHistory: () => context.push(ServiceRequestRoutes.history),
              onPreviewAttachment: (attachment) =>
                  showServiceAttachmentPreview(context, attachment),
              formatDateTime: controller.formatDateTime,
              canShowCompletionAction: controller.canShowCompletionAction,
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
    final progressRoute = ServiceRequestRoutes.progress(widget.ticketId);
    if (route != progressRoute) {
      context.go(route);
    }
  }
}

class ServiceProgressStepPage extends StatelessWidget {
  const ServiceProgressStepPage({
    super.key,
    required this.ticket,
    required this.onRetry,
    required this.onViewCompletion,
    required this.onViewHistory,
    required this.onPreviewAttachment,
    required this.formatDateTime,
    required this.canShowCompletionAction,
  });

  final ServiceTicketRecord? ticket;
  final VoidCallback onRetry;
  final VoidCallback onViewCompletion;
  final VoidCallback onViewHistory;
  final ValueChanged<ServiceAttachment> onPreviewAttachment;
  final String Function(String raw) formatDateTime;
  final bool Function(ServiceTicketRecord ticket) canShowCompletionAction;

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

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceRequestCardTitle(
            title: l10n.workInProgress,
            subtitle: l10n.workInProgressSubtitle,
            icon: Icons.construction_outlined,
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
          ServiceRequestDetailPanel(
            rows: [
              (l10n.ticketNumber, currentTicket.ticketNumber),
              (
                l10n.status,
                currentTicket.status.isEmpty ? '-' : currentTicket.status,
              ),
              (l10n.category, currentTicket.category.displayLabel),
              (l10n.subcategory, currentTicket.subcategory.displayLabel),
              (
                l10n.priority,
                currentTicket.priority.isEmpty ? '-' : currentTicket.priority,
              ),
              (
                l10n.assignedTo,
                currentTicket.assignedTo.isEmpty
                    ? '-'
                    : currentTicket.assignedTo,
              ),
              (l10n.createdAt, formatDateTime(currentTicket.createdAt)),
              (
                l10n.operationalTime,
                currentTicket.operationalTimestamp.isEmpty
                    ? '-'
                    : formatDateTime(currentTicket.operationalTimestamp),
              ),
              (
                l10n.slaDue,
                currentTicket.slaDueAt.isEmpty
                    ? '-'
                    : formatDateTime(currentTicket.slaDueAt),
              ),
              (
                l10n.slaState,
                currentTicket.slaState.isEmpty ? '-' : currentTicket.slaState,
              ),
              (
                l10n.completedAt,
                currentTicket.completedAt.isEmpty
                    ? '-'
                    : formatDateTime(currentTicket.completedAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.attachments,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ServiceAttachmentSection(
            attachments: currentTicket.attachments,
            emptyMessage: l10n.noFileAttachments,
            onPreviewTap: onPreviewAttachment,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 18),
          if (canShowCompletionAction(currentTicket)) ...[
            LuxuryButton(
              label: l10n.viewCompletion,
              icon: Icons.check_circle_outline_rounded,
              onPressed: onViewCompletion,
            ),
            const SizedBox(height: 10),
          ] else ...[
            ServiceRequestProgressLockedNotice(
              message: l10n.completionPendingProgressLocked,
            ),
            const SizedBox(height: 10),
          ],
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
