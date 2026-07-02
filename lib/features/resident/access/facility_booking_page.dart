import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/facility_booking_dummy.dart' as booking_dummy;
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/facility_booking_models.dart';
import '../../../services/api_service.dart';
import '../services/widgets/service_status_badge.dart';
import '../services/widgets/service_step_indicator.dart';

final _facilityDate = DateFormat('d MMM yyyy', 'id_ID');
final _facilityTimeOptions = List<String>.generate(22, (index) {
  final minutes = (7 * 60) + (index * 30);
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
});

class FacilityBookingPage extends StatefulWidget {
  const FacilityBookingPage({super.key, required this.onBack, this.apiService});

  final VoidCallback onBack;
  final ApiService? apiService;

  @override
  State<FacilityBookingPage> createState() => _FacilityBookingPageState();
}

class _FacilityBookingPageState extends State<FacilityBookingPage> {
  final _notesController = TextEditingController();
  late final ApiService _apiService = widget.apiService ?? ApiService();
  List<FacilityBookingRecord> _bookings = const [];
  List<ResidentFacility> _facilities = const [];

  var _step = 0;
  ResidentFacility? _facility;
  String? _startTime;
  String? _endTime;
  var _guestCount = 2;
  var _bookingFilter = 'Upcoming';
  var _selectedDate = DateTime.now();
  var _isLoadingFacilities = false;
  var _isLoadingAvailability = false;
  var _isLoadingBookings = false;
  var _isSubmitting = false;
  String? _facilityErrorMessage;
  String? _bookingErrorMessage;
  ResidentFacilityAvailability? _availability;
  FacilityBookingRecord? _createdBooking;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step.clamp(0, 4));
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadFacilities(), _loadBookings()]);
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoadingFacilities = true;
      _facilityErrorMessage = null;
    });

    try {
      final facilities = await _apiService.getResidentFacilities();
      if (!mounted) {
        return;
      }
      setState(() {
        _facilities = facilities;
        _isLoadingFacilities = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFacilities = false;
        _facilityErrorMessage = error is ApiServiceException
            ? error.message
            : 'Data fasilitas belum bisa dimuat. Coba lagi.';
      });
    }
  }

  Future<void> _loadAvailability() async {
    final facility = _facility;
    if (facility == null) {
      return;
    }

    setState(() => _isLoadingAvailability = true);
    try {
      final availability = await _apiService.getResidentFacilityAvailability(
        facilityId: facility.id,
        bookingDate: _formatApiDate(_selectedDate),
        timeSlot: _startTime,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _availability = availability;
        _isLoadingAvailability = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingAvailability = false);
      _showBookingSnack(
        error is ApiServiceException
            ? error.message
            : 'Ketersediaan fasilitas belum bisa dimuat. Coba lagi.',
      );
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoadingBookings = true;
      _bookingErrorMessage = null;
    });

    try {
      final bookings = await _apiService.getResidentFacilityBookings();
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = bookings;
        _isLoadingBookings = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBookings = false;
        _bookingErrorMessage = error is ApiServiceException
            ? error.message
            : 'Data booking fasilitas belum bisa dimuat. Coba lagi.';
      });
    }
  }

  void _handleBack() {
    if (_step == 0 || _step == 4) {
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
    await _loadAvailability();
  }

  void _selectStartTime(String? value) {
    setState(() {
      _startTime = value;
      if (!_isEndAfterStart(_endTime)) {
        _endTime = null;
      }
      _availability = null;
    });
    if (value != null) {
      _loadAvailability();
    }
  }

  void _selectEndTime(String? value) {
    setState(() => _endTime = value);
  }

  void _continueToConfirm() {
    if (_startTime == null || _endTime == null) {
      _showBookingSnack('Pilih jam mulai dan jam selesai terlebih dahulu.');
      return;
    }
    if (!_isScheduleAvailable) {
      _showBookingSnack('Jadwal belum tersedia untuk fasilitas ini.');
      return;
    }
    _goToStep(2);
  }

  Future<void> _confirmBooking() async {
    final facility = _facility;
    if (facility == null) {
      _showBookingSnack('Pilih fasilitas terlebih dahulu.');
      return;
    }

    if (_startTime == null || _endTime == null) {
      _showBookingSnack('Pilih jam mulai dan jam selesai terlebih dahulu.');
      return;
    }

    if (!_isScheduleAvailable) {
      _showBookingSnack('Jadwal belum tersedia untuk fasilitas ini.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final booking = await _apiService.createResidentFacilityBooking(
        facilityId: facility.id,
        bookingTitle: '${facility.name} Reservation',
        bookingDate: _formatApiDate(_selectedDate),
        timeSlot: _timeRange,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _createdBooking = _mergeBookingForDisplay(booking);
        _isSubmitting = false;
        _step = 3;
      });
      await _loadBookings();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showBookingSnack(
        error is ApiServiceException
            ? error.message
            : 'Facility booking belum bisa dibuat. Coba lagi.',
      );
    }
  }

  void _showBookingSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDisplayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '-' : raw;
    }
    return _facilityDate.format(parsed);
  }

  String get _timeRange {
    final start = _startTime;
    final end = _endTime;
    if (start == null || end == null) {
      return '-';
    }
    return '$start - $end';
  }

  List<String> get _endTimeOptions {
    final start = _startTime;
    if (start == null) {
      return const [];
    }
    final startIndex = _facilityTimeOptions.indexOf(start);
    if (startIndex < 0 || startIndex >= _facilityTimeOptions.length - 1) {
      return const [];
    }
    return _facilityTimeOptions.sublist(startIndex + 1);
  }

  bool _isEndAfterStart(String? endTime) {
    final start = _startTime;
    if (start == null || endTime == null) {
      return false;
    }
    return _facilityTimeOptions.indexOf(endTime) >
        _facilityTimeOptions.indexOf(start);
  }

  bool get _isScheduleAvailable {
    final facility = _facility;
    if (facility == null || !facility.canBook) {
      return false;
    }
    final availability = _availability;
    if (availability == null || _startTime == null || _endTime == null) {
      return false;
    }
    if (!availability.facilityCanBook || availability.isAvailable == false) {
      return false;
    }
    if (availability.isSlotBlocked(_startTime!)) {
      return false;
    }
    return true;
  }

  FacilityBookingRecord _mergeBookingForDisplay(FacilityBookingRecord booking) {
    final facility = _facility;
    if (booking.id != 0 || facility == null) {
      return booking;
    }

    return FacilityBookingRecord(
      id: booking.id,
      facilityId: facility.id,
      bookingTitle: '${facility.name} Reservation',
      bookingDate: _formatApiDate(_selectedDate),
      timeSlot: _timeRange,
      notes: _notesController.text.trim(),
      status: booking.status.isEmpty ? 'Pending' : booking.status,
      cancellationReason: booking.cancellationReason,
      facility: facility,
      residentId: booking.residentId,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    );
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n?.back ?? 'Back',
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reserve residence facilities with the same simple service flow.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildSelectFacility(),
      1 => _buildSchedule(),
      2 => _buildConfirm(),
      3 => _buildApproved(),
      _ => _buildBookings(),
    };
  }

  Widget _buildSelectFacility() {
    if (_isLoadingFacilities) {
      return const WhitePremiumCard(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    if (_facilityErrorMessage != null) {
      return _ErrorStateCard(
        message: _facilityErrorMessage!,
        onRetry: _loadFacilities,
      );
    }

    if (_facilities.isEmpty) {
      return const WhitePremiumCard(
        child: Text('No facilities available right now.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Select Facility',
          subtitle: 'Choose a residence facility and continue to availability.',
        ),
        const SizedBox(height: 14),
        for (final facility in _facilities) ...[
          _FacilityOptionCard(
            facility: facility,
            selected: facility.id == _facility?.id,
            onTap: () {
              setState(() {
                _facility = facility;
                _availability = null;
                _step = 1;
              });
              _loadAvailability();
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSchedule() {
    final facility = _facility;
    if (facility == null) {
      return _ErrorStateCard(
        message: 'Pilih fasilitas terlebih dahulu.',
        onRetry: () => _goToStep(0),
      );
    }

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedFacilityCard(facility: facility),
          const SizedBox(height: 16),
          _DatePickerTile(date: _selectedDate, onTap: _pickDate),
          const SizedBox(height: 16),
          const _FieldLabel('Start Time'),
          const SizedBox(height: 10),
          _TimeDropdown(
            key: const ValueKey('facility-start-time-dropdown'),
            value: _startTime,
            hint: 'Select start time',
            items: _facilityTimeOptions
                .take(_facilityTimeOptions.length - 1)
                .toList(),
            onChanged: _selectStartTime,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('End Time'),
          const SizedBox(height: 10),
          _TimeDropdown(
            key: const ValueKey('facility-end-time-dropdown'),
            value: _endTime,
            hint: _startTime == null
                ? 'Select start time first'
                : 'Select end time',
            items: _endTimeOptions,
            onChanged: _startTime == null ? null : _selectEndTime,
          ),
          const SizedBox(height: 14),
          _AvailabilityNotice(
            availability: _availability,
            isLoading: _isLoadingAvailability,
            startTime: _startTime,
            endTime: _endTime,
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
            onPressed: _continueToConfirm,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    final facility = _facility;
    if (facility == null) {
      return _ErrorStateCard(
        message: 'Pilih fasilitas terlebih dahulu.',
        onRetry: () => _goToStep(0),
      );
    }

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
              ('Facility', facility.name),
              ('Location', facility.location),
              ('Date', _facilityDate.format(_selectedDate)),
              ('Time', _timeRange),
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
                'Please arrive 10 minutes before booking time. Your reservation will be submitted to management for review.',
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: _isSubmitting ? 'Submitting...' : 'Confirm Booking',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _isSubmitting ? () {} : _confirmBooking,
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
                'Your facility reservation has been submitted to management.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _DetailPanel(
                rows: [
                  ('Reservation ID', booking?.displayCode ?? '-'),
                  ('Status', booking?.status ?? 'Pending'),
                  ('Facility', booking?.facilityName ?? _facility?.name ?? '-'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // _BookingQrCard(
        //   code: booking?.displayCode ?? 'FB-DEMO',
        //   facility: booking?.facilityName ?? _facility?.name ?? '-',
        //   schedule:
        //       '${booking == null ? _facilityDate.format(_selectedDate) : _formatDisplayDate(booking.bookingDate)}, ${booking?.timeSlot ?? _timeRange}',
        // ),
        const SizedBox(height: 14),
        // LuxuryButton(
        //   label: 'View Booking Details',
        //   icon: Icons.visibility_outlined,
        //   onPressed: () => _goToStep(4),
        // ),
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
      final parsedDate = DateTime.tryParse(booking.bookingDate);
      final bookingDate = parsedDate == null
          ? today
          : DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final currentDate = DateTime(today.year, today.month, today.day);
      if (_bookingFilter == 'Past') {
        return bookingDate.isBefore(currentDate);
      }
      return !bookingDate.isBefore(currentDate);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingBookings)
          const WhitePremiumCard(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          )
        else if (_bookingErrorMessage != null)
          _ErrorStateCard(
            message: _bookingErrorMessage!,
            onRetry: _loadBookings,
          )
        else ...[
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
                  items: booking_dummy.FacilityBookingDummy.filters,
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
              _BookingCard(
                booking: booking,
                formatDate: _formatDisplayDate,
                onTap: () => _openBookingDetail(booking),
              ),
              const SizedBox(height: 12),
            ],
        ],
        LuxuryButton(
          label: 'Back to Home',
          icon: Icons.arrow_back_rounded,
          onPressed: widget.onBack,
        ),
      ],
    );
  }

  Future<void> _openBookingDetail(FacilityBookingRecord booking) async {
    try {
      final detail = await _apiService.getResidentFacilityBookingDetail(
        booking.id,
      );
      if (!mounted) {
        return;
      }
      _showBookingDetailSheet(detail.id == 0 ? booking : detail);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showBookingSnack(
        error is ApiServiceException
            ? error.message
            : 'Detail booking belum bisa dimuat. Coba lagi.',
      );
    }
  }

  void _showBookingDetailSheet(FacilityBookingRecord booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                    _CardTitle(
                      title: booking.facilityName,
                      subtitle: booking.facilityLocation,
                      icon: _facilityIcon(booking.facilityName),
                    ),
                    const SizedBox(height: 16),
                    _DetailPanel(
                      rows: [
                        ('Booking ID', booking.displayCode),
                        (
                          'Status',
                          booking.status.isEmpty ? '-' : booking.status,
                        ),
                        ('Date', _formatDisplayDate(booking.bookingDate)),
                        (
                          'Time',
                          booking.timeSlot.isEmpty ? '-' : booking.timeSlot,
                        ),
                        ('Notes', booking.notes.isEmpty ? '-' : booking.notes),
                        if (booking.cancellationReason.isNotEmpty)
                          ('Cancel Reason', booking.cancellationReason),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (booking.canCancel && booking.id != 0) ...[
                      LuxuryButton(
                        label: 'Cancel Booking',
                        icon: Icons.cancel_outlined,
                        danger: true,
                        variant: LuxuryButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showCancelBookingDialog(booking);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    LuxuryButton(
                      label: 'Close',
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

  void _showCancelBookingDialog(FacilityBookingRecord booking) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Cancellation reason',
              hintText: 'Example: Schedule changed',
            ),
            minLines: 2,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                Navigator.of(context).pop();
                _cancelBooking(
                  booking,
                  reason.isEmpty ? 'Cancelled by resident' : reason,
                );
              },
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  Future<void> _cancelBooking(
    FacilityBookingRecord booking,
    String reason,
  ) async {
    try {
      await _apiService.cancelResidentFacilityBooking(
        bookingId: booking.id,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      _showBookingSnack('Booking berhasil dibatalkan.');
      await _loadBookings();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showBookingSnack(
        error is ApiServiceException
            ? error.message
            : 'Booking belum bisa dibatalkan. Coba lagi.',
      );
    }
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

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Unable to load data',
            subtitle: 'Please retry the request when the connection is stable.',
            icon: Icons.wifi_off_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          LuxuryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            variant: LuxuryButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _FacilityOptionCard extends StatelessWidget {
  const _FacilityOptionCard({
    required this.facility,
    required this.selected,
    required this.onTap,
  });

  final ResidentFacility facility;
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
                  facility.description.isEmpty
                      ? facility.category
                      : facility.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${facility.location.isEmpty ? '-' : facility.location} • ${facility.capacityLabel}',
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

  final ResidentFacility facility;

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

class _TimeDropdown extends StatelessWidget {
  const _TimeDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.schedule_outlined),
      ),
    );
  }
}

class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice({
    required this.availability,
    required this.isLoading,
    required this.startTime,
    required this.endTime,
  });

  final ResidentFacilityAvailability? availability;
  final bool isLoading;
  final String? startTime;
  final String? endTime;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _InfoNotice(text: 'Checking facility availability...');
    }

    if (startTime == null || endTime == null) {
      return const _InfoNotice(
        text: 'Select a start and end time to check availability.',
      );
    }

    final data = availability;
    if (data == null) {
      return const _InfoNotice(
        text: 'Availability will be checked after you choose a start time.',
      );
    }

    final available =
        data.facilityCanBook && (data.isAvailable == null || data.isAvailable!);
    final reason = data.reason.isEmpty
        ? available
              ? 'This facility is available for the selected schedule.'
              : 'This facility is not available for the selected schedule.'
        : data.reason;
    final bookedSlots = data.bookedTimeSlots.isEmpty
        ? ''
        : ' Booked slots: ${data.bookedTimeSlots.join(', ')}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFEAF7EF) : AppColors.goldSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: available
              ? AppColors.success.withValues(alpha: 0.24)
              : AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            available
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: available ? AppColors.success : AppColors.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$reason$bookedSlots',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                height: 1.38,
              ),
            ),
          ),
        ],
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

// class _BookingQrCard extends StatelessWidget {
//   const _BookingQrCard({
//     required this.code,
//     required this.facility,
//     required this.schedule,
//   });

//   final String code;
//   final String facility;
//   final String schedule;

//   @override
//   Widget build(BuildContext context) {
//     return WhitePremiumCard(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Text(
//             'Booking QR',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               color: AppColors.navy,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 14),
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(22),
//               border: Border.all(color: AppColors.borderSoft),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.shadow,
//                   blurRadius: 18,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: QrImageView(
//               data: code,
//               size: 170,
//               backgroundColor: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 14),
//           Text(
//             code,
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(
//               color: AppColors.navy,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '$facility • $schedule',
//             textAlign: TextAlign.center,
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.formatDate,
    required this.onTap,
  });

  final FacilityBookingRecord booking;
  final String Function(String raw) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
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
            child: Icon(
              _facilityIcon(booking.facilityName),
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.facilityName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(booking.bookingDate)} • ${booking.timeSlot.isEmpty ? '-' : booking.timeSlot}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.displayCode,
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
