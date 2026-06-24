import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/community_announcement_models.dart';
import '../../../services/api_service.dart';
import 'widgets/community_announcement_presentation.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<CommunityAnnouncement> _announcements = [];
  String _filter = 'All';
  bool _isLoading = false;
  String? _errorMessage;
  CommunityAnnouncement? _selectedAnnouncement;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  List<String> get _filters {
    final categories = <String>[];

    for (final item in _announcements) {
      final category = communityAnnouncementCategoryLabel(item.category);

      if (!categories.contains(category)) {
        categories.add(category);
      }
    }

    return ['All', 'Pinned', ...categories];
  }

  List<CommunityAnnouncement> get _filteredAnnouncements {
    return _announcements.where((item) {
      if (_filter == 'All') {
        return true;
      }

      if (_filter == 'Pinned') {
        return item.isPinned;
      }

      return communityAnnouncementCategoryLabel(item.category).toLowerCase() ==
          _filter.trim().toLowerCase();
    }).toList();
  }

  int get _pinnedCount {
    return _announcements.where((item) => item.isPinned).length;
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final announcements = await _apiService.getResidentAnnouncements();

      if (!mounted) {
        return;
      }

      final nextCategories = <String>[];

      for (final item in announcements) {
        final category = communityAnnouncementCategoryLabel(item.category);

        if (!nextCategories.contains(category)) {
          nextCategories.add(category);
        }
      }

      final nextFilters = ['All', 'Pinned', ...nextCategories];
      final nextFilter = nextFilters.contains(_filter) ? _filter : 'All';

      setState(() {
        _announcements = announcements;
        _filter = nextFilter;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiServiceException
          ? error.message
          : 'Pengumuman belum bisa dimuat. Coba lagi.';

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAnnouncementDetail(CommunityAnnouncement item) async {
    setState(() {
      _selectedAnnouncement = item;
      _isLoadingDetail = true;
    });

    await showCommunityAnnouncementDetailSheet(
      context: context,
      initialAnnouncement: item,
      apiService: _apiService,
      onLoaded: (detail) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedAnnouncement = detail;
          _isLoadingDetail = false;
        });
      },
      onLoadingFinished: () {
        if (!mounted) {
          return;
        }

        setState(() => _isLoadingDetail = false);
      },
      onError: (_) {},
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAnnouncement = null;
      _isLoadingDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = _filters;
    final announcements = _filteredAnnouncements;
    final selectedAnnouncementId = _selectedAnnouncement?.id;

    return ListView(
      key: const ValueKey('community-page'),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        _CommunityHero(
          totalAnnouncements: _announcements.length,
          pinnedCount: _pinnedCount,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _SectionHeader(
            title: l10n.filterAnnouncements.toUpperCase(),
            actionLabel: l10n.reload,
            onAction: _isLoading ? null : _loadAnnouncements,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = filters[index];
                final active = value == _filter;

                return _FilterChip(
                  label: value,
                  active: active,
                  onTap: () => setState(() => _filter = value),
                );
              },
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: _SectionHeader(
            title: _filter == 'All'
                ? l10n.newestAnnouncements.toUpperCase()
                : 'PENGUMUMAN: ${_filter.toUpperCase()}',
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              if (_isLoading) const _AnnouncementsLoadingCard(),

              if (!_isLoading && _errorMessage != null)
                _AnnouncementsErrorCard(
                  message: _errorMessage!,
                  onRetry: _loadAnnouncements,
                ),

              if (!_isLoading && _errorMessage == null && announcements.isEmpty)
                const _AnnouncementsEmptyCard(),

              if (!_isLoading && _errorMessage == null)
                for (final item in announcements)
                  _AnnouncementCard(
                    item: item,
                    isSelected:
                        _isLoadingDetail && selectedAnnouncementId == item.id,
                    onTap: () => _openAnnouncementDetail(item),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({
    required this.totalAnnouncements,
    required this.pinnedCount,
  });

  final int totalAnnouncements;
  final int pinnedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 310,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 238,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, Color(0xFF103B86), AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 56,
            child: Icon(
              Icons.campaign_rounded,
              size: 210,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 38,
            top: 48,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.announcementCenter,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.communityHeroSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          Positioned(
            top: 184,
            left: 20,
            right: 20,
            child: _AnnouncementSummaryCard(
              totalAnnouncements: totalAnnouncements,
              pinnedCount: pinnedCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementSummaryCard extends StatelessWidget {
  const _AnnouncementSummaryCard({
    required this.totalAnnouncements,
    required this.pinnedCount,
  });

  final int totalAnnouncements;
  final int pinnedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.gold,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryMetric(
              label: l10n.totalAnnouncements,
              value: '$totalAnnouncements',
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.borderSoft),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryMetric(
              label: l10n.importantAnnouncements,
              value: '$pinnedCount',
              valueColor: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: valueColor ?? AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? AppColors.navy : AppColors.borderSoft,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.onTap,
    this.isSelected = false,
  });

  final CommunityAnnouncement item;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final accentColor = communityAnnouncementAccentColor(item);
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnnouncementIcon(
            icon: communityAnnouncementIconFor(item),
            color: accentColor,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isEmpty
                            ? l10n.managementAnnouncement
                            : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSelected)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    else
                      _AnnouncementBadge(
                        label: item.isPinned ? l10n.pinned : l10n.update,
                        accentColor: accentColor,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  communityAnnouncementPreviewContent(item.content),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.36,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        communityAnnouncementPublishedLabel(item.publishedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CategoryBadge(
                      label: communityAnnouncementCategoryLabel(item.category),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementIcon extends StatelessWidget {
  const _AnnouncementIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _AnnouncementBadge extends StatelessWidget {
  const _AnnouncementBadge({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isPinned = label.toLowerCase() == 'pinned';

    final background = isPinned
        ? AppColors.goldSoft
        : accentColor.withValues(alpha: 0.10);

    final foreground = isPinned ? AppColors.gold : accentColor;

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 94),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnnouncementsLoadingCard extends StatelessWidget {
  const _AnnouncementsLoadingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.hourglass_bottom_rounded,
            color: AppColors.gold,
          ),
          const SizedBox(height: 14),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.loadingAnnouncements,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.syncAnnouncements,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsErrorCard extends StatelessWidget {
  const _AnnouncementsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.error_outline_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.retryAnnouncementsHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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

class _AnnouncementsEmptyCard extends StatelessWidget {
  const _AnnouncementsEmptyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.notifications_paused_outlined,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noAnnouncementsAvailable,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.announcementsEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
