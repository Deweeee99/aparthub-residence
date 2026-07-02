import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/community_announcement_models.dart';
import '../../../models/resident_user.dart';
import '../../../services/api_service.dart';
import '../community/widgets/community_announcement_presentation.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class ResidentHomePage extends StatefulWidget {
  const ResidentHomePage({
    super.key,
    this.resident,
    this.apiService,
    required this.onNavigate,
    required this.onOpenBilling,
  });

  final ResidentUser? resident;
  final ApiService? apiService;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenBilling;

  @override
  State<ResidentHomePage> createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<CommunityAnnouncement> _highlights = [];
  bool _isLoadingHighlights = false;
  String? _highlightsError;
  CommunityAnnouncement? _selectedAnnouncement;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() {
      _isLoadingHighlights = true;
      _highlightsError = null;
    });

    try {
      final announcements = await _apiService.getResidentAnnouncements();

      if (!mounted) {
        return;
      }

      final sorted = List<CommunityAnnouncement>.of(announcements)
        ..sort(_sortHighlights);

      setState(() {
        _highlights = sorted.take(3).toList();
        _isLoadingHighlights = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiServiceException
          ? error.message
          : 'Pengumuman belum bisa dimuat. Coba lagi.';

      setState(() {
        _highlightsError = message;
        _isLoadingHighlights = false;
      });
    }
  }

  Future<void> _openHighlightDetail(CommunityAnnouncement announcement) async {
    setState(() {
      _selectedAnnouncement = announcement;
      _isLoadingDetail = true;
    });

    await showCommunityAnnouncementDetailSheet(
      context: context,
      initialAnnouncement: announcement,
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
    final residentName = _displayName(widget.resident);
    final towerValue = _rawTowerValue(widget.resident?.unit);
    final unitValue = _rawUnitValue(widget.resident?.unit);
    final residentTypeValue = _rawResidentTypeValue(widget.resident);

    final towerLabel = _towerLabel(widget.resident?.unit);
    final unitLabel = _unitLabel(widget.resident?.unit);
    final residentTypeLabel = _residentTypeLabel(widget.resident);
    final contractLabel = _contractLabel(widget.resident);

    final locationLabel = [
      if (towerValue.isNotEmpty) 'Tower $towerValue',
      if (unitValue.isNotEmpty) 'Unit $unitValue',
    ].join(' • ');

    final summaryItems = [
      _SummaryData(label: l10n.tower, value: towerLabel),
      _SummaryData(label: l10n.unit, value: unitLabel),
      _SummaryData(label: l10n.residentType, value: residentTypeLabel),
      _SummaryData(label: l10n.contractEnd, value: contractLabel),
    ];

    final quickActions = [
      _QuickAction(
        icon: Icons.groups_2_outlined,
        label: l10n.visitor,
        onTap: () => widget.onNavigate(1),
      ),
      _QuickAction(
        icon: Icons.handyman_outlined,
        label: l10n.serviceRequest.replaceFirst(' ', '\n'),
        onTap: () => widget.onNavigate(2),
      ),
      _QuickAction(
        icon: Icons.campaign_outlined,
        label: l10n.announcement,
        onTap: () => widget.onNavigate(3),
      ),
      _QuickAction(
        icon: Icons.event_available_outlined,
        label: 'Booking',
        onTap: () => widget.onNavigate(1),
      ),
    ];

    final selectedAnnouncementId = _selectedAnnouncement?.id;
    final viewport = MediaQuery.sizeOf(context);
    final quickAccessTopGap = viewport.height >= 740 ? 30.0 : 20.0;

    return ColoredBox(
      color: Colors.transparent,
      child: ListView(
        key: const ValueKey('resident-home-page'),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _ResidenceHero(
            residentName: residentName,
            locationLabel: locationLabel,
            residentTypeLabel: residentTypeValue,
            onBillingTap: widget.onOpenBilling,
          ).animate().fadeIn(duration: 360.ms).moveY(begin: 18, end: 0),

          Padding(
            padding: EdgeInsets.fromLTRB(20, quickAccessTopGap, 20, 0),
            child: _DashboardSectionHeader(
              title: l10n.quickAccess.toUpperCase(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                return _QuickAccessCard(action: quickActions[index]);
              },
            ),
          ).animate().fadeIn(duration: 460.ms).moveY(begin: 18, end: 0),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: _DashboardSectionHeader(
              title: l10n.residenceSummary.toUpperCase(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _ResidenceSummaryCard(items: summaryItems),
          ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: _DashboardSectionHeader(
              title: AppLocalizations.of(context).todayHighlights.toUpperCase(),
              actionLabel: l10n.viewAll,
              onAction: () => widget.onNavigate(3),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildHighlights(
              selectedAnnouncementId: selectedAnnouncementId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights({required String? selectedAnnouncementId}) {
    if (_isLoadingHighlights) {
      return const _HighlightsLoadingCard();
    }

    if (_highlightsError != null) {
      return _HighlightsErrorCard(
        message: _highlightsError!,
        onRetry: _loadHighlights,
      );
    }

    if (_highlights.isEmpty) {
      return const _HighlightsEmptyCard();
    }

    return Column(
      children: [
        for (var index = 0; index < _highlights.length; index++) ...[
          _AnnouncementDashboardCard(
            icon: communityAnnouncementIconFor(_highlights[index]),
            title: _highlights[index].title.isEmpty
                ? 'Pengumuman Management'
                : _highlights[index].title,
            detail: communityAnnouncementPreviewContent(
              _highlights[index].content,
              maxLength: 110,
            ),
            accent: communityAnnouncementAccentColor(_highlights[index]),
            badgeLabel: communityAnnouncementPrimaryBadgeLabel(
              _highlights[index],
            ),
            isSelected:
                _isLoadingDetail &&
                selectedAnnouncementId == _highlights[index].id,
            onTap: () => _openHighlightDetail(_highlights[index]),
          ),
          if (index < _highlights.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ResidenceHero extends StatelessWidget {
  const _ResidenceHero({
    required this.residentName,
    required this.locationLabel,
    required this.residentTypeLabel,
    required this.onBillingTap,
  });

  final String residentName;
  final String locationLabel;
  final String residentTypeLabel;
  final VoidCallback onBillingTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayName = residentName.isEmpty ? 'Resident' : residentName;
    final displayLocation = locationLabel.isEmpty
        ? 'Unit belum ditentukan'
        : locationLabel;
    final viewport = MediaQuery.sizeOf(context);
    final isNarrow = viewport.width < 380;
    final isTall = viewport.height >= 740;
    final headerHeight = isNarrow ? 286.0 : 292.0;
    final billingTop = isNarrow ? 236.0 : 258.0;
    final heroHeight = isTall ? 402.0 : 392.0;
    final buildingBottom = isTall ? 78.0 : 82.0;
    final orbTop = isTall ? 136.0 : 138.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: headerHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, Color(0xFF0E3478), AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            right: -18,
            bottom: buildingBottom,
            child: Icon(
              Icons.apartment_rounded,
              size: 192,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),

          Positioned(
            right: 56,
            top: orbTop,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _greeting(l10n),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      const _NotificationBell(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (residentTypeLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ResidentTypeBadge(label: residentTypeLabel),
                  ],
                ],
              ),
            ),
          ),

          Positioned(
            top: billingTop,
            left: 20,
            right: 20,
            child: _BillingHeroCard(onBillingTap: onBillingTap),
          ),
        ],
      ),
    );
  }
}

class _BillingHeroCard extends StatelessWidget {
  const _BillingHeroCard({required this.onBillingTap});

  final VoidCallback onBillingTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL TAGIHAN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency.format(2850000),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jatuh tempo 25 Jun 2026',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PayNowButton(
            key: const ValueKey('current-balance-billing-button'),
            onTap: onBillingTap,
          ),
        ],
      ),
    );
  }
}

class _PayNowButton extends StatelessWidget {
  const _PayNowButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('monthly-billing-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 104,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'BAYAR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: action.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: AppColors.navy, size: 34),
          const SizedBox(height: 10),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

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
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResidenceSummaryCard extends StatelessWidget {
  const _ResidenceSummaryCard({required this.items});

  final List<_SummaryData> items;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: _SummaryItem(label: item.label, value: item.value),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
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
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementDashboardCard extends StatelessWidget {
  const _AnnouncementDashboardCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.badgeLabel,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final String badgeLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    height: 1.14,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  detail.isEmpty
                      ? 'Informasi terbaru dari management apartemen.'
                      : detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.34,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              if (isSelected)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                _AnnouncementBadge(label: badgeLabel, color: accent),
              const SizedBox(height: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBadge extends StatelessWidget {
  const _AnnouncementBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HighlightsLoadingCard extends StatelessWidget {
  const _HighlightsLoadingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
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
            'Sedang mengambil informasi terbaru dari management.',
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

class _HighlightsErrorCard extends StatelessWidget {
  const _HighlightsErrorCard({required this.message, required this.onRetry});

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
            size: 38,
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
          const SizedBox(height: 14),
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

class _HighlightsEmptyCard extends StatelessWidget {
  const _HighlightsEmptyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      child: Column(
        children: [
          const Icon(
            Icons.notifications_paused_outlined,
            size: 40,
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
            'Informasi dari management akan tampil pada area ini.',
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B4B),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.navy, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '1',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentTypeBadge extends StatelessWidget {
  const _ResidentTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({required this.label, required this.value});

  final String label;
  final String value;
}

String _greeting(AppLocalizations l10n) {
  final hour = DateTime.now().hour;

  if (hour < 11) {
    return l10n.goodMorning;
  }

  if (hour < 15) {
    return l10n.goodAfternoon;
  }

  if (hour < 18) {
    return l10n.goodEvening;
  }

  return l10n.goodNight;
}

String _displayName(ResidentUser? resident) {
  final name = resident?.name.trim() ?? '';
  return name.isEmpty ? '' : name;
}

String _rawTowerValue(ResidentUnit? unit) {
  return unit?.tower.trim() ?? '';
}

String _rawUnitValue(ResidentUnit? unit) {
  return unit?.code.trim() ?? '';
}

String _rawResidentTypeValue(ResidentUser? resident) {
  return resident?.residentType.trim() ?? '';
}

String _towerLabel(ResidentUnit? unit) {
  final tower = _rawTowerValue(unit);
  return tower.isEmpty ? 'Assigned after activation' : tower;
}

String _unitLabel(ResidentUnit? unit) {
  final code = _rawUnitValue(unit);
  return code.isEmpty ? 'Pending assignment' : code;
}

String _residentTypeLabel(ResidentUser? resident) {
  final type = _rawResidentTypeValue(resident);
  return type.isEmpty ? 'Resident account' : type;
}

String _contractLabel(ResidentUser? resident) {
  final contractEndDate = resident?.contractEndDate.trim() ?? '';

  if (contractEndDate.isEmpty) {
    return 'Not available';
  }

  final parsedDate = DateTime.tryParse(contractEndDate);

  if (parsedDate == null) {
    return contractEndDate;
  }

  return DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
}

int _sortHighlights(CommunityAnnouncement left, CommunityAnnouncement right) {
  if (left.isPinned != right.isPinned) {
    return left.isPinned ? -1 : 1;
  }

  final rightDate = DateTime.tryParse(right.publishedAt);
  final leftDate = DateTime.tryParse(left.publishedAt);

  if (leftDate == null && rightDate == null) {
    return 0;
  }

  if (leftDate == null) {
    return 1;
  }

  if (rightDate == null) {
    return -1;
  }

  return rightDate.compareTo(leftDate);
}
