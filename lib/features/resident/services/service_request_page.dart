import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/service_request_dummy.dart';
import 'widgets/service_status_badge.dart';
import 'widgets/service_step_indicator.dart';

enum ServiceRequestInitialMode { create, history }

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({
    super.key,
    required this.onBack,
    required this.initialMode,
  });

  final VoidCallback onBack;
  final ServiceRequestInitialMode initialMode;

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _commentController;
  late List<ServiceTicketRecord> _tickets;

  late int _serviceStep;
  var _category = ServiceRequestDummy.defaultCategory;
  var _priority = ServiceRequestDummy.defaultPriority;
  var _historyFilter = 'All';
  var _rating = 5;
  var _isSubmitting = false;
  ServiceTicketRecord? _createdTicket;

  @override
  void initState() {
    super.initState();
    _serviceStep = widget.initialMode == ServiceRequestInitialMode.history
        ? ServiceRequestDummy.steps.length - 1
        : 0;
    _titleController = TextEditingController(
      text: ServiceRequestDummy.defaultTitle,
    );
    _descriptionController = TextEditingController(
      text: ServiceRequestDummy.defaultDescription,
    );
    _commentController = TextEditingController(
      text: ServiceRequestDummy.defaultComment,
    );
    _tickets = List.of(ServiceRequestDummy.seedTickets);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  List<ServiceTicketRecord> get _filteredTickets {
    return _tickets.where((ticket) {
      return _historyFilter == 'All' || ticket.status == _historyFilter;
    }).toList();
  }

  ServiceTicketRecord get _activeTicket => _createdTicket ?? _tickets.first;

  void _goToStep(int step) {
    setState(
      () => _serviceStep = step.clamp(0, ServiceRequestDummy.steps.length - 1),
    );
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    final ticket = ServiceTicketRecord(
      id: 'SR-${2400 + _tickets.length + 1}',
      category: _category,
      title: _titleController.text.trim().isEmpty
          ? ServiceRequestDummy.defaultTitle
          : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? ServiceRequestDummy.defaultDescription
          : _descriptionController.text.trim(),
      priority: _priority,
      status: 'Open',
      assignee: 'Waiting assignment',
      createdAt: DateTime(2026, 6, 22, 10, 0),
    );
    setState(() {
      _tickets = [ticket, ..._tickets];
      _createdTicket = ticket;
      _isSubmitting = false;
      _serviceStep = 2;
    });
  }

  void _showServiceSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submitRating() {
    _showServiceSnack('Thank you for your feedback.');
    _goToStep(7);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('service-request-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        ServiceStepIndicator(
          currentStep: _serviceStep,
          steps: ServiceRequestDummy.steps,
          onStepSelected: _goToStep,
        ),
        const SizedBox(height: 16),
        _buildStepContent(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: _serviceStep == 0 || _serviceStep == 7
              ? widget.onBack
              : () => _goToStep(_serviceStep - 1),
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
          'Service Request',
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

  Widget _buildStepContent() {
    return switch (_serviceStep) {
      0 => _buildCreateRequest(),
      1 => _buildDescribeIssue(),
      2 => _buildRequestSubmitted(),
      3 => _buildAssignedToStaff(),
      4 => _buildWorkInProgress(),
      5 => _buildCompleted(),
      6 => _buildRateService(),
      _ => _buildTicketHistory(),
    };
  }

  Widget _buildCreateRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of service do you need?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in ServiceRequestDummy.categories)
          _ServiceCategoryCard(
            title: option.title,
            subtitle: option.subtitle,
            icon: _categoryIcon(option.title),
            selected: _category == option.title,
            onTap: () {
              setState(() {
                _category = option.title;
                _serviceStep = 1;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDescribeIssue() {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Describe Issue',
            subtitle: 'Provide issue details and supporting photos.',
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('service-title-field'),
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Problem title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Problem description'),
          ),
          const SizedBox(height: 14),
          const _PhotoUploadRow(),
          const SizedBox(height: 14),
          _ChoiceWrap(
            items: ServiceRequestDummy.priorities,
            selected: _priority,
            onSelected: (value) => setState(() => _priority = value),
          ),
          const SizedBox(height: 14),
          const _InfoPanel(
            icon: Icons.calendar_month_outlined,
            title: 'Preferred Schedule',
            subtitle: '22 Jun 2026 - 10:00 AM - 12:00 PM',
            status: 'Open',
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: _isSubmitting ? 'Submitting...' : 'Submit Request',
            icon: Icons.send_outlined,
            onPressed: () {
              unawaited(_submitRequest());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSubmitted() {
    final ticket = _activeTicket;
    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SuccessIcon(icon: Icons.send_outlined),
          const SizedBox(height: 18),
          Text(
            'Ticket Created!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your service request has been submitted successfully.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _DetailPanel(
            rows: [
              ('Ticket Number', ticket.id),
              ('Status', ticket.status),
              ('Category', ticket.category),
            ],
          ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: 'View Details',
            icon: Icons.visibility_outlined,
            onPressed: () => _goToStep(3),
          ),
          const SizedBox(height: 10),
          _OutlineActionButton(
            label: 'Back to Services',
            icon: Icons.arrow_back_outlined,
            onPressed: widget.onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedToStaff() {
    return Column(
      children: [
        WhitePremiumCard(
          child: Column(
            children: [
              const _CardTitle(
                title: 'Assigned to Staff',
                subtitle: 'Your request has been assigned to a technician.',
                icon: Icons.engineering_outlined,
              ),
              const SizedBox(height: 18),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.goldSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.gold,
                  size: 52,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                ServiceRequestDummy.technicianName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ServiceRequestDummy.technicianRole,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                ServiceRequestDummy.technicianRating,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const _InfoPanel(
                icon: Icons.timer_outlined,
                title: 'Estimated Arrival Time',
                subtitle: '30 - 45 Minutes',
                status: 'Assigned',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _OutlineActionButton(
          label: 'Contact Technician',
          icon: Icons.phone_outlined,
          onPressed: () => _showServiceSnack('Contact technician simulated.'),
        ),
        const SizedBox(height: 10),
        LuxuryButton(
          label: 'Track Progress',
          icon: Icons.route_outlined,
          onPressed: () => _goToStep(4),
        ),
      ],
    );
  }

  Widget _buildWorkInProgress() {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Work In Progress',
            subtitle: 'Technician is working on your request.',
            icon: Icons.construction_outlined,
          ),
          const SizedBox(height: 16),
          const _InfoPanel(
            icon: Icons.engineering_outlined,
            title: 'Technician on Site',
            subtitle: '10:15 AM',
            status: 'Progress',
          ),
          const SizedBox(height: 16),
          const _ProgressTimeline(activeIndex: 1),
          const SizedBox(height: 16),
          Container(
            height: 126,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Center(
              child: Icon(Icons.location_pin, color: AppColors.gold, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Mark as Completed',
            icon: Icons.check_circle_outline,
            onPressed: () => _goToStep(5),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted() {
    return WhitePremiumCard(
      child: Column(
        children: [
          const _SuccessIcon(icon: Icons.check_rounded),
          const SizedBox(height: 18),
          Text(
            'Request Completed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The issue has been resolved successfully.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _BeforeAfterBox(label: 'Before')),
              SizedBox(width: 10),
              Expanded(child: _BeforeAfterBox(label: 'After')),
            ],
          ),
          const SizedBox(height: 18),
          const _DetailPanel(
            rows: [
              ('Completed By', ServiceRequestDummy.technicianName),
              ('Completed At', '22 Jun 2026, 11:25 AM'),
              ('Note', 'Leakage issue has been fixed and tested successfully.'),
            ],
          ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: 'Close Request',
            icon: Icons.star_outline,
            onPressed: () => _goToStep(6),
          ),
        ],
      ),
    );
  }

  Widget _buildRateService() {
    return WhitePremiumCard(
      child: Column(
        children: [
          const _CardTitle(
            title: 'Rate Service',
            subtitle: 'How was your experience with our service?',
            icon: Icons.star_outline,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: 30,
                  ),
                ),
            ],
          ),
          Text(
            _rating >= 5 ? 'Excellent!' : 'Thank you!',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            minLines: 4,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Add comment'),
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Submit Rating',
            icon: Icons.send_outlined,
            onPressed: _submitRating,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHistory() {
    final tickets = _filteredTickets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                title: 'Service History',
                subtitle: 'Review every service request and its progress.',
                icon: Icons.history_outlined,
              ),
              const SizedBox(height: 16),
              _ChoiceWrap(
                items: ServiceRequestDummy.historyFilters,
                selected: _historyFilter,
                onSelected: (value) => setState(() => _historyFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final ticket in tickets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhitePremiumCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoldIcon(icon: _categoryIcon(ticket.category), size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticket.id} - ${ticket.title}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text('${ticket.category} - ${ticket.priority}'),
                        const SizedBox(height: 8),
                        Text(
                          _dateTimeFormat.format(ticket.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assignee: ${ticket.assignee}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ServiceStatusBadge(status: ticket.status),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: widget.onBack,
          child: const Text('Back to Services'),
        ),
      ],
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  const _ServiceCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          _GoldIcon(icon: icon, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.chevron_right,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoldIcon(icon: icon, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoUploadRow extends StatelessWidget {
  const _PhotoUploadRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.gold.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: const Icon(Icons.add, color: AppColors.gold),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    const steps = ['Inspection', 'Repairing', 'Quality Check', 'Completed'];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    i <= activeIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i <= activeIndex
                        ? AppColors.gold
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  if (i != steps.length - 1)
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.borderSoft,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    steps[i],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: i == activeIndex
                          ? AppColors.navy
                          : AppColors.textMuted,
                      fontWeight: i == activeIndex
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BeforeAfterBox extends StatelessWidget {
  const _BeforeAfterBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
            if (i != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _GoldIcon(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ServiceStatusBadge(status: status),
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _PillChoice(
            label: item,
            selected: selected == item,
            onTap: () => onSelected(item),
          ),
      ],
    );
  }
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.goldSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.55)
              : AppColors.borderSoft,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.navy : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.34)),
      ),
      child: Icon(icon, color: AppColors.success, size: 52),
    );
  }
}

class _GoldIcon extends StatelessWidget {
  const _GoldIcon({required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: AppColors.gold, size: size * 0.54),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Plumbing' => Icons.plumbing_outlined,
    'Electrical' => Icons.bolt_outlined,
    'Air Conditioning' => Icons.ac_unit_outlined,
    'Housekeeping' => Icons.cleaning_services_outlined,
    'Internet / Wi-Fi' => Icons.wifi_outlined,
    _ => Icons.handyman_outlined,
  };
}
