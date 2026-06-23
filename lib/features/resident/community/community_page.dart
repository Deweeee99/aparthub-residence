import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
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
    final filters = _filters;
    final announcements = _filteredAnnouncements;
    final selectedAnnouncementId = _selectedAnnouncement?.id;

    return ListView(
      key: const ValueKey('community-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        WhitePremiumCard(
          child: Row(
            children: [
              const _AnnouncementIcon(
                icon: Icons.campaign_outlined,
                size: 48,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcement Center',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get the latest updates from management office.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = filters[index];
              final active = value == _filter;
              return ActionChip(
                label: Text(value),
                onPressed: () => setState(() => _filter = value),
                backgroundColor: active
                    ? AppColors.goldSoft
                    : AppColors.surface,
                side: BorderSide(
                  color: active ? AppColors.gold : AppColors.borderSoft,
                ),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
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
              isSelected: _isLoadingDetail && selectedAnnouncementId == item.id,
              onTap: () => _openAnnouncementDetail(item),
            ),
      ],
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
    return WhitePremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnnouncementIcon(icon: communityAnnouncementIconFor(item)),
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
                        item.title.isEmpty ? 'Management update' : item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AnnouncementBadge(
                      label: communityAnnouncementPrimaryBadgeLabel(item),
                      highlight: isSelected,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  communityAnnouncementPreviewContent(item.content),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        communityAnnouncementPublishedLabel(item.publishedAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AnnouncementBadge(
                      label: communityAnnouncementCategoryLabel(item.category),
                      subtle: true,
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.gold,
                      size: 18,
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

class _AnnouncementsLoadingCard extends StatelessWidget {
  const _AnnouncementsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.hourglass_bottom_rounded,
            size: 52,
            iconSize: 26,
          ),
          const SizedBox(height: 14),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading announcements...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait while we sync the latest management updates.',
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
    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.error_outline_rounded,
            size: 52,
            iconSize: 26,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again in a moment to get the latest announcements.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LuxuryButton(
            label: 'Retry',
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
    return WhitePremiumCard(
      child: Column(
        children: [
          const _AnnouncementIcon(
            icon: Icons.notifications_paused_outlined,
            size: 52,
            iconSize: 26,
          ),
          const SizedBox(height: 14),
          Text(
            'No announcements available yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Management updates will appear here as soon as they are published.',
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

class _AnnouncementBadge extends StatelessWidget {
  const _AnnouncementBadge({
    required this.label,
    this.subtle = false,
    this.highlight = false,
  });

  final String label;
  final bool subtle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final background = subtle
        ? AppColors.surfaceMuted
        : highlight
        ? AppColors.goldSoft
        : label == 'Pinned'
        ? AppColors.goldSoft
        : AppColors.blueSoft;
    final foreground = subtle
        ? AppColors.textSecondary
        : highlight
        ? AppColors.gold
        : label == 'Pinned'
        ? AppColors.gold
        : AppColors.info;

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
  const _AnnouncementIcon({
    required this.icon,
    this.size = 46,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
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
