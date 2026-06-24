import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/service_request_models.dart';
import '../../../services/api_service.dart';
import 'widgets/service_attachment_section.dart';
import 'widgets/service_status_badge.dart';
import 'widgets/service_step_indicator.dart';

enum ServiceRequestInitialMode { create, history }

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({
    super.key,
    required this.onBack,
    required this.initialMode,
    this.apiService,
    this.attachmentPicker,
  });

  final VoidCallback onBack;
  final ServiceRequestInitialMode initialMode;
  final ApiService? apiService;
  final Future<String?> Function(ImageSource source)? attachmentPicker;

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  static const _steps = [
    'Create',
    'Describe',
    'Submitted',
    'Tracking',
    'History',
  ];
  static const _priorities = ['Low', 'Medium', 'High', 'Emergency'];
  static const _desktopImageTypes = XTypeGroup(
    label: 'Images',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'],
  );

  late final ApiService _apiService = widget.apiService ?? ApiService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _preferredScheduleController;
  final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  final _imagePicker = ImagePicker();

  ServiceRequestCatalog? _catalog;
  List<ServiceTicketRecord> _tickets = const [];
  ServiceCategory? _selectedCategory;
  ServiceSubcategory? _selectedSubcategory;
  ServiceTicketRecord? _createdTicket;
  ServiceTicketRecord? _trackingTicket;
  List<String> _attachmentPaths = [];

  late int _serviceStep;
  var _priority = 'Medium';
  var _historyFilter = 'All';
  var _isLoadingCatalog = false;
  var _isLoadingHistory = false;
  var _isSubmitting = false;
  String? _errorMessage;

  bool get _usesDesktopFilePicker => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _serviceStep = widget.initialMode == ServiceRequestInitialMode.history
        ? 4
        : 0;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _preferredScheduleController = TextEditingController();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _preferredScheduleController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.initialMode == ServiceRequestInitialMode.history) {
      await _loadHistory(openHistory: true);
      return;
    }

    await _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _errorMessage = null;
    });

    try {
      final catalog = await _apiService.getServiceRequestCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _isLoadingCatalog = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCatalog = false;
        _errorMessage = error is ApiServiceException
            ? error.message
            : 'Data layanan belum bisa dimuat. Coba lagi.';
      });
    }
  }

  Future<void> _loadHistory({bool openHistory = false}) async {
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
      if (openHistory) {
        _serviceStep = 4;
      }
    });

    try {
      final tickets = await _apiService.getServiceRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _tickets = tickets;
        _isLoadingHistory = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingHistory = false;
        _errorMessage = error is ApiServiceException
            ? error.message
            : 'Data layanan belum bisa dimuat. Coba lagi.';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) {
      return;
    }

    final selectedCategory = _selectedCategory;
    final selectedSubcategory = _selectedSubcategory;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (selectedCategory == null) {
      _showServiceSnack('Pilih kategori layanan terlebih dahulu.');
      return;
    }
    if (selectedSubcategory == null) {
      _showServiceSnack('Pilih subkategori layanan terlebih dahulu.');
      return;
    }
    if (title.isEmpty) {
      _showServiceSnack('Judul masalah tidak boleh kosong.');
      return;
    }
    if (description.isEmpty) {
      _showServiceSnack('Deskripsi masalah tidak boleh kosong.');
      return;
    }
    if (_priority.isEmpty) {
      _showServiceSnack('Pilih prioritas layanan terlebih dahulu.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ticket = await _apiService.createServiceRequest(
        categoryId: selectedCategory.id,
        subcategoryId: selectedSubcategory.id,
        title: title,
        description: description,
        priority: _priority,
        residentId: _catalog?.residentId == 0 ? null : _catalog?.residentId,
        preferredSchedule: _preferredScheduleController.text.trim().isEmpty
            ? null
            : _preferredScheduleController.text.trim(),
        attachmentPaths: _attachmentPaths,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdTicket = ticket;
        _trackingTicket = ticket;
        _tickets = [ticket, ..._tickets];
        _isSubmitting = false;
        _serviceStep = 2;
        _historyFilter = 'All';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showServiceSnack(
        error is ApiServiceException
            ? error.message
            : 'Service request belum bisa dikirim. Coba beberapa saat lagi.',
      );
    }
  }

  Future<void> _openTicketDetail(ServiceTicketRecord ticket) async {
    try {
      final detail = await _apiService.getServiceRequestDetail(ticket.id);
      if (!mounted) {
        return;
      }
      _showTicketDetailSheet(detail);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showServiceSnack(
        error is ApiServiceException
            ? error.message
            : 'Data layanan belum bisa dimuat. Coba lagi.',
      );
    }
  }

  Future<void> _openTracking(ServiceTicketRecord ticket) async {
    try {
      final detail = await _apiService.getServiceRequestDetail(ticket.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _trackingTicket = detail;
        _serviceStep = 3;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showServiceSnack(
        error is ApiServiceException
            ? error.message
            : 'Data layanan belum bisa dimuat. Coba lagi.',
      );
    }
  }

  void _showServiceSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> get _historyFilters {
    final statuses = <String>{
      for (final ticket in _tickets)
        if (ticket.status.trim().isNotEmpty) ticket.status.trim(),
    }.toList()..sort();
    return ['All', ...statuses];
  }

  List<ServiceTicketRecord> get _filteredTickets {
    if (_historyFilter == 'All') {
      return _tickets;
    }
    return _tickets.where((ticket) => ticket.status == _historyFilter).toList();
  }

  ServiceTicketRecord? get _activeTicket => _createdTicket ?? _trackingTicket;

  void _goToStep(int step) {
    setState(() => _serviceStep = step.clamp(0, _steps.length - 1));
  }

  Future<void> _showAttachmentSourcePicker() async {
    final l10n = AppLocalizations.of(context);

    if (_attachmentPaths.length >= 3) {
      _showServiceSnack(l10n.maxPhotoAttachments);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: WhitePremiumCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addAttachment,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _usesDesktopFilePicker
                        ? l10n.choosePhotoComputer
                        : l10n.choosePhotoSource,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_usesDesktopFilePicker)
                    _AttachmentSourceTile(
                      key: const ValueKey('attachment-source-file'),
                      icon: Icons.folder_open_outlined,
                      title: l10n.choosePhoto,
                      subtitle: l10n.browsePhoto,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAttachment(ImageSource.gallery);
                      },
                    )
                  else ...[
                    _AttachmentSourceTile(
                      key: const ValueKey('attachment-source-camera'),
                      icon: Icons.photo_camera_outlined,
                      title: l10n.camera,
                      subtitle: l10n.capturePhoto,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAttachment(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 10),
                    _AttachmentSourceTile(
                      key: const ValueKey('attachment-source-gallery'),
                      icon: Icons.photo_library_outlined,
                      title: l10n.gallery,
                      subtitle: l10n.chooseExistingPhoto,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAttachment(ImageSource.gallery);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final l10n = AppLocalizations.of(context);

    if (_attachmentPaths.length >= 3) {
      _showServiceSnack(l10n.maxPhotoAttachments);
      return;
    }

    String? pickedPath;
    try {
      pickedPath =
          await widget.attachmentPicker?.call(source) ??
          await _pickAttachmentPath(source);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showServiceSnack(l10n.photoPickFailed);
      return;
    }

    if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) {
      return;
    }

    final selectedPath = pickedPath.trim();
    setState(() {
      if (_attachmentPaths.contains(selectedPath) ||
          _attachmentPaths.length >= 3) {
        return;
      }
      _attachmentPaths = [..._attachmentPaths, selectedPath];
    });
  }

  Future<String?> _pickAttachmentPath(ImageSource source) async {
    if (_usesDesktopFilePicker) {
      final pickedFile = await openFile(
        acceptedTypeGroups: const [_desktopImageTypes],
      );
      return pickedFile?.path;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 2200,
    );
    return pickedFile?.path;
  }

  void _removeAttachment(String path) {
    setState(() {
      _attachmentPaths = _attachmentPaths
          .where((item) => item != path)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.createServiceRequest.split(' ').first,
      l10n.describeIssue,
      l10n.status,
      l10n.trackingDetail,
      l10n.serviceHistory,
    ];

    return ListView(
      key: const ValueKey('service-request-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        ServiceStepIndicator(
          currentStep: _serviceStep,
          steps: steps,
          onStepSelected: _handleStepSelected,
        ),
        const SizedBox(height: 16),
        _buildStepContent(),
      ],
    );
  }

  void _handleStepSelected(int step) {
    if (step == 4) {
      _loadHistory(openHistory: true);
      return;
    }
    if (step == 3 && _activeTicket != null) {
      _openTracking(_activeTicket!);
      return;
    }
    if (step <= _serviceStep) {
      _goToStep(step);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n.back,
          onPressed: _serviceStep == 0 || _serviceStep == 4
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
          l10n.serviceRequest,
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
      3 => _buildTrackingStep(),
      _ => _buildTicketHistory(),
    };
  }

  Widget _buildCreateRequest() {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingCatalog) {
      return _LoadingStateCard(message: l10n.loadingServiceCatalog);
    }

    if (_catalog == null && _errorMessage != null) {
      return _ErrorStateCard(message: _errorMessage!, onRetry: _loadCatalog);
    }

    final catalog = _catalog;
    if (catalog == null) {
      return _ErrorStateCard(message: l10n.failedToLoad, onRetry: _loadCatalog);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whatServiceNeeded,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final category in catalog.categories)
          _ServiceCategoryCard(
            title: category.name,
            subtitle: '${category.subcategories.length} ${l10n.serviceOptions}',
            icon: _categoryIcon(category.name),
            selected: _selectedCategory?.id == category.id,
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _selectedSubcategory = null;
              });
            },
          ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 8),
          WhitePremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseSpecificService,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final subcategory in _selectedCategory!.subcategories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServiceCategoryCard(
                      title: subcategory.name,
                      subtitle: _slaLabel(subcategory.sla),
                      icon: Icons.tune_rounded,
                      selected: _selectedSubcategory?.id == subcategory.id,
                      onTap: () {
                        setState(() => _selectedSubcategory = subcategory);
                      },
                    ),
                  ),
                _PrimaryStateButton(
                  buttonKey: const ValueKey('continue-to-description-button'),
                  label: l10n.continueToDescription,
                  enabled: _selectedSubcategory != null,
                  onPressed: () => _goToStep(1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescribeIssue() {
    final l10n = AppLocalizations.of(context);
    final subcategory = _selectedSubcategory;
    final slaMinutes = subcategory?.sla.minutesForPriority(_priority) ?? 0;

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: l10n.describeIssue,
            subtitle: l10n.describeIssueSubtitle,
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 16),
          if (_selectedCategory != null || _selectedSubcategory != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCategory != null)
                    _StaticPill(label: _selectedCategory!.name),
                  if (_selectedSubcategory != null)
                    _StaticPill(label: _selectedSubcategory!.name),
                ],
              ),
            ),
          TextField(
            key: const ValueKey('service-title-field'),
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.problemTitle),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('service-description-field'),
            controller: _descriptionController,
            minLines: 4,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.problemDescription),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.priority,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _ChoiceWrap(
            items: _priorities,
            selected: _priority,
            onSelected: (value) => setState(() => _priority = value),
          ),
          if (slaMinutes > 0) ...[
            const SizedBox(height: 14),
            _InfoPanel(
              icon: Icons.timer_outlined,
              title: l10n.estimatedSla,
              subtitle: '$slaMinutes minutes for $_priority priority',
              status: 'Open',
            ),
          ],
          const SizedBox(height: 14),
          const _AutomaticScheduleNotice(
            key: ValueKey('automatic-schedule-info'),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('preferred-schedule-field'),
            controller: _preferredScheduleController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.preferredScheduleNote,
              hintText: 'Example: Morning after 09:00 or after office hours',
            ),
          ),
          const SizedBox(height: 14),
          _PhotoUploadRow(
            attachmentPaths: _attachmentPaths,
            onAddTap: _showAttachmentSourcePicker,
            onRemove: _removeAttachment,
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            key: const ValueKey('submit-service-request-button'),
            label: _isSubmitting ? l10n.submitting : l10n.submitRequest,
            icon: Icons.send_outlined,
            onPressed: _submitRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSubmitted() {
    final l10n = AppLocalizations.of(context);
    final ticket = _createdTicket;
    if (ticket == null) {
      return _ErrorStateCard(
        message: l10n.serviceRequestUnavailable,
        onRetry: () => _goToStep(1),
      );
    }

    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SuccessIcon(icon: Icons.send_outlined),
          const SizedBox(height: 18),
          Text(
            l10n.ticketCreated,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ticketSubmittedSuccess,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _DetailPanel(
            rows: [
              (l10n.ticketNumber, ticket.ticketNumber),
              (l10n.status, ticket.status),
              (l10n.priority, ticket.priority),
              (l10n.category, ticket.category.displayLabel),
              (l10n.subcategory, ticket.subcategory.displayLabel),
              if (ticket.slaState.isNotEmpty) (l10n.slaState, ticket.slaState),
              if (ticket.slaDueAt.isNotEmpty)
                (l10n.slaDue, _formatDateTime(ticket.slaDueAt)),
            ],
          ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: l10n.viewDetail,
            icon: Icons.visibility_outlined,
            onPressed: () => _openTracking(ticket),
          ),
          const SizedBox(height: 10),
          _OutlineActionButton(
            label: l10n.viewHistory,
            icon: Icons.history_outlined,
            onPressed: () => _loadHistory(openHistory: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep() {
    final l10n = AppLocalizations.of(context);
    final ticket = _trackingTicket ?? _createdTicket;
    if (ticket == null) {
      return _ErrorStateCard(
        message: l10n.ticketDetailUnavailable,
        onRetry: () => _loadHistory(openHistory: true),
      );
    }

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: l10n.trackingDetail,
            subtitle: l10n.realTimeTicketInfo,
            icon: Icons.track_changes_outlined,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ServiceStatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.description.isEmpty ? '-' : ticket.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          _DetailPanel(
            rows: [
              (l10n.ticketNumber, ticket.ticketNumber),
              (l10n.category, ticket.category.displayLabel),
              (l10n.subcategory, ticket.subcategory.displayLabel),
              (l10n.priority, ticket.priority),
              (
                l10n.assignedTo,
                ticket.assignedTo.isEmpty ? '-' : ticket.assignedTo,
              ),
              (l10n.createdAt, _formatDateTime(ticket.createdAt)),
              (
                l10n.operationalTime,
                ticket.operationalTimestamp.isEmpty
                    ? '-'
                    : _formatDateTime(ticket.operationalTimestamp),
              ),
              (
                l10n.slaDue,
                ticket.slaDueAt.isEmpty
                    ? '-'
                    : _formatDateTime(ticket.slaDueAt),
              ),
              (l10n.slaState, ticket.slaState.isEmpty ? '-' : ticket.slaState),
              (
                l10n.completedAt,
                ticket.completedAt.isEmpty
                    ? '-'
                    : _formatDateTime(ticket.completedAt),
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
            emptyMessage: l10n.noFileAttachments,
            onPreviewTap: _showAttachmentPreview,
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
          if (ticket.timeline.isEmpty)
            _EmptyStateText(text: l10n.noTimelineUpdates)
          else
            for (final item in ticket.timeline)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TimelineCard(item: item),
              ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: l10n.viewHistory,
            icon: Icons.history_outlined,
            onPressed: () => _loadHistory(openHistory: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHistory() {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingHistory) {
      return _LoadingStateCard(message: l10n.loadingServiceHistory);
    }

    if (_tickets.isEmpty && _errorMessage != null) {
      return _ErrorStateCard(
        message: _errorMessage!,
        onRetry: () => _loadHistory(openHistory: true),
      );
    }

    final tickets = _filteredTickets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                title: l10n.serviceHistory,
                subtitle: l10n.serviceHistoryCardSubtitle,
                icon: Icons.history_outlined,
              ),
              const SizedBox(height: 16),
              _ChoiceWrap(
                items: _historyFilters,
                selected: _historyFilter,
                onSelected: (value) => setState(() => _historyFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          WhitePremiumCard(
            child: _EmptyStateText(text: l10n.noServiceRequestsFound),
          ),
        for (final ticket in tickets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhitePremiumCard(
              onTap: () => _openTicketDetail(ticket),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoldIcon(
                    icon: _categoryIcon(ticket.category.displayLabel),
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
                          _formatDateTime(ticket.createdAt),
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
        TextButton(onPressed: widget.onBack, child: Text(l10n.backToServices)),
      ],
    );
  }

  void _showTicketDetailSheet(ServiceTicketRecord ticket) {
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
                        _GoldIcon(
                          icon: _categoryIcon(ticket.category.displayLabel),
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
                                  _StaticPill(label: ticket.priority),
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
                    _DetailPanel(
                      rows: [
                        (l10n.ticketNumber, ticket.ticketNumber),
                        (l10n.category, ticket.category.displayLabel),
                        (l10n.subcategory, ticket.subcategory.displayLabel),
                        (
                          l10n.assignedTo,
                          ticket.assignedTo.isEmpty ? '-' : ticket.assignedTo,
                        ),
                        (l10n.createdAt, _formatDateTime(ticket.createdAt)),
                        (
                          l10n.operationalTime,
                          ticket.operationalTimestamp.isEmpty
                              ? '-'
                              : _formatDateTime(ticket.operationalTimestamp),
                        ),
                        (
                          l10n.slaDue,
                          ticket.slaDueAt.isEmpty
                              ? '-'
                              : _formatDateTime(ticket.slaDueAt),
                        ),
                        (
                          l10n.slaState,
                          ticket.slaState.isEmpty ? '-' : ticket.slaState,
                        ),
                        (
                          l10n.completedAt,
                          ticket.completedAt.isEmpty
                              ? '-'
                              : _formatDateTime(ticket.completedAt),
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
                      onPreviewTap: _showAttachmentPreview,
                    ),
                    const SizedBox(height: 16),
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

  Future<void> _showAttachmentPreview(ServiceAttachment attachment) {
    return showServiceAttachmentPreview(context, attachment);
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return _dateTimeFormat.format(parsed.toLocal());
  }

  String _slaLabel(ServiceSla sla) {
    final parts = <String>[];
    if (sla.low > 0) {
      parts.add('Low ${sla.low}m');
    }
    if (sla.medium > 0) {
      parts.add('Medium ${sla.medium}m');
    }
    if (sla.high > 0) {
      parts.add('High ${sla.high}m');
    }
    if (sla.emergency > 0) {
      parts.add('Emergency ${sla.emergency}m');
    }
    return parts.isEmpty ? 'SLA not available' : parts.join(' • ');
  }
}

class _LoadingStateCard extends StatelessWidget {
  const _LoadingStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.warning,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: l10n.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final primary = _readTimelinePrimary(item);
    final secondary = _readTimelineSecondary(item);
    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GoldIcon(icon: Icons.timeline_rounded, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondary,
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

class _StaticPill extends StatelessWidget {
  const _StaticPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrimaryStateButton extends StatelessWidget {
  const _PrimaryStateButton({
    this.buttonKey,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final Key? buttonKey;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: LuxuryButton(
          key: buttonKey,
          label: label,
          icon: Icons.arrow_forward_rounded,
          onPressed: onPressed,
        ),
      ),
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
  const _PhotoUploadRow({
    required this.attachmentPaths,
    required this.onAddTap,
    required this.onRemove,
  });

  final List<String> attachmentPaths;
  final VoidCallback onAddTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.attachments,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.optionalPhotosDescription,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;
            final children = <Widget>[
              for (var index = 0; index < attachmentPaths.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: _AttachmentPreviewCard(
                    path: attachmentPaths[index],
                    removeKey: ValueKey('attachment-remove-$index'),
                    onRemove: () => onRemove(attachmentPaths[index]),
                  ),
                ),
              if (attachmentPaths.length < 3)
                SizedBox(
                  width: itemWidth,
                  child: _AttachmentAddCard(onTap: onAddTap),
                ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: children,
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  const _AttachmentPreviewCard({
    required this.path,
    required this.removeKey,
    required this.onRemove,
  });

  final String path;
  final Key removeKey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.surfaceMuted,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: AppColors.gold.withValues(alpha: 0.82),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            _attachmentLabel(path),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.96),
              shape: const CircleBorder(),
              child: InkWell(
                key: removeKey,
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentAddCard extends StatelessWidget {
  const _AttachmentAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('attachment-add-button'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, color: AppColors.gold),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).addPhoto,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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

class _AutomaticScheduleNotice extends StatelessWidget {
  const _AutomaticScheduleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GoldIcon(icon: Icons.schedule_outlined, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleAutomaticTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scheduleAutomaticBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
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

class _AttachmentSourceTile extends StatelessWidget {
  const _AttachmentSourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
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
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
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

String _readTimelinePrimary(Map<String, dynamic> item) {
  final status = '${item['status'] ?? ''}'.trim();
  final title = '${item['title'] ?? ''}'.trim();
  final note = '${item['note'] ?? ''}'.trim();
  if (status.isNotEmpty) {
    return status;
  }
  if (title.isNotEmpty) {
    return title;
  }
  if (note.isNotEmpty) {
    return note;
  }
  return 'Timeline Update';
}

String _readTimelineSecondary(Map<String, dynamic> item) {
  final parts = <String>[
    '${item['description'] ?? ''}'.trim(),
    '${item['created_at'] ?? item['timestamp'] ?? ''}'.trim(),
  ].where((value) => value.isNotEmpty).toList();
  return parts.join(' • ');
}

String _attachmentLabel(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  if (parts.isEmpty) {
    return path;
  }

  final label = parts.last.trim();
  return label.isEmpty ? path : label;
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Plumbing' => Icons.plumbing_outlined,
    'Electrical' => Icons.bolt_outlined,
    'Air Conditioning' => Icons.ac_unit_outlined,
    'Housekeeping' => Icons.cleaning_services_outlined,
    'Internet / Wi-Fi' => Icons.wifi_outlined,
    'General Maintenance' => Icons.handyman_outlined,
    _ => Icons.handyman_outlined,
  };
}
