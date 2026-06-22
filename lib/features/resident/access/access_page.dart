import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/visitor_access_dummy.dart';
import 'visitor_management_page.dart';

enum _AccessSubview { hub, create, history }

class AccessPage extends StatefulWidget {
  const AccessPage({super.key});

  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  var _activeSubview = _AccessSubview.hub;

  void _openCreateFlow() =>
      setState(() => _activeSubview = _AccessSubview.create);

  void _openHistory() =>
      setState(() => _activeSubview = _AccessSubview.history);

  void _backToHub() => setState(() => _activeSubview = _AccessSubview.hub);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: switch (_activeSubview) {
        _AccessSubview.create => VisitorManagementPage(
          key: const ValueKey('visitor-create-flow'),
          onBack: _backToHub,
          initialMode: VisitorManagementInitialMode.create,
        ),
        _AccessSubview.history => VisitorManagementPage(
          key: const ValueKey('visitor-history-flow'),
          onBack: _backToHub,
          initialMode: VisitorManagementInitialMode.history,
        ),
        _ => _AccessHub(
          key: const ValueKey('visitor-access-hub'),
          onCreateVisitor: _openCreateFlow,
          onOpenHistory: _openHistory,
        ),
      },
    );
  }
}

class _AccessHub extends StatelessWidget {
  const _AccessHub({
    super.key,
    required this.onCreateVisitor,
    required this.onOpenHistory,
  });

  final VoidCallback onCreateVisitor;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('access-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        Text(
          'Visitor Access',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Register visitors, generate QR passes, and review visitor activity.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        WhitePremiumCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VisitorAccessDummy.unitLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resident ${VisitorAccessDummy.residentName} visitor desk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AccessFeatureCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Create Visitor Access',
          subtitle: 'Register a visitor and generate a secure QR pass.',
          actionLabel: 'Start Registration',
          onTap: onCreateVisitor,
        ),
        const SizedBox(height: 14),
        _AccessFeatureCard(
          icon: Icons.history_rounded,
          title: 'Visitor History',
          subtitle: 'Review upcoming, checked-in, and past visitor records.',
          actionLabel: 'Open History',
          onTap: onOpenHistory,
        ),
      ],
    );
  }
}

class _AccessFeatureCard extends StatelessWidget {
  const _AccessFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.gold,
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
