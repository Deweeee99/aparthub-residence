import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/api_service.dart';
import 'service_request/service_request_flow_scope.dart';
import 'service_request/service_request_routes.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  @override
  Widget build(BuildContext context) {
    return _ServicesHub(
      key: const ValueKey('services-hub'),
      onCreateRequest: () {
        ServiceRequestFlowScope.of(context).resetCreateFlow();
        context.push(ServiceRequestRoutes.create);
      },
      onOpenHistory: () => context.push(ServiceRequestRoutes.history),
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
    final l10n = AppLocalizations.of(context);

    return ListView(
      key: const ValueKey('services-page'),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        const _ServicesHero(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: const _ServiceDeskCard(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: _SectionHeader(title: l10n.technicalServices.toUpperCase()),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
            children: [
              _ServiceActionCard(
                icon: Icons.build_circle_outlined,
                title: l10n.createServiceRequest.replaceFirst(' ', '\n'),
                subtitle: l10n.serviceRequestCardSubtitle,
                actionLabel: l10n.submitRequest,
                accentColor: AppColors.gold,
                iconBackground: AppColors.goldSoft,
                onTap: onCreateRequest,
              ),
              _ServiceActionCard(
                icon: Icons.history_rounded,
                title: l10n.serviceHistory.replaceFirst(' ', '\n'),
                subtitle: l10n.serviceHistoryCardSubtitle,
                actionLabel: l10n.viewServiceHistory,
                accentColor: AppColors.navy,
                iconBackground: AppColors.blueSoft,
                onTap: onOpenHistory,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: _SectionHeader(title: l10n.serviceInformation.toUpperCase()),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: const _ServiceInformationCard(),
        ),
      ],
    );
  }
}

class _ServicesHero extends StatelessWidget {
  const _ServicesHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 238,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF103B86), AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -28,
            child: Icon(
              Icons.handyman_rounded,
              size: 205,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 30,
            top: 44,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                      Icons.handyman_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.serviceRequest,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.serviceHeroSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDeskCard extends StatelessWidget {
  const _ServiceDeskCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.serviceDesk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.serviceDeskSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.verified_outlined, color: AppColors.gold, size: 24),
        ],
      ),
    );
  }
}

class _ServiceActionCard extends StatelessWidget {
  const _ServiceActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.accentColor,
    required this.iconBackground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color accentColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 14),
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
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accentColor, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceInformationCard extends StatelessWidget {
  const _ServiceInformationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.navy,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.handlingFlowTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.handlingFlowBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.42,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }
}
