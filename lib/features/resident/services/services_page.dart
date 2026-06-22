import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/service_request_dummy.dart';
import 'service_request_page.dart';

enum _ServiceSubview { hub, request, history }

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  var _activeSubview = _ServiceSubview.hub;

  void _openRequest() =>
      setState(() => _activeSubview = _ServiceSubview.request);

  void _openHistory() =>
      setState(() => _activeSubview = _ServiceSubview.history);

  void _backToHub() => setState(() => _activeSubview = _ServiceSubview.hub);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: switch (_activeSubview) {
        _ServiceSubview.request => ServiceRequestPage(
          key: const ValueKey('service-request-flow'),
          onBack: _backToHub,
          initialMode: ServiceRequestInitialMode.create,
        ),
        _ServiceSubview.history => ServiceRequestPage(
          key: const ValueKey('service-history-flow'),
          onBack: _backToHub,
          initialMode: ServiceRequestInitialMode.history,
        ),
        _ => _ServicesHub(
          key: const ValueKey('services-hub'),
          onCreateRequest: _openRequest,
          onOpenHistory: _openHistory,
        ),
      },
    );
  }
}

class _ServicesHub extends StatelessWidget {
  const _ServicesHub({
    super.key,
    required this.onCreateRequest,
    required this.onOpenHistory,
  });

  final VoidCallback onCreateRequest;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('services-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        Text(
          'Services',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Create maintenance requests and monitor every service ticket.',
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
                      ServiceRequestDummy.unitLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resident ${ServiceRequestDummy.residentName} service desk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ServiceFeatureCard(
          icon: Icons.build_circle_outlined,
          title: 'Service Request',
          subtitle: 'Maintenance, plumbing, electrical, and housekeeping.',
          actionLabel: 'Create Request',
          onTap: onCreateRequest,
        ),
        const SizedBox(height: 14),
        _ServiceFeatureCard(
          icon: Icons.history_rounded,
          title: 'Service History',
          subtitle: 'Track open, assigned, in-progress, and completed tickets.',
          actionLabel: 'Open History',
          onTap: onOpenHistory,
        ),
      ],
    );
  }
}

class _ServiceFeatureCard extends StatelessWidget {
  const _ServiceFeatureCard({
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
