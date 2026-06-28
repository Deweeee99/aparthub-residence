import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/facility_booking_dummy.dart';
import 'widgets/service_status_badge.dart';
import 'widgets/service_step_indicator.dart';

final _facilityDate = DateFormat('d MMM yyyy', 'id_ID');

class FacilityBookingPage extends StatefulWidget {
  const FacilityBookingPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<FacilityBookingPage> createState() => _FacilityBookingPageState();
}

class _FacilityBookingPageState extends State<FacilityBookingPage> {
  final _notesController = TextEditingController();
  late List<FacilityBookingRecord> _bookings = List.of(
    FacilityBookingDummy.seedBookings,
  );

  var _step = 0;
  var _facility = FacilityBookingDummy.facilities.first;
  var _slot = FacilityBookingDummy.slots.first.slot;
  var _guestCount = 2;
  var _bookingFilter = 'Upcoming';
  var _selectedDate = DateTime(2026, 6, 29);
  FacilityBookingRecord? _createdBooking;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step.clamp(0, 5));
  }

  void _handleBack() {
    if (_step == 0 || _step == 5) {
      widget.onBack();
      return;
    }

    _goToStep(_step - 1);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() => _selectedDate = picked);
  }

  void _confirmBooking() {
    final booking = FacilityBookingRecord(
      id: 'BK-${2400 + _bookings.length + 1}',
      facility: _facility.name,
      location: _facility.location,
      date: _selectedDate,
      slot: _slot,
      guestCount: _guestCount,
      status: 'Approved',
      notes: _notesController.text.trim(),
    );

    setState(() {
      _createdBooking = booking;
      _bookings = [booking, ..._bookings];
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('facility-booking-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        ServiceStepIndicator(
          currentStep: _step,
          steps: const [
            'Select',
            'Slots',
            'Schedule',
            'Confirm',
            'Approved',
            'Bookings',
          ],
          onStepSelected: _goToStep,
        ),
        const SizedBox(height: 16),
        _buildStep(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: _handleBack,
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
          'Facility Booking',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reserve residence facilities with the same simple service flow.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildSelectFacility(),
      1 => _buildAvailability(),
      2 => _buildSchedule(),
      3 => _buildConfirm(),
      4 => _buildApproved(),
      _ => _buildBookings(),
    };
  }

  Widget _buildSelectFacility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Select Facility',
          subtitle: 'Choose a residence facility and continue to availability.',
        ),
        const SizedBox(height: 14),
        for (final facility in FacilityBookingDummy.facilities) ...[
          _FacilityOptionCard(
            facility: facility,
            selected: facility.name == _facility.name,
            onTap: () {
              setState(() {
                _facility = facility;
                _step = 1;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectedFacilityCard(facility: _facility),
        const SizedBox(height: 14),
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                title: 'Available Time Slots',
                subtitle: 'Select an available slot for your facility booking.',
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: 14),
              for (final slot in FacilityBookingDummy.slots) ...[
                _SlotCard(
                  slot: slot,
                  selected: _slot == slot.slot,
                  onTap: slot.status == 'Available'
                      ? () => setState(() => _slot = slot.slot)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              LuxuryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _goToStep(2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedFacilityCard(facility: _facility),
          const SizedBox(height: 16),
          _DatePickerTile(date: _selectedDate, onTap: _pickDate),
          const SizedBox(height: 16),
          const _FieldLabel('Selected Time'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            items: FacilityBookingDummy.slots
                .where((item) => item.status == 'Available')
                .map((item) => item.slot)
                .toList(),
            selected: _slot,
            onSelected: (value) => setState(() => _slot = value),
          ),
          const SizedBox(height: 16),
          _GuestStepper(
            value: _guestCount,
            onMinus: _guestCount <= 1
                ? null
                : () => setState(() => _guestCount--),
            onPlus: _guestCount >= 8
                ? null
                : () => setState(() => _guestCount++),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes (Optional)'),
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _goToStep(3),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Confirm Booking',
            subtitle: 'Review the reservation details before submitting.',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 16),
          _DetailPanel(
            rows: [
              ('Facility', _facility.name),
              ('Location', _facility.location),
              ('Date', _facilityDate.format(_selectedDate)),
              ('Time', _slot),
              ('Guests', '$_guestCount person(s)'),
              (
                'Notes',
                _notesController.text.trim().isEmpty
                    ? '-'
                    : _notesController.text.trim(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InfoNotice(
            text:
                'Please arrive 10 minutes before booking time. Cancellation policy is simulated for this demo.',
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Confirm Booking',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _confirmBooking,
          ),
        ],
      ),
    );
  }

  Widget _buildApproved() {
    final booking = _createdBooking;

    return Column(
      children: [
        WhitePremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFEAF7EF),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Booking Confirmed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your facility reservation has been created locally for demo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _DetailPanel(
                rows: [
                  ('Reservation ID', booking?.id ?? '-'),
                  ('Status', booking?.status ?? 'Approved'),
                  ('Facility', booking?.facility ?? _facility.name),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _BookingQrCard(
          code: booking?.id ?? 'BK-DEMO',
          facility: booking?.facility ?? _facility.name,
          schedule:
              '${_facilityDate.format(booking?.date ?? _selectedDate)}, ${booking?.slot ?? _slot}',
        ),
        const SizedBox(height: 14),
        LuxuryButton(
          label: 'View Booking Details',
          icon: Icons.visibility_outlined,
          onPressed: () => _goToStep(5),
        ),
        const SizedBox(height: 10),
        LuxuryButton(
          label: 'Back to Home',
          icon: Icons.arrow_back_rounded,
          variant: LuxuryButtonVariant.secondary,
          onPressed: widget.onBack,
        ),
      ],
    );
  }

  Widget _buildBookings() {
    final today = DateTime.now();
    final items = _bookings.where((booking) {
      final bookingDate = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
      );
      final currentDate = DateTime(today.year, today.month, today.day);
      if (_bookingFilter == 'Past') {
        return bookingDate.isBefore(currentDate);
      }
      return !bookingDate.isBefore(currentDate);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                title: 'My Bookings',
                subtitle: 'View upcoming and past facility reservations.',
                icon: Icons.list_alt_outlined,
              ),
              const SizedBox(height: 16),
              _ChoiceWrap(
                items: FacilityBookingDummy.filters,
                selected: _bookingFilter,
                onSelected: (value) => setState(() => _bookingFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const WhitePremiumCard(child: Text('No bookings in this filter.'))
        else
          for (final booking in items) ...[
            _BookingCard(booking: booking),
            const SizedBox(height: 12),
          ],
        LuxuryButton(
          label: 'Back to Home',
          icon: Icons.arrow_back_rounded,
          onPressed: widget.onBack,
        ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FacilityOptionCard extends StatelessWidget {
  const _FacilityOptionCard({
    required this.facility,
    required this.selected,
    required this.onTap,
  });

  final FacilityOption facility;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? AppColors.goldSoft : AppColors.blueSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _facilityIcon(facility.name),
              color: selected ? AppColors.gold : AppColors.navy,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  facility.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${facility.location}  •  ${facility.capacity}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: selected ? AppColors.gold : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SelectedFacilityCard extends StatelessWidget {
  const _SelectedFacilityCard({required this.facility});

  final FacilityOption facility;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_facilityIcon(facility.name), color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  facility.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.success),
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
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(width: 10),
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final FacilitySlotOption slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = slot.status == 'Available';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldSoft : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                color: isAvailable ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slot.slot,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ServiceStatusBadge(status: slot.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('facility-date-picker'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Booking Date'),
                    const SizedBox(height: 4),
                    Text(
                      _facilityDate.format(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_rounded, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w800,
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
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item),
            selected: selected == item,
            onSelected: (_) => onSelected(item),
          ),
      ],
    );
  }
}

class _GuestStepper extends StatelessWidget {
  const _GuestStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_2_outlined, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$value guest(s)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _RoundCounterButton(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 8),
          _RoundCounterButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundCounterButton extends StatelessWidget {
  const _RoundCounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.navy,
        backgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.textMuted,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          height: 1.38,
        ),
      ),
    );
  }
}

class _BookingQrCard extends StatelessWidget {
  const _BookingQrCard({
    required this.code,
    required this.facility,
    required this.schedule,
  });

  final String code;
  final String facility;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Booking QR',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: QrImageView(
              data: code,
              size: 170,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            code,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$facility • $schedule',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final FacilityBookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(_facilityIcon(booking.facility), color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.facility,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_facilityDate.format(booking.date)} • ${booking.slot}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.id,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ServiceStatusBadge(status: booking.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _facilityIcon(String facility) {
  final value = facility.toLowerCase();
  if (value.contains('gym')) {
    return Icons.fitness_center_outlined;
  }
  if (value.contains('tennis')) {
    return Icons.sports_tennis_outlined;
  }
  if (value.contains('meeting')) {
    return Icons.meeting_room_outlined;
  }
  if (value.contains('hall')) {
    return Icons.celebration_outlined;
  }
  if (value.contains('lounge')) {
    return Icons.deck_outlined;
  }
  return Icons.event_available_outlined;
}
