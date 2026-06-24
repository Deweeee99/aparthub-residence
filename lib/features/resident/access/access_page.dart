import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/resident_user.dart';
import 'visitor_management_page.dart';

enum _AccessSubview { hub, create, history }

class AccessPage extends StatefulWidget {
  const AccessPage({
    super.key,
    this.resident,
  });

  final ResidentUser? resident;

  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  var _activeSubview = _AccessSubview.hub;

  void _openCreateFlow() {
    setState(() => _activeSubview = _AccessSubview.create);
  }

  void _openHistory() {
    setState(() => _activeSubview = _AccessSubview.history);
  }

  void _backToHub() {
    setState(() => _activeSubview = _AccessSubview.hub);
  }

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
          resident: widget.resident,
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
    required this.resident,
    required this.onCreateVisitor,
    required this.onOpenHistory,
  });

  final ResidentUser? resident;
  final VoidCallback onCreateVisitor;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      key: const ValueKey('access-page'),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        const _AccessHero(),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: _ResidentUnitCard(resident: resident),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: _SectionHeader(title: l10n.visitorAccessSection.toUpperCase()),
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
              _AccessActionCard(
                icon: Icons.person_add_alt_1_rounded,
                title: l10n.registerVisitor.replaceFirst(' ', '\n'),
                subtitle: 'Buat akses dan QR pass untuk tamu.',
                accentColor: AppColors.gold,
                iconBackground: AppColors.goldSoft,
                buttonLabel: l10n.registerVisitor,
                onTap: onCreateVisitor,
              ),
              _AccessActionCard(
                icon: Icons.history_rounded,
                title: l10n.visitorHistory.replaceFirst(' ', '\n'),
                subtitle: 'Lihat status kunjungan dan data tamu.',
                accentColor: AppColors.navy,
                iconBackground: AppColors.blueSoft,
                buttonLabel: l10n.viewHistory,
                onTap: onOpenHistory,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: _SectionHeader(title: l10n.accessInformation.toUpperCase()),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _AccessInformationCard(),
        ),
      ],
    );
  }
}

class _AccessHero extends StatelessWidget {
  const _AccessHero();

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
            right: -25,
            bottom: -30,
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 210,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 36,
            top: 52,
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
                      Icons.groups_2_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.visitorAccess,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola kunjungan tamu dan akses QR secara aman.',
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

class _ResidentUnitCard extends StatelessWidget {
  const _ResidentUnitCard({
    required this.resident,
  });

  final ResidentUser? resident;

  @override
  Widget build(BuildContext context) {
    final displayName = _residentDisplayName(resident);
    final unitLabel = _residentUnitLabel(context, resident?.unit);

    return Transform.translate(
      offset: const Offset(0, -22),
      child: WhitePremiumCard(
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
                Icons.apartment_rounded,
                color: AppColors.gold,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unitLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Akses visitor untuk $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.gold,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessActionCard extends StatelessWidget {
  const _AccessActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.iconBackground,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color iconBackground;
  final String buttonLabel;
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
                    height: 1.3,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  buttonLabel,
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

class _AccessInformationCard extends StatelessWidget {
  const _AccessInformationCard();

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
                  l10n.visitorQrPass,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Setiap visitor yang didaftarkan akan memiliki QR pass untuk proses verifikasi oleh security saat masuk.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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

String _residentDisplayName(ResidentUser? resident) {
  final name = resident?.name.trim() ?? '';
  return name.isEmpty ? 'Resident' : name;
}

String _residentUnitLabel(BuildContext context, ResidentUnit? unit) {
  final l10n = AppLocalizations.of(context);
  final tower = unit?.tower.trim() ?? '';
  final code = unit?.code.trim() ?? '';

  final parts = <String>[];

  if (tower.isNotEmpty) {
    parts.add(_withLabelIfNeeded(label: l10n.tower, value: tower));
  }

  if (code.isNotEmpty) {
    parts.add(_withLabelIfNeeded(label: l10n.unit, value: code));
  }

  if (parts.isEmpty) {
    return 'Unit belum ditentukan';
  }

  return parts.join(' • ');
}

String _withLabelIfNeeded({
  required String label,
  required String value,
}) {
  final normalizedValue = value.toLowerCase();
  final normalizedLabel = label.toLowerCase();

  if (normalizedValue.startsWith(normalizedLabel)) {
    return value;
  }

  return '$label $value';
}