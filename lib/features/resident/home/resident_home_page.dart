import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/white_premium_card.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class ResidentHomePage extends StatelessWidget {
  const ResidentHomePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      _QuickAction(
        icon: Icons.qr_code_2_rounded,
        label: 'Visitor Pass',
        onTap: () => onNavigate(1),
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        label: 'Profile',
        onTap: () => onNavigate(4),
      ),
      _QuickAction(
        icon: Icons.handyman_rounded,
        label: 'Service',
        onTap: () => onNavigate(2),
      ),
      _QuickAction(
        icon: Icons.groups_rounded,
        label: 'Community',
        onTap: () => onNavigate(3),
      ),
    ];

    return ColoredBox(
      color: Colors.transparent,
      child: ListView(
        key: const ValueKey('resident-home-page'),
        padding: const EdgeInsets.only(bottom: 128),
        children: [
          _HeroHeaderStack(
            onBillingTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Billing is currently unavailable in this package.',
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: 360.ms).moveY(begin: 18, end: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
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
                children: const [
                  _SummaryItem(label: 'Tower', value: 'Asteria'),
                  _SummaryItem(label: 'Unit', value: 'A-1808'),
                  _SummaryItem(label: 'Access', value: '3 active passes'),
                  _SummaryItem(label: 'Packages', value: '2 waiting pickup'),
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
                _ActivityCard(
                  icon: Icons.calendar_today_rounded,
                  eyebrow: 'Facility Booking',
                  title: 'Sky Lounge reserved tonight',
                  detail: 'Friday, 19 June 2026 • 19:00 - 21:00',
                  accent: AppColors.info,
                  actionLabel: 'View booking',
                ),
                const SizedBox(height: 12),
                _ActivityCard(
                  icon: Icons.inventory_2_rounded,
                  eyebrow: 'Concierge Update',
                  title: '2 packages ready at lobby desk',
                  detail: 'Pickup before 22:00 with resident QR verification.',
                  accent: AppColors.gold,
                  actionLabel: 'Open access',
                ),
                const SizedBox(height: 12),
                _ActivityCard(
                  icon: Icons.campaign_rounded,
                  eyebrow: 'Community Notice',
                  title: 'Weekend acoustic evening at rooftop garden',
                  detail: 'Reserve seats early from the community tab.',
                  accent: AppColors.success,
                  actionLabel: 'See details',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                    label: 'Billing unavailable',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Billing is currently unavailable in this package.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 480.ms).moveY(begin: 28, end: 0),
        ],
      ),
    );
  }
}

class _HeroHeaderStack extends StatelessWidget {
  const _HeroHeaderStack({required this.onBillingTap});

  final VoidCallback onBillingTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 382,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _HeroHeader(),
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
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
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
                        'Good Evening, Nadia',
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _HeroBadge(label: 'Tower Asteria'),
                _HeroBadge(label: 'Unit A-1808'),
                _HeroBadge(label: 'Resident since 2024'),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.accent,
    required this.actionLabel,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String detail;
  final Color accent;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
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
                color: accent,
                background: accent.withValues(alpha: 0.10),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
