import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('community-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        Text(
          'Community',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Stay connected with building announcements, events, and resident groups.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        const _CommunityCard(
          title: 'Rooftop Acoustic Evening',
          subtitle: 'Saturday, 20 June 2026 • 19:30',
          badge: 'Open RSVP',
        ),
        const SizedBox(height: 12),
        const _CommunityCard(
          title: 'New parcel handling policy',
          subtitle: 'Updated by concierge management',
          badge: 'Important',
        ),
        const SizedBox(height: 12),
        WhitePremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resident feedback',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Share your suggestion',
                  hintText:
                      'Tell management what would improve your experience.',
                ),
              ),
              const SizedBox(height: 16),
              LuxuryButton(
                label: 'Send feedback',
                icon: Icons.send_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
