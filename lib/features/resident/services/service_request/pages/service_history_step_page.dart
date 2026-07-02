import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../../widgets/service_attachment_section.dart';
import '../../widgets/service_status_badge.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../utils/service_request_helpers.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceHistoryRequestPage extends StatefulWidget {
  const ServiceHistoryRequestPage({super.key});

  @override
  State<ServiceHistoryRequestPage> createState() =>
      _ServiceHistoryRequestPageState();
}

class _ServiceHistoryRequestPageState extends State<ServiceHistoryRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ServiceRequestFlowScope.of(context);
      if (controller.tickets.isEmpty && !controller.isLoadingHistory) {
        controller.loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ServiceRequestFlowScope.of(context);

    return ServiceRequestScreenScaffold(
      onRefresh: controller.loadHistory,
      onBack: () => context.go(ServiceRequestRoutes.services),
      child: ServiceHistoryStepPage(
        isLoading: controller.isLoadingHistory,
        errorMessage: controller.errorMessage,
        tickets: controller.tickets,
        filteredTickets: controller.filteredTickets,
        historyFilters: controller.historyFilters,
        historyFilter: controller.historyFilter,
        onRetry: controller.loadHistory,
        onFilterChanged: controller.setHistoryFilter,
        onOpenTicketDetail: _openTicketDetail,
        onBackToServices: () => context.go(ServiceRequestRoutes.services),
        formatDateTime: controller.formatDateTime,
      ),
    );
  }

  Future<void> _openTicketDetail(ServiceTicketRecord ticket) async {
    final controller = ServiceRequestFlowScope.of(context);
    final detail = await controller.fetchTicketDetail(ticket.id);
    if (!mounted || detail == null) {
      _showServiceSnack(
        controller.errorMessage ?? 'Data layanan belum bisa dimuat. Coba lagi.',
      );
      return;
    }
    _showTicketDetailSheet(detail);
  }

  void _showTicketDetailSheet(ServiceTicketRecord ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final controller = ServiceRequestFlowScope.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: WhitePremiumCard(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ServiceRequestGoldIcon(
                          icon: serviceCategoryIcon(
                            ticket.category.displayLabel,
                          ),
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ServiceStatusBadge(status: ticket.status),
                                  ServiceRequestStaticPill(
                                    label: ticket.priority,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ticket.description.isEmpty ? '-' : ticket.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    ServiceRequestDetailPanel(
                      rows: [
                        (l10n.ticketNumber, ticket.ticketNumber),
                        (l10n.category, ticket.category.displayLabel),
                        (l10n.subcategory, ticket.subcategory.displayLabel),
                        (
                          l10n.assignedTo,
                          ticket.assignedTo.isEmpty ? '-' : ticket.assignedTo,
                        ),
                        (
                          l10n.createdAt,
                          controller.formatDateTime(ticket.createdAt),
                        ),
                        (
                          l10n.operationalTime,
                          ticket.operationalTimestamp.isEmpty
                              ? '-'
                              : controller.formatDateTime(
                                  ticket.operationalTimestamp,
                                ),
                        ),
                        (
                          l10n.slaDue,
                          ticket.slaDueAt.isEmpty
                              ? '-'
                              : controller.formatDateTime(ticket.slaDueAt),
                        ),
                        (
                          l10n.slaState,
                          ticket.slaState.isEmpty ? '-' : ticket.slaState,
                        ),
                        (
                          l10n.completedAt,
                          ticket.completedAt.isEmpty
                              ? '-'
                              : controller.formatDateTime(ticket.completedAt),
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
                      attachments: ticket.attachments,
                      onPreviewTap: (attachment) =>
                          showServiceAttachmentPreview(context, attachment),
                    ),
                    const SizedBox(height: 16),
                    LuxuryButton(
                      label: l10n.viewStatus,
                      icon: Icons.track_changes_outlined,
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.setTrackingTicket(ticket);
                        this.context.push(
                          controller.routeForServiceStatus(ticket),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    LuxuryButton(
                      label: l10n.close,
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showServiceSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ServiceHistoryStepPage extends StatelessWidget {
  const ServiceHistoryStepPage({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.tickets,
    required this.filteredTickets,
    required this.historyFilters,
    required this.historyFilter,
    required this.onRetry,
    required this.onFilterChanged,
    required this.onOpenTicketDetail,
    required this.onBackToServices,
    required this.formatDateTime,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<ServiceTicketRecord> tickets;
  final List<ServiceTicketRecord> filteredTickets;
  final List<String> historyFilters;
  final String historyFilter;
  final VoidCallback onRetry;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<ServiceTicketRecord> onOpenTicketDetail;
  final VoidCallback onBackToServices;
  final String Function(String raw) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return ServiceRequestLoadingStateCard(
        message: l10n.loadingServiceHistory,
      );
    }

    if (tickets.isEmpty && errorMessage != null) {
      return ServiceRequestErrorStateCard(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceRequestCardTitle(
                title: l10n.serviceHistory,
                subtitle: l10n.serviceHistoryCardSubtitle,
                icon: Icons.history_outlined,
              ),
              const SizedBox(height: 16),
              ServiceRequestChoiceWrap(
                items: historyFilters,
                selected: historyFilter,
                onSelected: onFilterChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filteredTickets.isEmpty)
          WhitePremiumCard(
            child: ServiceRequestEmptyStateText(
              text: l10n.noServiceRequestsFound,
            ),
          ),
        for (final ticket in filteredTickets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhitePremiumCard(
              onTap: () => onOpenTicketDetail(ticket),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceRequestGoldIcon(
                    icon: serviceCategoryIcon(ticket.category.displayLabel),
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticket.ticketNumber} - ${ticket.title}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.category.displayLabel} • ${ticket.subcategory.displayLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.priority} • ${ticket.slaState.isEmpty ? l10n.slaNotAvailable : ticket.slaState}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatDateTime(ticket.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.assignedTo}: ${ticket.assignedTo.isEmpty ? '-' : ticket.assignedTo}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ServiceStatusBadge(status: ticket.status),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: onBackToServices,
          child: Text(l10n.backToServices),
        ),
      ],
    );
  }
}
