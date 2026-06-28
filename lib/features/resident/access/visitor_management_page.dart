import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/visitor_access_dummy.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/visitor_access_models.dart';
import '../../../services/api_service.dart';
import '../../../services/app_debug_logger.dart';
import 'widgets/visitor_qr_card.dart';
import 'widgets/visitor_status_badge.dart';
import 'widgets/visitor_step_indicator.dart';

enum VisitorManagementInitialMode { create, history }

class VisitorManagementPage extends StatefulWidget {
  const VisitorManagementPage({
    super.key,
    required this.onBack,
    required this.initialMode,
    this.apiService,
    this.launchUrlOverride,
    this.copyTextOverride,
  });

  final VoidCallback onBack;
  final VisitorManagementInitialMode initialMode;
  final ApiService? apiService;
  final Future<bool> Function(Uri url)? launchUrlOverride;
  final Future<void> Function(String text)? copyTextOverride;

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
  static const _historyFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Checked In',
    'Checked Out',
    'Cancelled',
    'Expired',
  ];

  late final ApiService _apiService = widget.apiService ?? ApiService();
  final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  final _visitDateFormat = DateFormat('yyyy-MM-dd');
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  // Hold: vehicle number is hidden until backend supports it in visitor POST.
  // late final TextEditingController _vehicleController;
  List<VisitorAccessRecord> _visitorHistory = const [];
  VisitorAccessRecord? _createdVisitor;

  late int _visitorStep;
  var _visitorName = '';
  var _phone = '';
  var _purpose = '';
  DateTime? _selectedVisitDate;
  var _visitTime = '';
  // Hold: duration is hidden until backend supports it in visitor POST.
  // var _duration = VisitorAccessDummy.defaultDuration;
  var _visitorCount = 1;
  // Hold: vehicle number is hidden until backend supports it in visitor POST.
  // var _vehicleNumber = VisitorAccessDummy.defaultVehicleNumber;
  var _visitorPassCode = VisitorAccessDummy.defaultPassCode;
  var _historyFilter = 'All';
  var _isVerifying = false;
  var _isLoadingHistory = false;
  var _isLoadingDetail = false;
  var _isLoadingQrPass = false;
  var _isSubmittingVisitor = false;
  var _isLoadingVisitorStatus = false;

  String? _historyErrorMessage;
  String? _qrPassErrorMessage;
  String? _visitorStatusErrorMessage;
  VisitorQrPass? _createdVisitorQrPass;

  @override
  void initState() {
    super.initState();
    _visitorStep = widget.initialMode == VisitorManagementInitialMode.history
        ? _steps.length - 1
        : 0;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    // Hold: _vehicleController kept out of active flow until backend supports it.
    // _vehicleController = TextEditingController(text: _vehicleNumber);
    if (widget.initialMode == VisitorManagementInitialMode.history) {
      unawaited(_loadVisitorHistory());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    // Hold: _vehicleController kept out of active flow until backend supports it.
    // _vehicleController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final target = step.clamp(0, _steps.length - 1);
    setState(() => _visitorStep = target);
    if (target == 4) {
      _startVerification();
    }
    if (target == 6 && _visitorHistory.isEmpty && !_isLoadingHistory) {
      unawaited(_loadVisitorHistory());
    }
  }

  void _nextStep() => _goToStep(_visitorStep + 1);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _debugVisitorQrState(String message) {
    appDebugLog('VisitorManagement', message);
  }

  void _debugVisitorShareState(String message) {
    appDebugLog('VisitorShare', message);
  }

  bool _canAttemptVisitorQr(VisitorAccessRecord visitor) {
    return visitor.qrAvailable ||
        visitor.status.trim().toLowerCase() == 'approved';
  }

  void _saveRegistration() {
    final visitorName = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (visitorName.isEmpty) {
      _showSnackBar('Nama visitor wajib diisi.');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Nomor ponsel visitor wajib diisi.');
      return;
    }
    if (_purpose.trim().isEmpty) {
      _showSnackBar('Tujuan kunjungan wajib dipilih.');
      return;
    }

    setState(() {
      _visitorName = visitorName;
      _phone = phone;
      // Hold: vehicle number is intentionally not collected/sent in this phase.
      // _vehicleNumber = _vehicleController.text.trim().isEmpty
      //     ? '-'
      //     : _vehicleController.text.trim();
    });
    _nextStep();
  }

  // Hold: local pass-code generation is inactive while create uses backend response.
  // void _generatePassCode() {
  //   final nextNumber = (_localVisitorHistory.length + 126).toString().padLeft(
  //     5,
  //     '0',
  //   );
  //   setState(() => _visitorPassCode = 'VST-2026-$nextNumber');
  // }

  Future<void> _submitVisitorRegistration() async {
    if (_isSubmittingVisitor) {
      return;
    }

    final selectedVisitDate = _selectedVisitDate;

    if (selectedVisitDate == null) {
      _showSnackBar('Tanggal kunjungan wajib dipilih.');
      return;
    }

    if (_visitTime.trim().isEmpty) {
      _showSnackBar('Waktu kedatangan wajib dipilih.');
      return;
    }

    setState(() => _isSubmittingVisitor = true);

    try {
      final visitor = await _apiService.createResidentVisitor(
        visitorName: _visitorName,
        visitorPhone: _phone,
        visitDate: _visitDateFormat.format(selectedVisitDate),
        estimatedArrivalTime: _visitTime,
        guestCount: _visitorCount,
        visitPurpose: _purpose,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdVisitor = visitor;
        _createdVisitorQrPass = null;
        _qrPassErrorMessage = null;
        _visitorPassCode = visitor.accessCardNumber.trim().isNotEmpty
            ? visitor.accessCardNumber.trim()
            : 'VISITOR-${visitor.id}';
        _isSubmittingVisitor = false;

        // Setelah konfirmasi jadwal, masuk ke Verify Step dulu.
        _visitorStep = 4;
      });

      _startVerification();

      _debugVisitorQrState(
        'Create visitor result: id=${visitor.id}, status="${visitor.status}", qrAvailable=${visitor.qrAvailable}',
      );

      if (_canAttemptVisitorQr(visitor)) {
        unawaited(_loadQrPassForCreatedVisitor());
      } else {
        _debugVisitorQrState(
          'Verify step QR decision: pending approval for visitor ${visitor.id}',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmittingVisitor = false);

      _showSnackBar(
        error is ApiServiceException
            ? error.message
            : 'Registrasi visitor belum bisa dibuat. Coba lagi.',
      );
    }
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

  // void _completeCheckIn() {
  //   _nextStep();
  // }

  Future<void> _pickVisitDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate =
        _selectedVisitDate == null || _selectedVisitDate!.isBefore(firstDate)
        ? firstDate
        : _selectedVisitDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(firstDate.year + 1, firstDate.month, firstDate.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.navy,
              secondary: AppColors.gold,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }
    setState(() => _selectedVisitDate = picked);
  }

  Future<void> _loadVisitorHistory({String? status}) async {
    setState(() {
      _isLoadingHistory = true;
      _historyErrorMessage = null;
      if (status != null) {
        _historyFilter = status;
      }
    });
    _debugVisitorQrState(
      'History load start: filter="${_historyFilter == 'All' ? 'All/no-query' : _historyFilter}"',
    );

    try {
      final visitors = await _apiService.getResidentVisitors(
        status: _historyFilter == 'All' ? null : _historyFilter,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _visitorHistory = visitors;
        _isLoadingHistory = false;
      });
      _debugVisitorQrState(
        'History load success: count=${visitors.length}, filter="$_historyFilter"',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingHistory = false;
        _historyErrorMessage = error is ApiServiceException
            ? error.message
            : 'Data visitor belum bisa dimuat. Coba lagi.';
      });
      _debugVisitorQrState('History load failed: $error');
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
      if (!mounted) {
        return;
      }
      _showSnackBar(
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

  Future<void> _loadQrPassForCreatedVisitor({
    bool refreshDetailFirst = false,
  }) async {
    final visitor = _createdVisitor;
    if (visitor == null) {
      _debugVisitorQrState('QR load skipped: no created visitor state');
      return;
    }

    if (refreshDetailFirst) {
      await _refreshCreatedVisitorApproval();
      if (!mounted) {
        return;
      }
      final refreshedVisitor = _createdVisitor;
      if (refreshedVisitor == null || !_canAttemptVisitorQr(refreshedVisitor)) {
        _debugVisitorQrState(
          'QR load skipped: visitor ${refreshedVisitor?.id ?? visitor.id} is still pending/unavailable',
        );
        return;
      }
      if (!refreshedVisitor.qrAvailable &&
          refreshedVisitor.status.trim().toLowerCase() == 'approved') {
        _debugVisitorQrState(
          'Detail says Approved but qrAvailable=false; attempting QR endpoint anyway',
        );
      }
    }

    final currentVisitor = _createdVisitor;
    if (currentVisitor == null) {
      return;
    }

    setState(() {
      _isLoadingQrPass = true;
      _qrPassErrorMessage = null;
    });
    _debugVisitorQrState('QR endpoint start: visitor id=${currentVisitor.id}');

    try {
      final qrPass = await _apiService.getResidentVisitorQr(currentVisitor.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _createdVisitorQrPass = qrPass;
        _visitorPassCode = qrPass.accessCode.trim().isNotEmpty
            ? qrPass.accessCode.trim()
            : _visitorPassCode;
        _isLoadingQrPass = false;
      });
      _debugVisitorQrState(
        'QR endpoint success: visitor id=${qrPass.visitorId}, status="${qrPass.status}", hasPayload=${qrPass.qrPayload.trim().isNotEmpty}, hasAccessCode=${qrPass.accessCode.trim().isNotEmpty}, validUntil="${qrPass.validUntil}"',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingQrPass = false;
        _qrPassErrorMessage = error is ApiServiceException
            ? error.message
            : 'QR visitor belum bisa dimuat. Coba lagi.';
      });
      _debugVisitorQrState(
        'QR endpoint failed: visitor id=${currentVisitor.id}, error=$error',
      );
    }
  }

  void _openVisitorStatusStep() {
    setState(() => _visitorStep = 5);
    unawaited(_refreshCreatedVisitorStatus());
  }

  Future<void> _refreshCreatedVisitorStatus() async {
    final visitor = _createdVisitor;

    if (visitor == null) {
      setState(() {
        _visitorStatusErrorMessage = 'Data visitor belum tersedia.';
      });
      return;
    }

    if (_isLoadingVisitorStatus) {
      return;
    }

    setState(() {
      _isLoadingVisitorStatus = true;
      _visitorStatusErrorMessage = null;
    });

    try {
      final detail = await _apiService.getResidentVisitorDetail(visitor.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _createdVisitor = detail;
        _isLoadingVisitorStatus = false;

        if (detail.visitorName.trim().isNotEmpty) {
          _visitorName = detail.visitorName.trim();
        }

        if (detail.visitorPhone.trim().isNotEmpty) {
          _phone = detail.visitorPhone.trim();
        }

        if (detail.visitPurpose.trim().isNotEmpty) {
          _purpose = detail.visitPurpose.trim();
        }

        if (detail.estimatedArrivalTime.trim().isNotEmpty) {
          _visitTime = detail.estimatedArrivalTime.trim();
        }

        if (detail.guestCount > 0) {
          _visitorCount = detail.guestCount;
        }
      });

      _debugVisitorQrState(
        'Visitor status refreshed: id=${detail.id}, status="${detail.status}", checkedIn="${detail.checkedInAt}", checkedOut="${detail.checkedOutAt}"',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingVisitorStatus = false;
        _visitorStatusErrorMessage = error is ApiServiceException
            ? error.message
            : 'Status visitor belum bisa dimuat. Coba lagi.';
      });
    }
  }

  Future<void> _refreshCreatedVisitorApproval() async {
    final visitor = _createdVisitor;
    if (visitor == null || _isLoadingQrPass) {
      return;
    }

    setState(() {
      _isLoadingQrPass = true;
      _qrPassErrorMessage = null;
    });
    _debugVisitorQrState('Refresh approval start: visitor id=${visitor.id}');

    try {
      final refreshed = await _apiService.getResidentVisitorDetail(visitor.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _createdVisitor = refreshed;
        _isLoadingQrPass = false;
        _visitorPassCode = refreshed.accessCardNumber.trim().isNotEmpty
            ? refreshed.accessCardNumber.trim()
            : _visitorPassCode;
      });
      _debugVisitorQrState(
        'Refresh approval success: visitor id=${refreshed.id}, status="${refreshed.status}", qrAvailable=${refreshed.qrAvailable}, accessCard="${refreshed.accessCardNumber}", expiresAt="${refreshed.expiresAt}"',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingQrPass = false;
        _qrPassErrorMessage = error is ApiServiceException
            ? error.message
            : 'Detail visitor belum bisa dimuat. Coba lagi.';
      });
      _debugVisitorQrState(
        'Refresh approval failed: visitor id=${visitor.id}, error=$error',
      );
    }
  }

  void _openVisitorPassFromHistory(VisitorAccessRecord visitor) {
    final parsedVisitDate = DateTime.tryParse(visitor.visitDate.trim());

    final fallbackPassCode = visitor.accessCardNumber.trim().isNotEmpty
        ? visitor.accessCardNumber.trim()
        : 'VISITOR-${visitor.id}';

    setState(() {
      _createdVisitor = visitor;

      // Reset QR lama supaya tidak ketukar dengan visitor sebelumnya.
      _createdVisitorQrPass = null;
      _qrPassErrorMessage = null;
      _isLoadingQrPass = false;

      // Dari history detail, masuk ke Verify Step dulu.
      _visitorStep = 4;

      _visitorPassCode = fallbackPassCode;

      if (visitor.visitorName.trim().isNotEmpty) {
        _visitorName = visitor.visitorName.trim();
      }

      if (visitor.visitorPhone.trim().isNotEmpty) {
        _phone = visitor.visitorPhone.trim();
      }

      if (visitor.visitPurpose.trim().isNotEmpty) {
        _purpose = visitor.visitPurpose.trim();
      }

      if (visitor.estimatedArrivalTime.trim().isNotEmpty) {
        _visitTime = visitor.estimatedArrivalTime.trim();
      }

      if (visitor.guestCount > 0) {
        _visitorCount = visitor.guestCount;
      }

      if (parsedVisitDate != null) {
        _selectedVisitDate = parsedVisitDate;
      }
    });

    _startVerification();

    if (_canAttemptVisitorQr(visitor)) {
      _debugVisitorQrState(
        'Verify opened from history: visitor id=${visitor.id}, loading QR endpoint',
      );

      unawaited(_loadQrPassForCreatedVisitor());
    } else {
      _debugVisitorQrState(
        'Verify opened from history: visitor id=${visitor.id}, QR unavailable/pending',
      );
    }
  }

  // void _showVisitorQrSheet(VisitorAccessRecord visitor) {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       final qrFuture = _apiService.getResidentVisitorQr(visitor.id);

  //       return SafeArea(
  //         child: Padding(
  //           padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  //           child: FutureBuilder<VisitorQrPass>(
  //             future: qrFuture,
  //             builder: (context, snapshot) {
  //               if (snapshot.connectionState != ConnectionState.done) {
  //                 return const WhitePremiumCard(
  //                   child: _VisitorLoadingState(
  //                     message: 'Loading visitor QR...',
  //                   ),
  //                 );
  //               }

  //               if (snapshot.hasError || !snapshot.hasData) {
  //                 return WhitePremiumCard(
  //                   child: _VisitorErrorState(
  //                     message: 'QR visitor belum bisa dimuat. Coba lagi.',
  //                     onRetry: () {
  //                       Navigator.of(context).pop();
  //                       _showVisitorQrSheet(visitor);
  //                     },
  //                   ),
  //                 );
  //               }

  //               final qrPass = snapshot.data!;
  //               return SingleChildScrollView(
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     VisitorQrCard(
  //                       title: 'Visitor QR Pass',
  //                       code: _qrAccessCode(qrPass, visitor),
  //                       qrPayload: qrPass.qrPayload,
  //                       visitorName: visitor.visitorName,
  //                       schedule: _visitScheduleLabel(visitor),
  //                       status: qrPass.status.trim().isNotEmpty
  //                           ? qrPass.status
  //                           : visitor.status,
  //                       countdownText: qrPass.validUntil.trim().isNotEmpty
  //                           ? 'Valid until ${_formatVisitorDate(qrPass.validUntil)}'
  //                           : null,
  //                     ),
  //                     const SizedBox(height: 12),
  //                     LuxuryButton(
  //                       label: AppLocalizations.of(context).close,
  //                       icon: Icons.check_rounded,
  //                       onPressed: () => Navigator.of(context).pop(),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

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
              key: const ValueKey('visitor-phone-field'),
              controller: _phoneController,
              hintText: '+62 8xx-xxxx-xxxx',
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
          // Hold: vehicle number is hidden until backend supports it in POST /resident/visitors.
          // const SizedBox(height: 14),
          // _LabeledField(
          //   label: l10n.vehicleNumberOptional,
          //   child: _PremiumTextField(
          //     controller: _vehicleController,
          //     hintText: 'B 1234 ABC',
          //     icon: Icons.directions_car_outlined,
          //   ),
          // ),
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
            subtitle: 'Choose visit date and estimated arrival time.',
          ),
          const SizedBox(height: 18),
          _DatePickerCard(
            selectedDate: _selectedVisitDate,
            onTap: _pickVisitDate,
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: l10n.visitTime,
            child: _ChoiceWrap<String>(
              options: VisitorAccessDummy.timeOptions,
              selected: _visitTime,
              onSelected: (value) => setState(() => _visitTime = value),
            ),
          ),
          // Hold: duration is hidden until backend supports it in POST /resident/visitors.
          // const SizedBox(height: 14),
          // _LabeledField(
          //   label: l10n.expectedDuration,
          //   child: _ChoiceWrap<String>(
          //     options: VisitorAccessDummy.durationOptions,
          //     selected: _duration,
          //     onSelected: (value) => setState(() => _duration = value),
          //   ),
          // ),
          const SizedBox(height: 20),
          LuxuryButton(
            label: _isSubmittingVisitor ? l10n.submitting : l10n.confirm,
            onPressed: _submitVisitorRegistration,
          ),
        ],
      ),
    );
  }

  Widget _buildPassStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final visitor = _createdVisitor;
    final qrPass = _createdVisitorQrPass;

    final hasQrPayload = qrPass?.qrPayload.trim().isNotEmpty == true;
    final hasAccessCode = qrPass?.accessCode.trim().isNotEmpty == true;

    // Ini yang jadi patokan utama tombol Share muncul.
    // Kalau backend belum ngasih QR payload/access code, user belum boleh lanjut Share.
    final canSharePass = qrPass != null && (hasQrPayload || hasAccessCode);

    final canAttemptQr = visitor == null
        ? false
        : _canAttemptVisitorQr(visitor);

    final passCode = canSharePass
        ? _qrAccessCode(qrPass, visitor)
        : (visitor?.accessCardNumber.trim().isNotEmpty == true
              ? visitor!.accessCardNumber.trim()
              : _visitorPassCode);

    final displayName = visitor?.visitorName.trim().isNotEmpty == true
        ? visitor!.visitorName.trim()
        : _visitorName;

    final displaySchedule = visitor == null
        ? '${_selectedVisitDate == null ? '-' : _visitDateFormat.format(_selectedVisitDate!)}, ${_visitTime.isEmpty ? '-' : _visitTime}'
        : _visitScheduleLabel(visitor);

    void openHistory() {
      setState(() {
        _visitorStep = 6;
        _historyFilter = 'All';
      });

      _debugVisitorQrState(
        'History opened from pass step: loading API history',
      );

      unawaited(_loadVisitorHistory());
    }

    void openShareStep() {
      if (!canSharePass) {
        _showSnackBar('QR pass belum tersedia untuk dibagikan.');
        return;
      }

      setState(() {
        _visitorPassCode = passCode;
        _visitorStep = 3;
      });
    }

    return Column(
      children: [
        if (_isLoadingQrPass && !canSharePass)
          const WhitePremiumCard(
            child: _VisitorLoadingState(message: 'Loading visitor QR...'),
          )
        else if (canSharePass)
          VisitorQrCard(
            title: l10n.passGenerated,
            code: passCode,
            qrPayload: qrPass.qrPayload,
            visitorName: displayName,
            schedule: displaySchedule,
            status: qrPass.status.trim().isNotEmpty
                ? qrPass.status
                : visitor?.status.trim().isNotEmpty == true
                ? visitor!.status
                : 'Ready to Share',
            countdownText: qrPass.validUntil.trim().isNotEmpty
                ? 'Valid until ${_formatVisitorDate(qrPass.validUntil)}'
                : visitor?.expiresAt.trim().isNotEmpty == true
                ? 'Valid until ${_formatVisitorDate(visitor!.expiresAt)}'
                : null,
          )
        else
          WhitePremiumCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.goldSoft,
                  child: Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.gold,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  canAttemptQr
                      ? 'QR pass belum tersedia.'
                      : 'QR pass menunggu approval management.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  canAttemptQr
                      ? 'Visitor sudah diproses, tetapi QR belum tersedia dari admin.'
                      : 'Visitor registration berhasil dibuat dan akan aktif setelah approval.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (_qrPassErrorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _qrPassErrorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 14),

        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: l10n.visitorId, value: '${visitor?.id ?? '-'}'),
              _InfoRow(
                label: l10n.visitorName,
                value: visitor?.visitorName.isNotEmpty == true
                    ? visitor!.visitorName
                    : _visitorName,
              ),
              _InfoRow(
                label: l10n.mobileNumber,
                value: visitor?.visitorPhone.isNotEmpty == true
                    ? visitor!.visitorPhone
                    : _phone,
              ),
              _InfoRow(
                label: l10n.purposeOfVisit,
                value: visitor?.visitPurpose.isNotEmpty == true
                    ? visitor!.visitPurpose
                    : _purpose,
              ),
              _InfoRow(label: l10n.visitTime, value: displaySchedule),
              _InfoRow(
                label: l10n.numberOfVisitors,
                value: '${visitor?.guestCount ?? _visitorCount}',
              ),
              _InfoRow(
                label: l10n.unit,
                value: visitor?.unit.displayLabel ?? '-',
              ),
              _InfoRow(
                label: 'Access Card',
                value: visitor?.accessCardNumber.trim().isNotEmpty == true
                    ? visitor!.accessCardNumber
                    : '-',
              ),
              _InfoRow(
                label: l10n.status,
                value: visitor?.status.trim().isNotEmpty == true
                    ? visitor!.status
                    : '-',
              ),
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
                      canSharePass
                          ? 'This pass is valid only for the above time and unit.'
                          : 'QR pass belum bisa dibagikan sebelum tersedia dari management.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (canSharePass) ...[
                LuxuryButton(
                  label: l10n.shareVisitorPass,
                  icon: Icons.ios_share_rounded,
                  onPressed: openShareStep,
                ),
                const SizedBox(height: 12),
                LuxuryButton(
                  label: l10n.viewHistory,
                  icon: Icons.history_outlined,
                  onPressed: openHistory,
                ),
              ] else
                LuxuryButton(
                  label: l10n.viewHistory,
                  icon: Icons.history_outlined,
                  onPressed: openHistory,
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _visitorShareText() {
    final visitor = _createdVisitor;
    final qrPass = _createdVisitorQrPass;
    final visitorName = visitor?.visitorName.trim().isNotEmpty == true
        ? visitor!.visitorName.trim()
        : _visitorName.trim();
    final schedule = visitor == null
        ? '${_selectedVisitDate == null ? '-' : _visitDateFormat.format(_selectedVisitDate!)}, ${_visitTime.isEmpty ? '-' : _visitTime}'
        : _visitScheduleLabel(visitor);
    final accessCode = qrPass == null
        ? _visitorPassCode
        : _qrAccessCode(qrPass, visitor);
    final validUntil = qrPass?.validUntil.trim().isNotEmpty == true
        ? _formatVisitorDate(qrPass!.validUntil)
        : visitor?.expiresAt.trim().isNotEmpty == true
        ? _formatVisitorDate(visitor!.expiresAt)
        : '-';
    final payload = qrPass?.qrPayload.trim() ?? '';
    final payloadLabel = _isHttpUrl(payload) ? 'Pass Link' : 'QR Payload';

    return [
      'ApartHub Visitor Pass',
      'Visitor: ${visitorName.isEmpty ? '-' : visitorName}',
      'Schedule: $schedule',
      'Access Code: $accessCode',
      'Valid Until: $validUntil',
      if (payload.isNotEmpty) '$payloadLabel: $payload',
    ].join('\n');
  }

  String _visitorShareLinkOrText() {
    final payload = _createdVisitorQrPass?.qrPayload.trim() ?? '';
    if (_isHttpUrl(payload)) {
      return payload;
    }
    return _visitorShareText();
  }

  Future<bool> _launchExternalUrl(Uri url) {
    final launcher = widget.launchUrlOverride;
    if (launcher != null) {
      return launcher(url);
    }
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyText(String text) async {
    final copier = widget.copyTextOverride;
    if (copier != null) {
      await copier(text);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _shareVisitorPassToWhatsApp() async {
    final qrPass = _createdVisitorQrPass;
    final visitor = _createdVisitor;
    if (qrPass == null ||
        (qrPass.qrPayload.trim().isEmpty && qrPass.accessCode.trim().isEmpty)) {
      _showSnackBar('QR pass belum tersedia untuk dibagikan.');
      _debugVisitorShareState('WhatsApp share blocked: QR pass unavailable');
      return;
    }

    final message = _visitorShareText();
    final payloadIsUrl = _isHttpUrl(qrPass.qrPayload);
    _debugVisitorShareState(
      'WhatsApp share start: visitorId=${visitor?.id ?? qrPass.visitorId}, hasPayload=${qrPass.qrPayload.trim().isNotEmpty}, hasAccessCode=${qrPass.accessCode.trim().isNotEmpty}, payloadIsUrl=$payloadIsUrl',
    );

    final appUrl = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'text': message},
    );
    final webUrl = Uri.https('wa.me', '/', {'text': message});

    try {
      final openedApp = await _launchExternalUrl(appUrl);
      if (openedApp) {
        _debugVisitorShareState('WhatsApp app opened');
        return;
      }

      _debugVisitorShareState('WhatsApp app unavailable; trying wa.me');
      final openedWeb = await _launchExternalUrl(webUrl);
      if (openedWeb) {
        _debugVisitorShareState('WhatsApp web fallback opened');
        return;
      }

      _debugVisitorShareState('WhatsApp share failed: launcher returned false');
      _showSnackBar('WhatsApp belum bisa dibuka. Coba salin link pass.');
    } catch (error) {
      _debugVisitorShareState('WhatsApp share failed: $error');
      _showSnackBar('WhatsApp belum bisa dibuka. Coba salin link pass.');
    }
  }

  Future<void> _copyVisitorPassLink() async {
    final qrPass = _createdVisitorQrPass;
    final visitor = _createdVisitor;
    if (qrPass == null ||
        (qrPass.qrPayload.trim().isEmpty && qrPass.accessCode.trim().isEmpty)) {
      _showSnackBar('QR pass belum tersedia untuk dibagikan.');
      _debugVisitorShareState('Copy blocked: QR pass unavailable');
      return;
    }

    final text = _visitorShareLinkOrText();
    final payloadIsUrl = _isHttpUrl(qrPass.qrPayload);
    try {
      await _copyText(text);
      _debugVisitorShareState(
        'Copy pass success: visitorId=${visitor?.id ?? qrPass.visitorId}, hasPayload=${qrPass.qrPayload.trim().isNotEmpty}, hasAccessCode=${qrPass.accessCode.trim().isNotEmpty}, copiedUrl=$payloadIsUrl',
      );
      _showSnackBar('Visitor pass copied.');
    } catch (error) {
      _debugVisitorShareState('Copy pass failed: $error');
      _showSnackBar('Visitor pass belum bisa disalin. Coba lagi.');
    }
  }

  Widget _buildShareStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visitor = _createdVisitor;
    final qrPass = _createdVisitorQrPass;
    final displayName = visitor?.visitorName.trim().isNotEmpty == true
        ? visitor!.visitorName.trim()
        : _visitorName;
    final displayCode = qrPass == null
        ? _visitorPassCode
        : _qrAccessCode(qrPass, visitor);

    _debugVisitorShareState(
      'Share step rendered: visitorId=${visitor?.id ?? '-'}, hasPayload=${qrPass?.qrPayload.trim().isNotEmpty == true}, hasAccessCode=${qrPass?.accessCode.trim().isNotEmpty == true}, payloadIsUrl=${_isHttpUrl(qrPass?.qrPayload ?? '')}',
    );

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
                        displayCode,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated for $displayName',
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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShareOptionTile(
              label: 'WhatsApp',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => unawaited(_shareVisitorPassToWhatsApp()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShareOptionTile(
              label: 'Copy Link',
              icon: Icons.link_rounded,
              onTap: () => unawaited(_copyVisitorPassLink()),
            ),
          ),
          const SizedBox(height: 10),
          LuxuryButton(
            label: l10n.viewStatus,
            icon: Icons.fact_check_outlined,
            onPressed: _openVisitorStatusStep,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final visitor = _createdVisitor;
    final qrPass = _createdVisitorQrPass;

    final hasQrPayload = qrPass?.qrPayload.trim().isNotEmpty == true;
    final hasAccessCode = qrPass?.accessCode.trim().isNotEmpty == true;
    final hasQrPass = qrPass != null && (hasQrPayload || hasAccessCode);

    final visitorStatus = visitor?.status.trim() ?? '';
    final normalizedStatus = visitorStatus.toLowerCase();
    final isApproved = normalizedStatus == 'approved';
    final canAttemptQr = visitor == null
        ? false
        : _canAttemptVisitorQr(visitor);

    final displayName = visitor?.visitorName.trim().isNotEmpty == true
        ? visitor!.visitorName.trim()
        : _visitorName;

    final displayUnit = visitor?.unit.displayLabel.trim().isNotEmpty == true
        ? visitor!.unit.displayLabel
        : '-';

    final displayPurpose = visitor?.visitPurpose.trim().isNotEmpty == true
        ? visitor!.visitPurpose
        : _purpose;

    final displayValidUntil = qrPass?.validUntil.trim().isNotEmpty == true
        ? _formatVisitorDate(qrPass!.validUntil)
        : visitor?.expiresAt.trim().isNotEmpty == true
        ? _formatVisitorDate(visitor!.expiresAt)
        : '-';

    final displayCode = hasQrPass
        ? _qrAccessCode(qrPass, visitor)
        : visitor?.accessCardNumber.trim().isNotEmpty == true
        ? visitor!.accessCardNumber.trim()
        : _visitorPassCode;

    void openHistory() {
      setState(() {
        _visitorStep = 6;
        _historyFilter = 'All';
      });

      _debugVisitorQrState(
        'History opened from verify step: loading API history',
      );

      unawaited(_loadVisitorHistory());
    }

    void openPassStep() {
      if (!hasQrPass) {
        _showSnackBar('QR pass belum tersedia.');
        return;
      }

      setState(() {
        _visitorPassCode = displayCode;
        _visitorStep = 2;
      });
    }

    final IconData icon;
    final Color iconColor;
    final Color iconBackground;
    final String title;
    final String subtitle;

    if (hasQrPass) {
      icon = Icons.shield_rounded;
      iconColor = AppColors.success;
      iconBackground = const Color(0xFFEAF7EF);
      title = 'QR Verified';
      subtitle = 'Akses visitor sudah disetujui dan QR pass sudah tersedia.';
    } else if (_isLoadingQrPass) {
      icon = Icons.hourglass_top_rounded;
      iconColor = AppColors.gold;
      iconBackground = AppColors.goldSoft;
      title = 'Mengecek QR Pass';
      subtitle = 'Sedang mengecek status approval dan QR visitor.';
    } else if (isApproved || canAttemptQr) {
      icon = Icons.qr_code_2_rounded;
      iconColor = AppColors.gold;
      iconBackground = AppColors.goldSoft;
      title = 'QR belum tersedia';
      subtitle =
          'Visitor sudah disetujui, tetapi QR pass belum tersedia dari admin.';
    } else {
      icon = Icons.pending_actions_rounded;
      iconColor = AppColors.gold;
      iconBackground = AppColors.goldSoft;
      title = 'Menunggu Approval';
      subtitle =
          'Registrasi visitor berhasil dibuat dan sedang menunggu approval management.';
    }

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
                        'Checking visitor approval...',
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
                key: ValueKey('visitor-verify-$title'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: iconBackground,
                      child: Icon(icon, size: 42, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: hasQrPass
                                ? AppColors.success
                                : AppColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (_qrPassErrorMessage != null && !hasQrPass) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _qrPassErrorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _InfoRow(label: l10n.visitorName, value: displayName),
                  _InfoRow(
                    label: l10n.visitorId,
                    value: '${visitor?.id ?? '-'}',
                  ),
                  _InfoRow(label: l10n.unit, value: displayUnit),
                  _InfoRow(label: 'Valid Until', value: displayValidUntil),
                  _InfoRow(label: l10n.purposeOfVisit, value: displayPurpose),
                  _InfoRow(
                    label: l10n.status,
                    value: visitorStatus.isEmpty ? '-' : visitorStatus,
                  ),
                  if (hasQrPass)
                    _InfoRow(label: 'Access Code', value: displayCode),
                  const SizedBox(height: 18),

                  if (hasQrPass)
                    LuxuryButton(
                      label: 'Lihat QR',
                      icon: Icons.qr_code_2_rounded,
                      onPressed: openPassStep,
                    )
                  else ...[
                    LuxuryButton(
                      label: _qrPassErrorMessage != null
                          ? 'Retry'
                          : 'Check Approval / Refresh QR',
                      icon: _qrPassErrorMessage != null
                          ? Icons.refresh_rounded
                          : Icons.verified_outlined,
                      onPressed: () {
                        if (_isLoadingQrPass || visitor == null) {
                          return;
                        }
                        unawaited(
                          _loadQrPassForCreatedVisitor(
                            refreshDetailFirst: true,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    LuxuryButton(
                      label: l10n.viewHistory,
                      icon: Icons.history_outlined,
                      onPressed: openHistory,
                    ),
                    const SizedBox(height: 12),
                    LuxuryButton(
                      label: l10n.back,
                      icon: Icons.arrow_back_rounded,
                      onPressed: widget.onBack,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildCheckInStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visitor = _createdVisitor;

    final status = visitor?.status.trim() ?? '';
    final normalizedStatus = status.toLowerCase();

    final checkedInAt = visitor?.checkedInAt.trim() ?? '';
    final checkedOutAt = visitor?.checkedOutAt.trim() ?? '';

    final isCheckedOut =
        checkedOutAt.isNotEmpty || normalizedStatus == 'checked out';

    final isCheckedIn =
        !isCheckedOut &&
        (checkedInAt.isNotEmpty || normalizedStatus == 'checked in');

    final isRejected = normalizedStatus == 'rejected';
    final isCancelled = normalizedStatus == 'cancelled';
    final isExpired = normalizedStatus == 'expired';

    final IconData icon;
    final Color iconColor;
    final Color iconBackground;
    final String title;
    final String subtitle;

    if (isCheckedOut) {
      icon = Icons.logout_rounded;
      iconColor = AppColors.navy;
      iconBackground = AppColors.blueSoft;
      title = 'Visitor Check-Out';
      subtitle = 'Tamu sudah keluar dari area residence.';
    } else if (isCheckedIn) {
      icon = Icons.domain_verification_rounded;
      iconColor = AppColors.success;
      iconBackground = const Color(0xFFEAF7EF);
      title = 'Check-In Berhasil';
      subtitle = 'Tamu sudah melakukan check-in melalui security.';
    } else if (isRejected) {
      icon = Icons.cancel_outlined;
      iconColor = AppColors.danger;
      iconBackground = const Color(0xFFFFEFEF);
      title = 'Akses Ditolak';
      subtitle = visitor?.rejectionReason.trim().isNotEmpty == true
          ? visitor!.rejectionReason
          : 'Akses visitor ditolak oleh management.';
    } else if (isCancelled) {
      icon = Icons.event_busy_rounded;
      iconColor = AppColors.danger;
      iconBackground = const Color(0xFFFFEFEF);
      title = 'Akses Dibatalkan';
      subtitle = visitor?.cancellationReason.trim().isNotEmpty == true
          ? visitor!.cancellationReason
          : 'Akses visitor sudah dibatalkan.';
    } else if (isExpired) {
      icon = Icons.timer_off_outlined;
      iconColor = AppColors.danger;
      iconBackground = const Color(0xFFFFEFEF);
      title = 'Akses Expired';
      subtitle = 'Masa berlaku akses visitor sudah berakhir.';
    } else {
      icon = Icons.pending_actions_rounded;
      iconColor = AppColors.gold;
      iconBackground = AppColors.goldSoft;
      title = 'Belum Check-In';
      subtitle =
          'Tamu belum melakukan check-in. Status akan berubah setelah security scan QR.';
    }

    void openHistory() {
      setState(() {
        _visitorStep = 6;
        _historyFilter = 'All';
      });

      unawaited(_loadVisitorHistory());
    }

    return WhitePremiumCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: iconBackground,
            child: Icon(icon, size: 42, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          if (_isLoadingVisitorStatus) ...[
            const SizedBox(height: 18),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.gold,
              ),
            ),
          ],

          if (_visitorStatusErrorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _visitorStatusErrorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

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
                _InfoRow(label: l10n.visitorId, value: '${visitor?.id ?? '-'}'),
                _InfoRow(
                  label: l10n.visitorName,
                  value: visitor?.visitorName.trim().isNotEmpty == true
                      ? visitor!.visitorName
                      : _visitorName,
                ),
                _InfoRow(
                  label: l10n.status,
                  value: status.isEmpty ? '-' : status,
                ),
                _InfoRow(
                  label: l10n.unit,
                  value: visitor?.unit.displayLabel.trim().isNotEmpty == true
                      ? visitor!.unit.displayLabel
                      : '-',
                ),
                _InfoRow(
                  label: l10n.visitTime,
                  value: visitor == null ? '-' : _visitScheduleLabel(visitor),
                ),
                _InfoRow(
                  label: l10n.checkInTime,
                  value: checkedInAt.isEmpty
                      ? '-'
                      : _formatVisitorDate(checkedInAt),
                ),
                _InfoRow(
                  label: 'Check-Out Time',
                  value: checkedOutAt.isEmpty
                      ? '-'
                      : _formatVisitorDate(checkedOutAt),
                ),
                _InfoRow(
                  label: 'Access Card',
                  value: visitor?.accessCardNumber.trim().isNotEmpty == true
                      ? visitor!.accessCardNumber
                      : '-',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          LuxuryButton(
            label: _isLoadingVisitorStatus
                ? 'Memuat Status...'
                : 'Refresh Status',
            icon: Icons.refresh_rounded,
            onPressed: () {
              if (_isLoadingVisitorStatus) {
                return;
              }

              unawaited(_refreshCreatedVisitorStatus());
            },
          ),

          const SizedBox(height: 12),

          LuxuryButton(
            label: l10n.viewHistory,
            icon: Icons.history_outlined,
            onPressed: openHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                options: _historyFilters,
                selected: _historyFilter,
                onSelected: (value) => _loadVisitorHistory(status: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoadingHistory)
          const WhitePremiumCard(
            child: _VisitorLoadingState(message: 'Memuat riwayat visitor...'),
          ),
        if (!_isLoadingHistory && _historyErrorMessage != null)
          WhitePremiumCard(
            child: _VisitorErrorState(
              message: _historyErrorMessage!,
              onRetry: _loadVisitorHistory,
            ),
          ),
        if (!_isLoadingHistory &&
            _historyErrorMessage == null &&
            _visitorHistory.isEmpty)
          const WhitePremiumCard(
            child: _VisitorEmptyState(message: 'Belum ada data visitor.'),
          ),
        if (!_isLoadingHistory && _historyErrorMessage == null)
          for (final record in _visitorHistory)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WhitePremiumCard(
                onTap: () => _openVisitorDetail(record),
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
                            record.visitorName.isEmpty
                                ? '-'
                                : record.visitorName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(_visitorPurposeLabel(record)),
                          const SizedBox(height: 8),
                          Text(
                            _visitScheduleLabel(record),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.unit}: ${record.unit.displayLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    VisitorStatusBadge(status: record.status),
                  ],
                ),
              ),
            ),
        if (_isLoadingDetail) ...[
          const SizedBox(height: 4),
          const LinearProgressIndicator(minHeight: 3),
        ],
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

  void _showVisitorDetailSheet(VisitorAccessRecord visitor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context);

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
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.gold.withValues(
                            alpha: 0.14,
                          ),
                          child: Text(
                            _initials(visitor.visitorName),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visitor.visitorName.isEmpty
                                    ? '-'
                                    : visitor.visitorName,
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
                                  VisitorStatusBadge(status: visitor.status),
                                  _StaticPill(
                                    label: visitor.qrAvailable
                                        ? l10n.visitorQrPass
                                        : 'QR unavailable',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (visitor.identityPhotoUrl.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            visitor.identityPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _DetailPanel(
                      rows: [
                        (l10n.mobileNumber, visitor.visitorPhone),
                        (l10n.purposeOfVisit, _visitorPurposeLabel(visitor)),
                        (l10n.visitTime, _visitScheduleLabel(visitor)),
                        (l10n.numberOfVisitors, '${visitor.guestCount}'),
                        (l10n.unit, visitor.unit.displayLabel),
                        ('Source', _dashIfEmpty(visitor.registrationSource)),
                        ('Access Card', _dashIfEmpty(visitor.accessCardNumber)),
                        ('Expires At', _formatVisitorDate(visitor.expiresAt)),
                        ('Approved At', _formatVisitorDate(visitor.approvedAt)),
                        ('Rejected At', _formatVisitorDate(visitor.rejectedAt)),
                        (
                          'Cancelled At',
                          _formatVisitorDate(visitor.cancelledAt),
                        ),
                        (
                          l10n.checkInTime,
                          _formatVisitorDate(visitor.checkedInAt),
                        ),
                        (
                          'Checked Out',
                          _formatVisitorDate(visitor.checkedOutAt),
                        ),
                        if (visitor.cancellationReason.trim().isNotEmpty)
                          ('Cancellation Reason', visitor.cancellationReason),
                        if (visitor.rejectionReason.trim().isNotEmpty)
                          ('Rejection Reason', visitor.rejectionReason),
                      ],
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
                    if (visitor.timeline.isEmpty)
                      _VisitorEmptyState(message: l10n.noTimelineUpdates)
                    else
                      for (final item in visitor.timeline)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TimelineCard(item: item),
                        ),
                    const SizedBox(height: 16),

                    LuxuryButton(
                      label: 'View QR Pass',
                      icon: Icons.qr_code_2_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openVisitorPassFromHistory(visitor);
                      },
                    ),
                    const SizedBox(height: 10),

                    if (!_canAttemptVisitorQr(visitor)) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'QR pass masih menunggu approval management.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

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

  String _visitorPurposeLabel(VisitorAccessRecord visitor) {
    final purpose = visitor.visitPurpose.trim();
    return purpose.isEmpty ? '-' : purpose;
  }

  String _visitScheduleLabel(VisitorAccessRecord visitor) {
    final date = _formatVisitorDate(visitor.visitDate);
    final time = visitor.estimatedArrivalTime.trim();
    if (date == '-' && time.isEmpty) {
      return '-';
    }
    if (time.isEmpty) {
      return date;
    }
    return '$date, $time';
  }

  String _formatVisitorDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return _dateTimeFormat.format(parsed.toLocal());
  }

  String _dashIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _qrAccessCode(VisitorQrPass qrPass, VisitorAccessRecord? visitor) {
    final accessCode = qrPass.accessCode.trim();
    if (accessCode.isNotEmpty) {
      return accessCode;
    }
    final accessCard = visitor?.accessCardNumber.trim();
    if (accessCard != null && accessCard.isNotEmpty) {
      return accessCard;
    }
    return 'VISITOR-${qrPass.visitorId}';
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

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({required this.selectedDate, required this.onTap});

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = selectedDate == null
        ? 'Select visit date'
        : DateFormat('dd MMM yyyy').format(selectedDate!);

    return InkWell(
      key: const ValueKey('visitor-visit-date-picker'),
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Date',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selectedDate == null
                          ? AppColors.textSecondary
                          : AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.navy,
            ),
          ],
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
          for (var index = 0; index < rows.length; index++) ...[
            _InfoRow(label: rows[index].$1, value: rows[index].$2),
            if (index != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _StaticPill extends StatelessWidget {
  const _StaticPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final label = _readTimelineValue(item, ['label', 'status', 'title']);
    final timestamp = _readTimelineValue(item, [
      'timestamp',
      'created_at',
      'time',
    ]);

    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timeline_rounded, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.isEmpty ? 'Timeline update' : label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorLoadingState extends StatelessWidget {
  const _VisitorLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _VisitorErrorState extends StatelessWidget {
  const _VisitorErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.warning,
          size: 34,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        LuxuryButton(
          label: l10n.retry,
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _VisitorEmptyState extends StatelessWidget {
  const _VisitorEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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

String _readTimelineValue(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}
