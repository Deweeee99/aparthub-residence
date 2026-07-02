import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../../../../../services/api_service.dart';
import '../service_request_flow_controller.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceDescribeRequestPage extends StatefulWidget {
  const ServiceDescribeRequestPage({super.key, this.attachmentPicker});

  final Future<String?> Function(ImageSource source)? attachmentPicker;

  @override
  State<ServiceDescribeRequestPage> createState() =>
      _ServiceDescribeRequestPageState();
}

class _ServiceDescribeRequestPageState
    extends State<ServiceDescribeRequestPage> {
  static const _desktopImageTypes = XTypeGroup(
    label: 'Images',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'],
  );

  final _imagePicker = ImagePicker();

  bool get _usesDesktopFilePicker {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ServiceRequestFlowScope.of(context);

    return ServiceRequestScreenScaffold(
      onRefresh: controller.loadCatalog,
      child: ServiceDescribeStepPage(
        selectedCategory: controller.selectedCategory,
        selectedSubcategory: controller.selectedSubcategory,
        titleController: controller.titleController,
        descriptionController: controller.descriptionController,
        preferredScheduleController: controller.preferredScheduleController,
        priorities: ServiceRequestFlowController.priorities,
        priority: controller.priority,
        isSubmitting: controller.isSubmitting,
        attachmentPaths: controller.attachmentPaths,
        onPriorityChanged: controller.setPriority,
        onAddAttachment: _showAttachmentSourcePicker,
        onRemoveAttachment: controller.removeAttachment,
        onSubmit: _submitRequest,
      ),
    );
  }

  Future<void> _submitRequest() async {
    final controller = ServiceRequestFlowScope.of(context);
    final selectedCategory = controller.selectedCategory;
    final selectedSubcategory = controller.selectedSubcategory;
    final title = controller.titleController.text.trim();
    final description = controller.descriptionController.text.trim();

    if (controller.isSubmitting) {
      return;
    }
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
    if (controller.priority.isEmpty) {
      _showServiceSnack('Pilih prioritas layanan terlebih dahulu.');
      return;
    }

    try {
      final ticket = await controller.submitRequest();
      if (!mounted || ticket == null) {
        return;
      }
      context.go(ServiceRequestRoutes.submitted);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showServiceSnack(
        error is ApiServiceException
            ? error.message
            : 'Service request belum bisa dikirim. Coba beberapa saat lagi.',
      );
    }
  }

  Future<void> _showAttachmentSourcePicker() async {
    final controller = ServiceRequestFlowScope.of(context);
    final l10n = AppLocalizations.of(context);

    if (controller.attachmentPaths.length >= 3) {
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
                    ServiceRequestAttachmentSourceTile(
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
                    ServiceRequestAttachmentSourceTile(
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
                    ServiceRequestAttachmentSourceTile(
                      key: const ValueKey('attachment-source-gallery'),
                      icon: Icons.photo_library_outlined,
                      title: l10n.gallery,
                      subtitle: l10n.choosePhoto,
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
    String? pickedPath;
    try {
      pickedPath = widget.attachmentPicker != null
          ? await widget.attachmentPicker!(source)
          : await _pickAttachmentPath(source);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showServiceSnack(AppLocalizations.of(context).photoPickFailed);
      return;
    }

    if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) {
      return;
    }
    ServiceRequestFlowScope.of(context).addAttachment(pickedPath);
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

  void _showServiceSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ServiceDescribeStepPage extends StatelessWidget {
  const ServiceDescribeStepPage({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.titleController,
    required this.descriptionController,
    required this.preferredScheduleController,
    required this.priorities,
    required this.priority,
    required this.isSubmitting,
    required this.attachmentPaths,
    required this.onPriorityChanged,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
    required this.onSubmit,
  });

  final ServiceCategory? selectedCategory;
  final ServiceSubcategory? selectedSubcategory;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController preferredScheduleController;
  final List<String> priorities;
  final String priority;
  final bool isSubmitting;
  final List<String> attachmentPaths;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slaMinutes =
        selectedSubcategory?.sla.minutesForPriority(priority) ?? 0;

    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceRequestCardTitle(
            title: l10n.describeIssue,
            subtitle: l10n.describeIssueSubtitle,
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 16),
          if (selectedCategory != null || selectedSubcategory != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedCategory != null)
                    ServiceRequestStaticPill(label: selectedCategory!.name),
                  if (selectedSubcategory != null)
                    ServiceRequestStaticPill(label: selectedSubcategory!.name),
                ],
              ),
            ),
          TextField(
            key: const ValueKey('service-title-field'),
            controller: titleController,
            decoration: InputDecoration(labelText: l10n.problemTitle),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('service-description-field'),
            controller: descriptionController,
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
          ServiceRequestChoiceWrap(
            items: priorities,
            selected: priority,
            onSelected: onPriorityChanged,
          ),
          if (slaMinutes > 0) ...[
            const SizedBox(height: 14),
            ServiceRequestInfoPanel(
              icon: Icons.timer_outlined,
              title: l10n.estimatedSla,
              subtitle: '$slaMinutes minutes for $priority priority',
              status: 'Open',
            ),
          ],
          const SizedBox(height: 14),
          const ServiceRequestAutomaticScheduleNotice(
            key: ValueKey('automatic-schedule-info'),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('preferred-schedule-field'),
            controller: preferredScheduleController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.preferredScheduleNote,
              hintText: 'Example: Morning after 09:00 or after office hours',
            ),
          ),
          const SizedBox(height: 14),
          ServiceRequestPhotoUploadRow(
            attachmentPaths: attachmentPaths,
            onAddTap: onAddAttachment,
            onRemove: onRemoveAttachment,
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            key: const ValueKey('submit-service-request-button'),
            label: isSubmitting ? l10n.submitting : l10n.submitRequest,
            icon: Icons.send_outlined,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
