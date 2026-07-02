import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/luxury_button.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../widgets/service_status_badge.dart';

class ServiceRequestLoadingStateCard extends StatelessWidget {
  const ServiceRequestLoadingStateCard({super.key, required this.message});

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

class ServiceRequestErrorStateCard extends StatelessWidget {
  const ServiceRequestErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

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

class ServiceRequestEmptyStateText extends StatelessWidget {
  const ServiceRequestEmptyStateText({super.key, required this.text});

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

class ServiceRequestTimelineCard extends StatelessWidget {
  const ServiceRequestTimelineCard({super.key, required this.item});

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
          const ServiceRequestGoldIcon(icon: Icons.timeline_rounded, size: 36),
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

class ServiceRequestStaticPill extends StatelessWidget {
  const ServiceRequestStaticPill({super.key, required this.label});

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

class ServiceRequestPrimaryStateButton extends StatelessWidget {
  const ServiceRequestPrimaryStateButton({
    super.key,
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

class ServiceRequestCategoryCard extends StatelessWidget {
  const ServiceRequestCategoryCard({
    super.key,
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
          ServiceRequestGoldIcon(icon: icon, size: 42),
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

class ServiceRequestCardTitle extends StatelessWidget {
  const ServiceRequestCardTitle({
    super.key,
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
        ServiceRequestGoldIcon(icon: icon, size: 42),
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

class ServiceRequestPhotoUploadRow extends StatelessWidget {
  const ServiceRequestPhotoUploadRow({
    super.key,
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

class ServiceRequestDetailPanel extends StatelessWidget {
  const ServiceRequestDetailPanel({super.key, required this.rows});

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

class ServiceRequestInfoPanel extends StatelessWidget {
  const ServiceRequestInfoPanel({
    super.key,
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
          ServiceRequestGoldIcon(icon: icon, size: 40),
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

class ServiceRequestProgressLockedNotice extends StatelessWidget {
  const ServiceRequestProgressLockedNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ServiceRequestGoldIcon(
            icon: Icons.lock_clock_outlined,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceRequestAutomaticScheduleNotice extends StatelessWidget {
  const ServiceRequestAutomaticScheduleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ServiceRequestGoldIcon(icon: Icons.schedule_outlined, size: 40),
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

class ServiceRequestAttachmentSourceTile extends StatelessWidget {
  const ServiceRequestAttachmentSourceTile({
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
          ServiceRequestGoldIcon(icon: icon, size: 40),
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

class ServiceRequestChoiceWrap extends StatelessWidget {
  const ServiceRequestChoiceWrap({
    super.key,
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

class ServiceRequestOutlineActionButton extends StatelessWidget {
  const ServiceRequestOutlineActionButton({
    super.key,
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

class ServiceRequestSuccessIcon extends StatelessWidget {
  const ServiceRequestSuccessIcon({super.key, required this.icon});

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

class ServiceRequestGoldIcon extends StatelessWidget {
  const ServiceRequestGoldIcon({super.key, required this.icon, this.size = 40});

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
                child: _buildPreviewImage(context),
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

  Widget _buildPreviewImage(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _AttachmentFallback(path: path),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _AttachmentFallback(path: path),
    );
  }
}

class _AttachmentFallback extends StatelessWidget {
  const _AttachmentFallback({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
