import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/white_premium_card.dart';
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
    final residentName = _displayName(widget.resident);
    final towerValue = _rawTowerValue(widget.resident?.unit);
    final unitValue = _rawUnitValue(widget.resident?.unit);
    final residentTypeValue = _rawResidentTypeValue(widget.resident);
    final towerLabel = _towerLabel(widget.resident?.unit);
    final unitLabel = _unitLabel(widget.resident?.unit);
    final residentTypeLabel = _residentTypeLabel(widget.resident);
    final contractLabel = _contractLabel(widget.resident);
    final selectedAnnouncementId = _selectedAnnouncement?.id;
    final summaryItems = [
      _SummaryData(label: 'Tower', value: towerLabel),
      _SummaryData(label: 'Unit', value: unitLabel),
      _SummaryData(label: 'Resident Type', value: residentTypeLabel),
      _SummaryData(label: 'Contract End', value: contractLabel),
    ];
    final quickActions = [
      _QuickAction(
        icon: Icons.qr_code_2_rounded,
        label: 'Visitor Pass',
        onTap: () => widget.onNavigate(1),
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        label: 'Profile',
        onTap: () => widget.onNavigate(4),
      ),
      _QuickAction(
        icon: Icons.handyman_rounded,
        label: 'Service',
        onTap: () => widget.onNavigate(2),
      ),
      _QuickAction(
        icon: Icons.groups_rounded,
        label: 'Community',
        onTap: () => widget.onNavigate(3),
      ),
    ];

    return ColoredBox(
      color: Colors.transparent,
      child: ListView(
        key: const ValueKey('resident-home-page'),
        padding: const EdgeInsets.only(bottom: 128),
        children: [
          _HeroHeaderStack(
            residentName: residentName,
            residentTypeLabel: residentTypeValue,
            towerLabel: towerValue,
            unitLabel: unitValue,
            onBillingTap: widget.onOpenBilling,
          ).animate().fadeIn(duration: 360.ms).moveY(begin: 18, end: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: WhitePremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Current Balance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(2850000),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service charge and facility maintenance due on 25 Jun 2026.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      _InfoChip(
                        label: 'Due Soon',
                        color: AppColors.warning,
                        background: Color(0xFFFFF2DE),
                      ),
                      SizedBox(width: 10),
                      _InfoChip(
                        label: 'Auto debit inactive',
                        color: AppColors.textSecondary,
                        background: AppColors.surfaceMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LuxuryButton(
                    key: const ValueKey('current-balance-billing-button'),
                    label: 'Open Billing',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onOpenBilling,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 480.ms).moveY(begin: 28, end: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'Quick Access',
                  actionLabel: 'Resident tools',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;

                    return GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1.65,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final action in quickActions)
                          _QuickAccessCard(action: action),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: WhitePremiumCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in summaryItems)
                    _SummaryItem(label: item.label, value: item.value),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 420.ms).moveY(begin: 24, end: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'Today Highlights',
                  actionLabel: 'Curated',
                ),
                const SizedBox(height: 14),
                if (_isLoadingHighlights)
                  const _HighlightsLoadingCard()
                else if (_highlightsError != null)
                  _HighlightsErrorCard(
                    message: _highlightsError!,
                    onRetry: _loadHighlights,
                  )
                else if (_highlights.isEmpty)
                  const _HighlightsEmptyCard()
                else
                  for (var index = 0; index < _highlights.length; index++) ...[
                    _ActivityCard(
                      icon: communityAnnouncementIconFor(_highlights[index]),
                      eyebrow: communityAnnouncementCategoryLabel(
                        _highlights[index].category,
                      ),
                      title: _highlights[index].title.isEmpty
                          ? 'Management update'
                          : _highlights[index].title,
                      detail: communityAnnouncementPreviewContent(
                        _highlights[index].content,
                        maxLength: 120,
                      ),
                      accent: communityAnnouncementAccentColor(
                        _highlights[index],
                      ),
                      actionLabel: communityAnnouncementPrimaryBadgeLabel(
                        _highlights[index],
                      ),
                      isSelected:
                          _isLoadingDetail &&
                          selectedAnnouncementId == _highlights[index].id,
                      onTap: () => _openHighlightDetail(_highlights[index]),
                    ),
                    if (index < _highlights.length - 1)
                      const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeaderStack extends StatelessWidget {
  const _HeroHeaderStack({
    required this.residentName,
    required this.residentTypeLabel,
    required this.towerLabel,
    required this.unitLabel,
    required this.onBillingTap,
  });

  final String residentName;
  final String residentTypeLabel;
  final String towerLabel;
  final String unitLabel;
  final VoidCallback onBillingTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 382,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _HeroHeader(
            residentName: residentName,
            residentTypeLabel: residentTypeLabel,
            towerLabel: towerLabel,
            unitLabel: unitLabel,
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 220,
            height: 96,
            child: IgnorePointer(child: _HeroFadeTransition()),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 258,
            child: _MonthlyBillingCard(onBillingTap: onBillingTap),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.residentName,
    required this.residentTypeLabel,
    required this.towerLabel,
    required this.unitLabel,
  });

  final String residentName;
  final String residentTypeLabel;
  final String towerLabel;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final heroBadges = [
      if (towerLabel.isNotEmpty) 'Tower $towerLabel',
      if (unitLabel.isNotEmpty) 'Unit $unitLabel',
      if (residentTypeLabel.isNotEmpty) residentTypeLabel,
    ];

    return Container(
      width: double.infinity,
      height: 306,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residentName.isEmpty
                            ? 'Good Evening'
                            : 'Good Evening, $residentName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your residence essentials, beautifully organized.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (heroBadges.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final badge in heroBadges) _HeroBadge(label: badge),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroFadeTransition extends StatelessWidget {
  const _HeroFadeTransition();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.background.withValues(alpha: 0.84),
            AppColors.background,
          ],
        ),
      ),
    );
  }
}

class _MonthlyBillingCard extends StatelessWidget {
  const _MonthlyBillingCard({required this.onBillingTap});

  final VoidCallback onBillingTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const _GoldIcon(icon: Icons.account_balance_wallet_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly billing status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'One invoice due in 6 days.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LuxuryButton(
            key: const ValueKey('monthly-billing-button'),
            label: 'Pay now',
            fullWidth: false,
            onPressed: onBillingTap,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoldIcon(icon: action.icon, size: 40, iconSize: 20),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldIcon extends StatelessWidget {
  const _GoldIcon({required this.icon, this.size = 52, this.iconSize = 24});

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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({required this.label, required this.value});

  final String label;
  final String value;
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.accent,
    required this.actionLabel,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String detail;
  final Color accent;
  final String actionLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = isSelected ? AppColors.gold : accent;
    return WhitePremiumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  eyebrow,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _InfoChip(
                label: actionLabel,
                color: chipColor,
                background: chipColor.withValues(alpha: 0.10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HighlightsLoadingCard extends StatelessWidget {
  const _HighlightsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading highlights...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Curating the latest management announcements for your home dashboard.',
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
    return WhitePremiumCard(
      child: Column(
        children: [
          const _GoldIcon(
            icon: Icons.error_outline_rounded,
            size: 52,
            iconSize: 24,
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

class _HighlightsEmptyCard extends StatelessWidget {
  const _HighlightsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        children: [
          const _GoldIcon(
            icon: Icons.notifications_paused_outlined,
            size: 52,
            iconSize: 24,
          ),
          const SizedBox(height: 14),
          Text(
            'No highlights available yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Fresh announcements from the management office will appear here.',
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
