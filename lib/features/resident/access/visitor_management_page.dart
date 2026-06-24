import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/visitor_access_dummy.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/visitor_qr_card.dart';
import 'widgets/visitor_status_badge.dart';
import 'widgets/visitor_step_indicator.dart';

enum VisitorManagementInitialMode { create, history }

class VisitorManagementPage extends StatefulWidget {
  const VisitorManagementPage({
    super.key,
    required this.onBack,
    required this.initialMode,
  });

  final VoidCallback onBack;
  final VisitorManagementInitialMode initialMode;

  @override
  State<VisitorManagementPage> createState() => _VisitorManagementPageState();
}

class _VisitorManagementPageState extends State<VisitorManagementPage> {
  static const _steps = [
    'Register',
    'Schedule',
    'Pass',
    'Share',
    'Verify',
    'Check-In',
    'History',
  ];

  final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleController;
  late final List<VisitorAccessRecord> _visitorHistory;

  late int _visitorStep;
  var _visitorName = VisitorAccessDummy.defaultVisitorName;
  var _phone = VisitorAccessDummy.defaultPhone;
  var _purpose = VisitorAccessDummy.defaultPurpose;
  var _visitTime = VisitorAccessDummy.defaultVisitTime;
  var _duration = VisitorAccessDummy.defaultDuration;
  var _visitorCount = 1;
  var _vehicleNumber = VisitorAccessDummy.defaultVehicleNumber;
  var _visitorPassCode = VisitorAccessDummy.defaultPassCode;
  var _historyFilter = 'All';
  var _isVerifying = false;
  var _hasSavedCheckIn = false;

