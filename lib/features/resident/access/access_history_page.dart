import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../models/facility_booking_models.dart';
import '../../../models/visitor_access_models.dart';
import '../../../services/api_service.dart';
import '../services/widgets/service_status_badge.dart';
import 'widgets/visitor_status_badge.dart';

final _accessHistoryDateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
final _accessHistoryDate = DateFormat('dd MMM yyyy', 'id_ID');

class AccessHistoryPage extends StatefulWidget {
  const AccessHistoryPage({
    super.key,
    required this.onBack,
    required this.onOpenVisitorPass,
    this.apiService,
  });

  final VoidCallback onBack;
  final ValueChanged<VisitorAccessRecord> onOpenVisitorPass;
  final ApiService? apiService;

  @override
  State<AccessHistoryPage> createState() => _AccessHistoryPageState();
}

class _AccessHistoryPageState extends State<AccessHistoryPage> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<VisitorAccessRecord> _visitors = const [];
  List<FacilityBookingRecord> _bookings = const [];
  var _isLoadingVisitors = false;
  var _isLoadingBookings = false;
  var _isLoadingDetail = false;
  String? _visitorError;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadVisitors(), _loadBookings()]);
  }

  Future<void> _loadVisitors() async {
    setState(() {
      _isLoadingVisitors = true;
      _visitorError = null;
    });

    try {
      final visitors = await _apiService.getResidentVisitors();
      if (!mounted) {
        return;
      }
      setState(() => _visitors = visitors);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visitorError = error is ApiServiceException
            ? error.message
            : 'Data visitor belum bisa dimuat. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingVisitors = false);
      }
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoadingBookings = true;
      _bookingError = null;
    });

    try {
      final bookings = await _apiService.getResidentFacilityBookings();
      if (!mounted) {
        return;
      }
      setState(() => _bookings = bookings);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bookingError = error is ApiServiceException
            ? error.message
            : 'Data booking fasilitas belum bisa dimuat. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  Future<void> _openVisitorDetail(VisitorAccessRecord visitor) async {
    if (_isLoadingDetail) {
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _apiService.getResidentVisitorDetail(visitor.id);
      if (!mounted) {
        return;
      }
      _showVisitorDetailSheet(detail);
    } catch (error) {
      _showSnack(
        error is ApiServiceException
            ? error.message
            : 'Detail visitor belum bisa dimuat. Coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  Future<void> _openBookingDetail(FacilityBookingRecord booking) async {
    if (_isLoadingDetail) {
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _apiService.getResidentFacilityBookingDetail(
        booking.id,
      );
      if (!mounted) {
        return;
      }
      _showBookingDetailSheet(detail.id == 0 ? booking : detail);
    } catch (error) {
      _showSnack(
        error is ApiServiceException
            ? error.message
            : 'Detail booking belum bisa dimuat. Coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  void _showVisitorDetailSheet(VisitorAccessRecord visitor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HistoryBottomSheet(
          title: visitor.visitorName.trim().isEmpty
              ? 'Visitor Detail'
              : visitor.visitorName,
          icon: Icons.groups_2_outlined,
          badges: [VisitorStatusBadge(status: visitor.status)],
          rows: [
            ('Phone', _dash(visitor.visitorPhone)),
            ('Purpose', _dash(visitor.visitPurpose)),
            ('Schedule', _visitorSchedule(visitor)),
            ('Guest Count', '${visitor.guestCount}'),
            ('Unit', _dash(visitor.unit.displayLabel)),
            ('Source', _dash(visitor.registrationSource)),
            ('Access Card', _dash(visitor.accessCardNumber)),
            ('Expires At', _formatDateTime(visitor.expiresAt)),
            ('Approved At', _formatDateTime(visitor.approvedAt)),
            ('Checked In', _formatDateTime(visitor.checkedInAt)),
            ('Checked Out', _formatDateTime(visitor.checkedOutAt)),
            if (visitor.cancellationReason.trim().isNotEmpty)
              ('Cancellation Reason', visitor.cancellationReason),
            if (visitor.rejectionReason.trim().isNotEmpty)
              ('Rejection Reason', visitor.rejectionReason),
          ],
          actions: [
            LuxuryButton(
              label: 'View QR Pass',
              icon: Icons.qr_code_2_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenVisitorPass(visitor);
              },
            ),
          ],
        );
      },
    );
  }

  void _showBookingDetailSheet(FacilityBookingRecord booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HistoryBottomSheet(
          title: booking.facilityName,
          icon: Icons.event_available_outlined,
          badges: [ServiceStatusBadge(status: _dash(booking.status))],
          rows: [
            ('Booking Code', booking.displayCode),
            ('Facility', booking.facilityName),
            ('Location', booking.facilityLocation),
            ('Date', _formatDate(booking.bookingDate)),
            ('Time', _dash(booking.timeSlot)),
            ('Notes', _dash(booking.notes)),
            if (booking.cancellationReason.trim().isNotEmpty)
              ('Cancel Reason', booking.cancellationReason),
          ],
          actions: [
            if (booking.canCancel && booking.id != 0)
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
          ],
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
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Tell management why this booking is cancelled.',
            ),
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
                _cancelBooking(booking, reason.isEmpty ? 'Cancelled' : reason);
              },
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );
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
      _showSnack('Booking berhasil dibatalkan.');
      await _loadBookings();
    } catch (error) {
      _showSnack(
        error is ApiServiceException
            ? error.message
            : 'Booking belum bisa dibatalkan. Coba lagi.',
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _HistoryHeader(onBack: widget.onBack),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: WhitePremiumCard(
              padding: const EdgeInsets.all(6),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                tabs: const [
                  Tab(text: 'Visitor'),
                  Tab(text: 'Booking'),
                ],
              ),
            ),
          ),
          if (_isLoadingDetail) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: _loadVisitors,
                  child: _VisitorHistoryList(
                    visitors: _visitors,
                    isLoading: _isLoadingVisitors,
                    errorMessage: _visitorError,
                    onRetry: _loadVisitors,
                    onOpenDetail: _openVisitorDetail,
                  ),
                ),
                RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: _BookingHistoryList(
                    bookings: _bookings,
                    isLoading: _isLoadingBookings,
                    errorMessage: _bookingError,
                    onRetry: _loadBookings,
                    onOpenDetail: _openBookingDetail,
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

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Access History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Riwayat visitor dan booking fasilitas.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisitorHistoryList extends StatelessWidget {
  const _VisitorHistoryList({
    required this.visitors,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenDetail,
  });

  final List<VisitorAccessRecord> visitors;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<VisitorAccessRecord> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (isLoading && visitors.isEmpty) {
      return const _HistoryStateList(
        icon: Icons.groups_2_outlined,
        title: 'Memuat riwayat visitor...',
      );
    }

    if (errorMessage != null && visitors.isEmpty) {
      return _HistoryStateList(
        icon: Icons.error_outline_rounded,
        title: errorMessage!,
        action: LuxuryButton(
          label: 'Coba Lagi',
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      );
    }

    if (visitors.isEmpty) {
      return const _HistoryStateList(
        icon: Icons.inbox_outlined,
        title: 'Belum ada riwayat visitor.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 128),
      itemBuilder: (context, index) {
        final visitor = visitors[index];
        return _VisitorHistoryCard(
          visitor: visitor,
          onTap: () => onOpenDetail(visitor),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: visitors.length,
    );
  }
}

class _BookingHistoryList extends StatelessWidget {
  const _BookingHistoryList({
    required this.bookings,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenDetail,
  });

  final List<FacilityBookingRecord> bookings;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<FacilityBookingRecord> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (isLoading && bookings.isEmpty) {
      return const _HistoryStateList(
        icon: Icons.event_available_outlined,
        title: 'Memuat riwayat booking...',
      );
    }

    if (errorMessage != null && bookings.isEmpty) {
      return _HistoryStateList(
        icon: Icons.error_outline_rounded,
        title: errorMessage!,
        action: LuxuryButton(
          label: 'Coba Lagi',
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      );
    }

    if (bookings.isEmpty) {
      return const _HistoryStateList(
        icon: Icons.inbox_outlined,
        title: 'Belum ada riwayat booking.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 128),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingHistoryCard(
          booking: booking,
          onTap: () => onOpenDetail(booking),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: bookings.length,
    );
  }
}

class _VisitorHistoryCard extends StatelessWidget {
  const _VisitorHistoryCard({required this.visitor, required this.onTap});

  final VisitorAccessRecord visitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HistoryIcon(
            icon: Icons.groups_2_outlined,
            background: AppColors.goldSoft,
            color: AppColors.gold,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.visitorName.trim().isEmpty
                      ? 'Unnamed Visitor'
                      : visitor.visitorName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _visitorSchedule(visitor),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _dash(visitor.visitPurpose),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          VisitorStatusBadge(status: visitor.status),
        ],
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({required this.booking, required this.onTap});

  final FacilityBookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HistoryIcon(
            icon: Icons.event_available_outlined,
            background: AppColors.blueSoft,
            color: AppColors.navy,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.facilityName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(booking.bookingDate)} • ${_dash(booking.timeSlot)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  booking.displayCode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ServiceStatusBadge(status: _dash(booking.status)),
        ],
      ),
    );
  }
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _HistoryStateList extends StatelessWidget {
  const _HistoryStateList({
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 128),
      children: [
        WhitePremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _HistoryIcon(
                icon: icon,
                background: AppColors.goldSoft,
                color: AppColors.gold,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryBottomSheet extends StatelessWidget {
  const _HistoryBottomSheet({
    required this.title,
    required this.icon,
    required this.badges,
    required this.rows,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final List<Widget> badges;
  final List<(String, String)> rows;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: WhitePremiumCard(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HistoryIcon(
                      icon: icon,
                      background: AppColors.goldSoft,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(spacing: 8, runSpacing: 8, children: badges),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    children: [
                      for (final row in rows)
                        _InfoRow(label: row.$1, value: row.$2),
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...actions.expand(
                    (action) => [action, const SizedBox(height: 10)],
                  ),
                ],
                const SizedBox(height: 8),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _visitorSchedule(VisitorAccessRecord visitor) {
  final date = _formatDate(visitor.visitDate);
  final time = visitor.estimatedArrivalTime.trim();
  if (date == '-' && time.isEmpty) {
    return '-';
  }
  if (time.isEmpty) {
    return date;
  }
  return '$date, $time';
}

String _formatDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _accessHistoryDate.format(parsed.toLocal());
}

String _formatDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _accessHistoryDateTime.format(parsed.toLocal());
}

String _dash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '-' : trimmed;
}
