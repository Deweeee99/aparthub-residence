import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/white_premium_card.dart';
import '../../../../models/community_announcement_models.dart';
import '../../../../services/api_service.dart';

Future<void> showCommunityAnnouncementDetailSheet({
  required BuildContext context,
  required CommunityAnnouncement initialAnnouncement,
  required ApiService apiService,
  ValueChanged<CommunityAnnouncement>? onLoaded,
  VoidCallback? onLoadingFinished,
  ValueChanged<String>? onError,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _CommunityAnnouncementDetailSheet(
            initialAnnouncement: initialAnnouncement,
            apiService: apiService,
            onLoaded: onLoaded,
            onLoadingFinished: onLoadingFinished,
            onError: (message) {
              onError?.call(message);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
          ),
        ),
      );
    },
  );
}

String communityAnnouncementPrimaryBadgeLabel(CommunityAnnouncement item) {
  return item.isPinned ? 'Pinned' : 'Update';
}

String communityAnnouncementCategoryLabel(String value) {
  final category = value.trim();
  return category.isEmpty ? 'General' : category;
}

String communityAnnouncementPreviewContent(
  String content, {
  int maxLength = 128,
}) {
  final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'Latest update from the management office is available to review.';
  }

  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength).trimRight()}...';
}

String communityAnnouncementPublishedLabel(String value) {
  final publishedAt = value.trim();
  if (publishedAt.isEmpty) {
    return 'Recently published';
  }

  final parsedDate = DateTime.tryParse(publishedAt);
  if (parsedDate == null) {
    return publishedAt;
  }

  return DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
}

IconData communityAnnouncementIconFor(CommunityAnnouncement item) {
  final lookup = '${item.category} ${item.title} ${item.content}'
      .toLowerCase()
      .trim();

  if (lookup.contains('maintenance') ||
      lookup.contains('engineering') ||
      lookup.contains('repair')) {
    return Icons.handyman_outlined;
  }

  if (lookup.contains('water')) {
    return Icons.water_drop_outlined;
  }

  if (lookup.contains('package') || lookup.contains('parcel')) {
    return Icons.inventory_2_outlined;
  }

  if (lookup.contains('event') || lookup.contains('community')) {
    return Icons.event_outlined;
  }

  return Icons.campaign_outlined;
}

Color communityAnnouncementAccentColor(CommunityAnnouncement item) {
  final icon = communityAnnouncementIconFor(item);
  return switch (icon) {
    Icons.handyman_outlined => AppColors.info,
    Icons.water_drop_outlined => AppColors.info,
    Icons.inventory_2_outlined => AppColors.gold,
    Icons.event_outlined => AppColors.success,
    _ => AppColors.gold,
  };
}

class _CommunityAnnouncementDetailSheet extends StatefulWidget {
  const _CommunityAnnouncementDetailSheet({
    required this.initialAnnouncement,
    required this.apiService,
    this.onLoaded,
    this.onLoadingFinished,
    required this.onError,
  });

  final CommunityAnnouncement initialAnnouncement;
  final ApiService apiService;
  final ValueChanged<CommunityAnnouncement>? onLoaded;
  final VoidCallback? onLoadingFinished;
  final ValueChanged<String> onError;

  @override
  State<_CommunityAnnouncementDetailSheet> createState() =>
      _CommunityAnnouncementDetailSheetState();
}

class _CommunityAnnouncementDetailSheetState
    extends State<_CommunityAnnouncementDetailSheet> {
  late CommunityAnnouncement _announcement = widget.initialAnnouncement;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.apiService.getResidentAnnouncementDetail(
        widget.initialAnnouncement.id,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _announcement = detail;
        _isLoading = false;
      });
      widget.onLoaded?.call(detail);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      final message = error is ApiServiceException
          ? error.message
          : 'Detail pengumuman belum bisa dimuat. Coba lagi.';
      widget.onError(message);
    } finally {
      widget.onLoadingFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _announcement;

    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnnouncementIcon(icon: communityAnnouncementIconFor(item)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Management update' : item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AnnouncementBadge(
                          label: communityAnnouncementPrimaryBadgeLabel(item),
                        ),
                        _AnnouncementBadge(
                          label: communityAnnouncementCategoryLabel(
                            item.category,
                          ),
                          subtle: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const _AnnouncementDetailLoadingState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content.isEmpty
                      ? 'Please follow the latest information from management office.'
                      : item.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Date',
                  value: communityAnnouncementPublishedLabel(item.publishedAt),
                ),
                const _InfoRow(label: 'Office', value: 'Management Office'),
                const _InfoRow(label: 'Affected area', value: 'All residents'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    'Please follow the latest information from management office.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Close',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementDetailLoadingState extends StatelessWidget {
  const _AnnouncementDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading latest details...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBadge extends StatelessWidget {
  const _AnnouncementBadge({required this.label, this.subtle = false});

  final String label;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final background = subtle ? AppColors.surfaceMuted : AppColors.goldSoft;
    final foreground = subtle ? AppColors.textSecondary : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: subtle
              ? AppColors.borderSoft
              : foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnnouncementIcon extends StatelessWidget {
  const _AnnouncementIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    const iconSize = 22.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Icon(icon, color: AppColors.gold, size: iconSize),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
