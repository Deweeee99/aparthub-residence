import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/white_premium_card.dart';
import '../../../../models/service_request_models.dart';
import '../../../../services/api_client.dart';

class ServiceAttachmentSection extends StatelessWidget {
  const ServiceAttachmentSection({
    super.key,
    required this.attachments,
    required this.onPreviewTap,
    this.emptyMessage = 'No attachments available.',
  });

  final List<ServiceAttachment> attachments;
  final ValueChanged<ServiceAttachment> onPreviewTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return _AttachmentEmptyState(message: emptyMessage);
    }

    final imageAttachments = attachments.where(_isImageAttachment).toList();
    final fileAttachments = attachments
        .where((item) => !_isImageAttachment(item))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageAttachments.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final attachment in imageAttachments)
                _ImageAttachmentCard(
                  attachment: attachment,
                  onTap: () => onPreviewTap(attachment),
                ),
            ],
          ),
        if (imageAttachments.isNotEmpty && fileAttachments.isNotEmpty)
          const SizedBox(height: 12),
        if (fileAttachments.isNotEmpty)
          for (final attachment in fileAttachments) ...[
            _FileAttachmentCard(attachment: attachment),
            if (attachment != fileAttachments.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

Future<void> showServiceAttachmentPreview(
  BuildContext context,
  ServiceAttachment attachment,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final previewUrl = resolveServiceAttachmentUrl(attachment.url);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: WhitePremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _AttachmentAccentIcon(
                      icon: Icons.photo_library_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attachment.fileName.isEmpty
                            ? 'Attachment Preview'
                            : attachment.fileName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (previewUrl.isEmpty)
                  _AttachmentFallbackCard(
                    attachment: attachment,
                    message: 'Preview is unavailable for this image.',
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: InteractiveViewer(
                        minScale: 0.85,
                        maxScale: 4,
                        child: Image.network(
                          previewUrl,
                          key: ValueKey(
                            'service-attachment-preview-${attachment.id}',
                          ),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const _ImageLoadingCard(expanded: true);
                          },
                          errorBuilder: (context, error, stackTrace) {
                            _debugAttachmentImageFailure(previewUrl, error);
                            return _AttachmentFallbackCard(
                              attachment: attachment,
                              message: 'Preview is unavailable for this image.',
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

bool _isImageAttachment(ServiceAttachment attachment) {
  final mime = attachment.mimeType.trim().toLowerCase();
  if (mime.startsWith('image/')) {
    return true;
  }

  final source =
      '${attachment.fileName.trim().toLowerCase()} ${attachment.url.trim().toLowerCase()}';
  const extensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.heic',
    '.heif',
    '.bmp',
  ];
  return extensions.any(source.contains);
}

String resolveServiceAttachmentUrl(String rawUrl) {
  final normalized = rawUrl.trim();
  if (normalized.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.hasScheme) {
    if (_isLocalhost(uri.host)) {
      final apiOrigin = _apiOriginUri();
      return uri
          .replace(
            scheme: apiOrigin.scheme,
            host: apiOrigin.host,
            port: apiOrigin.hasPort ? apiOrigin.port : null,
          )
          .toString();
    }
    return normalized;
  }

  final origin = _apiOriginUri().toString();

  if (normalized.startsWith('/')) {
    return '$origin$normalized';
  }

  return '$origin/$normalized';
}

bool _isLocalhost(String host) {
  final value = host.trim().toLowerCase();
  return value == 'localhost' || value == '127.0.0.1';
}

Uri _apiOriginUri() {
  final base = Uri.parse(ApiClient.baseUrl);
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
  );
}

void _debugAttachmentImageFailure(String url, Object error) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('[ServiceAttachment] Failed to load image: $url');
  debugPrint('[ServiceAttachment] Image error: $error');
}

class _ImageAttachmentCard extends StatelessWidget {
  const _ImageAttachmentCard({required this.attachment, required this.onTap});

  final ServiceAttachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl = resolveServiceAttachmentUrl(attachment.url);
    return SizedBox(
      width: 108,
      child: InkWell(
        key: ValueKey('service-attachment-image-${attachment.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: WhitePremiumCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: previewUrl.isEmpty
                      ? const _AttachmentFallbackCard(compact: true)
                      : Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const _ImageLoadingCard();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            _debugAttachmentImageFailure(previewUrl, error);
                            return const _AttachmentFallbackCard(compact: true);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                attachment.fileName.isEmpty
                    ? 'Image Attachment'
                    : attachment.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileAttachmentCard extends StatelessWidget {
  const _FileAttachmentCard({required this.attachment});

  final ServiceAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      key: ValueKey('service-attachment-file-${attachment.id}'),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const _AttachmentAccentIcon(icon: Icons.insert_drive_file_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName.isEmpty
                      ? 'Attachment File'
                      : attachment.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.mimeType.isEmpty
                      ? 'File attachment'
                      : attachment.mimeType,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _AttachmentFallbackCard extends StatelessWidget {
  const _AttachmentFallbackCard({
    this.attachment,
    this.message,
    this.compact = false,
  });

  final ServiceAttachment? attachment;
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        color: AppColors.surfaceMuted,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.gold,
            size: 22,
          ),
        ),
      );
    }

    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    (attachment?.fileName.isEmpty ?? true
                        ? 'Preview unavailable'
                        : attachment!.fileName),
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageLoadingCard extends StatelessWidget {
  const _ImageLoadingCard({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      constraints: expanded
          ? const BoxConstraints(minHeight: 240)
          : const BoxConstraints.expand(),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _AttachmentAccentIcon extends StatelessWidget {
  const _AttachmentAccentIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Icon(icon, color: AppColors.gold, size: 20),
    );
  }
}

class _AttachmentEmptyState extends StatelessWidget {
  const _AttachmentEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          const _AttachmentAccentIcon(icon: Icons.image_not_supported_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