  @override
  void initState() {
    super.initState();
    _visitorStep = widget.initialMode == VisitorManagementInitialMode.history
        ? _steps.length - 1
        : 0;
    _nameController = TextEditingController(text: _visitorName);
    _phoneController = TextEditingController(text: _phone);
    _vehicleController = TextEditingController(text: _vehicleNumber);
    _visitorHistory = List.of(VisitorAccessDummy.seedHistory);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  List<VisitorAccessRecord> get _filteredHistory {
    final now = DateTime(2026, 6, 8, 12);
    return _visitorHistory.where((record) {
      return switch (_historyFilter) {
        'Upcoming' => record.dateTime.isAfter(now),
        'Past' => record.dateTime.isBefore(now),
        'Checked In' => record.status == 'Checked In',
        'Checked Out' => record.status == 'Checked Out',
        _ => true,
      };
    }).toList();
  }

  void _goToStep(int step) {
    final target = step.clamp(0, _steps.length - 1);
    setState(() => _visitorStep = target);
    if (target == 4) {
      _startVerification();
    }
  }

  void _nextStep() => _goToStep(_visitorStep + 1);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveRegistration() {
    setState(() {
      _visitorName = _nameController.text.trim().isEmpty
          ? VisitorAccessDummy.defaultVisitorName
          : _nameController.text.trim();
      _phone = _phoneController.text.trim().isEmpty
          ? VisitorAccessDummy.defaultPhone
          : _phoneController.text.trim();
      _vehicleNumber = _vehicleController.text.trim().isEmpty
          ? '-'
          : _vehicleController.text.trim();
    });
    _nextStep();
  }

  void _generatePassCode() {
    final nextNumber = (_visitorHistory.length + 126).toString().padLeft(
      5,
      '0',
    );
    setState(() => _visitorPassCode = 'VST-2026-$nextNumber');
  }

  void _startVerification() {
    setState(() => _isVerifying = true);
    unawaited(
      Future<void>.delayed(const Duration(seconds: 1), () {
        if (!mounted || _visitorStep != 4) {
          return;
        }
        setState(() => _isVerifying = false);
      }),
    );
  }

  void _completeCheckIn() {
    if (!_hasSavedCheckIn) {
      final parts = _visitTime.split(':');
      final visitDateTime = DateTime(
        2026,
        6,
        8,
        int.parse(parts.first),
        int.parse(parts.last),
      );
      setState(() {
        _visitorHistory.insert(
          0,
          VisitorAccessRecord(
            visitorName: _visitorName,
            purpose: _purpose,
            dateTime: visitDateTime.add(const Duration(minutes: 3)),
            passCode: _visitorPassCode,
            status: 'Checked In',
            vehicleNumber: _vehicleNumber,
          ),
        );
        _hasSavedCheckIn = true;
      });
    }
    _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.registerVisitor,
      l10n.scheduleVisit,
      'Pass',
      'Share',
      'Verify',
      'Check-In',
      l10n.visitorHistory,
    ];

    return ColoredBox(
      color: Colors.transparent,
      child: ListView(
        key: const ValueKey('visitor-management-page'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
        children: [
          _buildTopBar(context),
          const SizedBox(height: 18),
          VisitorStepIndicator(
            currentStep: _visitorStep,
            steps: steps,
            onStepSelected: _goToStep,
          ),
          const SizedBox(height: 18),
          _buildStepBody(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n.back,
          onPressed: _visitorStep == 0 || _visitorStep == 6
              ? widget.onBack
              : () => _goToStep(_visitorStep - 1),
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
          l10n.visitorManagement,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure visitor registration and digital access for your unit.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }

  Widget _buildStepBody(BuildContext context) {
    return switch (_visitorStep) {
      0 => _buildRegisterStep(context),
      1 => _buildScheduleStep(context),
      2 => _buildPassStep(context),
      3 => _buildShareStep(context),
      4 => _buildVerifyStep(context),
      5 => _buildCheckInStep(context),
      _ => _buildHistoryStep(context),
    };
  }

  Widget _buildRegisterStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: l10n.registerVisitor,
            subtitle: 'Create a secure visitor profile before arrival.',
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: l10n.visitorName,
            child: _PremiumTextField(
              key: const ValueKey('visitor-name-field'),
              controller: _nameController,
              hintText: l10n.visitorFullName,
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: l10n.mobileNumber,
            child: _PremiumTextField(
              controller: _phoneController,
              hintText: '+62 812-3456-7890',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: l10n.purposeOfVisit,
            child: _ChoiceWrap<String>(
              options: VisitorAccessDummy.purposeOptions,
              selected: _purpose,
              onSelected: (value) => setState(() => _purpose = value),
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: l10n.numberOfVisitors,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups_2_outlined, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_visitorCount visitor${_visitorCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _visitorCount > 1
                        ? () => setState(() => _visitorCount -= 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  IconButton(
                    onPressed: _visitorCount < 6
                        ? () => setState(() => _visitorCount += 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: l10n.vehicleNumberOptional,
            child: _PremiumTextField(
              controller: _vehicleController,
              hintText: 'B 1234 ABC',
              icon: Icons.directions_car_outlined,
            ),
          ),
          const SizedBox(height: 22),
          LuxuryButton(label: l10n.next, onPressed: _saveRegistration),
        ],
      ),
    );
  }

  Widget _buildScheduleStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: l10n.scheduleVisit,
            subtitle: 'Choose visit date, time, and expected duration.',
          ),
          const SizedBox(height: 18),
          const _CalendarCard(selectedDay: 8),
          const SizedBox(height: 18),
          _LabeledField(
            label: l10n.visitTime,
            child: _ChoiceWrap<String>(
              options: VisitorAccessDummy.timeOptions,
              selected: _visitTime,
              onSelected: (value) => setState(() => _visitTime = value),
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: l10n.expectedDuration,
            child: _ChoiceWrap<String>(
              options: VisitorAccessDummy.durationOptions,
              selected: _duration,
              onSelected: (value) => setState(() => _duration = value),
            ),
          ),
          const SizedBox(height: 20),
          LuxuryButton(
            label: l10n.confirm,
            onPressed: () {
              _generatePassCode();
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPassStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        VisitorQrCard(
          title: l10n.passGenerated,
          code: _visitorPassCode,
          visitorName: _visitorName,
          schedule: '${VisitorAccessDummy.visitDateLabel}, $_visitTime',
          status: 'Ready to Share',
          countdownText: 'Valid until 16:00',
        ),
        const SizedBox(height: 14),
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: l10n.visitorId, value: _visitorPassCode),
              _InfoRow(label: l10n.purposeOfVisit, value: _purpose),
              _InfoRow(label: l10n.unit, value: VisitorAccessDummy.unitLabel),
              _InfoRow(label: l10n.vehicleNumber, value: _vehicleNumber),
              _InfoRow(label: l10n.duration, value: _duration),
              const Divider(height: 26),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This pass is valid only for the above time and unit.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LuxuryButton(
                label: l10n.shareVisitorPass,
                icon: Icons.ios_share_outlined,
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: l10n.shareVisitorPass,
            subtitle: 'Share visitor pass with your guest.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 34,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _visitorPassCode,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated for $_visitorName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const VisitorStatusBadge(status: 'Generated'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final item in const [
            ('WhatsApp', Icons.chat_bubble_outline_rounded),
            ('SMS', Icons.sms_outlined),
            ('Email', Icons.mail_outline_rounded),
            ('Copy Link', Icons.link_rounded),
            ('More Options', Icons.more_horiz_rounded),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShareOptionTile(
                label: item.$1,
                icon: item.$2,
                onTap: () => _showSnackBar(
                  item.$1 == 'Copy Link'
                      ? 'Visitor pass link copied'
                      : 'Visitor pass shared via ${item.$1}',
                ),
              ),
            ),
          const SizedBox(height: 10),
          LuxuryButton(
            label: l10n.continueToVerification,
            onPressed: () => _goToStep(4),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isVerifying
            ? SizedBox(
                key: const ValueKey('visitor-verifying'),
                height: 320,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.gold),
                      const SizedBox(height: 18),
                      Text(
                        'Scanning visitor pass...',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                key: const ValueKey('visitor-verified'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFEAF7EF),
                      child: Icon(
                        Icons.shield_rounded,
                        size: 42,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'QR Verified',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Visitor is verified successfully.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _InfoRow(label: l10n.visitorName, value: _visitorName),
                  _InfoRow(label: l10n.visitorId, value: _visitorPassCode),
                  _InfoRow(
                    label: l10n.unit,
                    value: VisitorAccessDummy.unitLabel,
                  ),
                  const _InfoRow(
                    label: 'Valid Until',
                    value: '08 Jun 2026, 16:00',
                  ),
                  _InfoRow(label: l10n.purposeOfVisit, value: _purpose),
                  const SizedBox(height: 16),
                  LuxuryButton(
                    label: l10n.accessApproved,
                    onPressed: _nextStep,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckInStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFEAF7EF),
            child: Icon(
              Icons.domain_verification_rounded,
              size: 42,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.checkInSuccessful,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.visitorEnteredResidence,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                _InfoRow(label: l10n.visitorName, value: _visitorName),
                _InfoRow(label: l10n.checkInTime, value: '08 Jun 2026, 14:03'),
                _InfoRow(label: l10n.unit, value: VisitorAccessDummy.unitLabel),
                _InfoRow(label: l10n.vehicleNumber, value: _vehicleNumber),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LuxuryButton(label: l10n.done, onPressed: _completeCheckIn),
        ],
      ),
    );
  }

  Widget _buildHistoryStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _filteredHistory;
    return Column(
      children: [
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                title: l10n.visitorHistory,
                subtitle: l10n.trackVisitorActivity,
              ),
              const SizedBox(height: 16),
              _ChoiceWrap<String>(
                options: VisitorAccessDummy.historyFilters,
                selected: _historyFilter,
                onSelected: (value) => setState(() => _historyFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final record in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhitePremiumCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.14),
                    child: Text(
                      _initials(record.visitorName),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.visitorName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(record.purpose),
                        const SizedBox(height: 8),
                        Text(
                          _dateTimeFormat.format(record.dateTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.vehicle}: ${record.vehicleNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  VisitorStatusBadge(status: record.status),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showSnackBar(l10n.visitorHistoryDownloaded),
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.downloadHistory),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: widget.onBack, child: Text(l10n.backToAccessHub)),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.gold),
        fillColor: AppColors.surfaceElevated,
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = option == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.goldSoft : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.borderSoft,
              ),
            ),
            child: Text(
              '$option',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppColors.navy : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.selectedDay});

  final int selectedDay;

  @override
  Widget build(BuildContext context) {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const days = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'June 2026',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_left_rounded, color: AppColors.navy),
              const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: [
              for (final day in weekDays)
                Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              for (final day in days)
                Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: day == selectedDay
                          ? AppColors.navy
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: day == selectedDay
                          ? null
                          : Border.all(color: AppColors.borderSoft),
                    ),
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: day == selectedDay
                            ? Colors.white
                            : AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
