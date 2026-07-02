import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/resident_user.dart';
import '../../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.apiService,
    this.resident,
    this.currentLocale = const Locale('id'),
    this.onLocaleChanged,
  });

  final ApiService? apiService;
  final ResidentUser? resident;
  final Locale currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  var _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);

    await _apiService.logoutResident();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resident = widget.resident;
    final residentName = _profileName(resident);
    final residentType = _profileResidentType(resident);
    final residenceLabel = _profileResidence(resident);
    final towerFloorLabel = _profileTowerFloor(resident);
    final emailLabel = _profileValue(
      resident?.email,
      fallback: l10n.notProvided,
    );
    final phoneLabel = _profileValue(
      resident?.mobileNo,
      fallback: l10n.notProvided,
    );
    final contractLabel = _profileContractEndDate(resident);
    final residentIdLabel = resident == null
        ? l10n.pendingSync
        : '#${resident.id}';

    final hasUnit = resident?.unit.code.trim().isNotEmpty == true;

    final profileActions = [
      _ProfileAction(
        icon: Icons.notifications_none_rounded,
        title: l10n.notifications,
        subtitle: l10n.emailUpdates,
      ),
      _ProfileAction(
        icon: Icons.privacy_tip_outlined,
        title: l10n.privacy,
        subtitle: l10n.privacySubtitle,
      ),
      _ProfileAction(
        icon: Icons.support_agent_rounded,
        title: l10n.helpCenter,
        subtitle: l10n.helpCenterSubtitle,
      ),
    ];

    void showDemoSnack(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label ${l10n.simulatedForDemo}')),
      );
    }

    return ListView(
      key: const ValueKey('profile-page'),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        _ProfileHero(
          resident: resident,
          residentName: residentName,
          residentType: residentType,
          residenceLabel: residenceLabel,
          residentIdLabel: residentIdLabel,
          contractLabel: contractLabel,
          hasUnit: hasUnit,
          profileLabel: l10n.residentProfile,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _SectionHeader(title: l10n.residentIdentity.toUpperCase()),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _ProfileInformationCard(
            residenceLabel: residenceLabel,
            towerFloorLabel: towerFloorLabel,
            emailLabel: emailLabel,
            phoneLabel: phoneLabel,
            contractLabel: contractLabel,
            residentIdLabel: residentIdLabel,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: _SectionHeader(title: l10n.accountSettings.toUpperCase()),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _LanguagePreferenceCard(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              for (var index = 0; index < profileActions.length; index++) ...[
                _ProfileActionTile(
                  action: profileActions[index],
                  onTap: () => showDemoSnack(profileActions[index].title),
                ),
                if (index < profileActions.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: _SectionHeader(title: l10n.account.toUpperCase()),
        ),

        // Padding(
        //   padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        //   child: LuxuryButton(
        //     label: l10n.editProfile,
        //     icon: Icons.edit_outlined,
        //     onPressed: () => showDemoSnack(l10n.editProfile),
        //   ),
        // ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: AbsorbPointer(
            absorbing: _isLoggingOut,
            child: Opacity(
              opacity: _isLoggingOut ? 0.72 : 1,
              child: LuxuryButton(
                key: const ValueKey('logout-button'),
                label: _isLoggingOut ? l10n.signingOut : l10n.logout,
                icon: Icons.logout_rounded,
                danger: true,
                variant: LuxuryButtonVariant.secondary,
                onPressed: _handleLogout,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.resident,
    required this.residentName,
    required this.residentType,
    required this.residenceLabel,
    required this.residentIdLabel,
    required this.contractLabel,
    required this.hasUnit,
    required this.profileLabel,
  });

  final ResidentUser? resident;
  final String residentName;
  final String residentType;
  final String residenceLabel;
  final String residentIdLabel;
  final String contractLabel;
  final bool hasUnit;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 370,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 264,
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
            right: -22,
            bottom: 84,
            child: Icon(
              Icons.person_rounded,
              size: 220,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 34,
            top: 40,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileAvatar(initials: _profileInitials(resident)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileLabel,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            residentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            residentType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 192,
            left: 20,
            right: 20,
            child: _ProfileSummaryCard(
              residenceLabel: residenceLabel,
              residentIdLabel: residentIdLabel,
              contractLabel: contractLabel,
              hasUnit: hasUnit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.56),
          width: 2,
        ),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.residenceLabel,
    required this.residentIdLabel,
    required this.contractLabel,
    required this.hasUnit,
  });

  final String residenceLabel;
  final String residentIdLabel;
  final String contractLabel;
  final bool hasUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WhitePremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.gold,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residenceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residentIdLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusIcon(
                icon: hasUnit ? Icons.verified_rounded : Icons.pending_outlined,
                color: hasUnit ? AppColors.success : AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _ProfileSummaryValue(
                  label: l10n.profileStatus.toUpperCase(),
                  value: l10n.linked,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.borderSoft),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _ProfileSummaryValue(
                    label: l10n.contractEnd.toUpperCase(),
                    value: contractLabel,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _ProfileSummaryValue extends StatelessWidget {
  const _ProfileSummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileInformationCard extends StatelessWidget {
  const _ProfileInformationCard({
    required this.residenceLabel,
    required this.towerFloorLabel,
    required this.emailLabel,
    required this.phoneLabel,
    required this.contractLabel,
    required this.residentIdLabel,
  });

  final String residenceLabel;
  final String towerFloorLabel;
  final String emailLabel;
  final String phoneLabel;
  final String contractLabel;
  final String residentIdLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      _ProfileInfoData(
        icon: Icons.apartment_rounded,
        label: l10n.residence,
        value: residenceLabel,
      ),
      _ProfileInfoData(
        icon: Icons.layers_rounded,
        label: l10n.towerAndFloor,
        value: towerFloorLabel,
      ),
      _ProfileInfoData(
        icon: Icons.mail_outline_rounded,
        label: l10n.email,
        value: emailLabel,
      ),
      _ProfileInfoData(
        icon: Icons.phone_outlined,
        label: l10n.phone,
        value: phoneLabel,
      ),
      _ProfileInfoData(
        icon: Icons.calendar_month_outlined,
        label: l10n.contractEnd,
        value: contractLabel,
      ),
      _ProfileInfoData(
        icon: Icons.badge_outlined,
        label: l10n.residentId,
        value: residentIdLabel,
      ),
    ];

    return WhitePremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _InfoRow(
              icon: items[index].icon,
              label: items[index].label,
              value: items[index].value,
            ),
            if (index < items.length - 1) ...[
              const SizedBox(height: 13),
              Container(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 13),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoData {
  const _ProfileInfoData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _LanguagePreferenceCard extends StatelessWidget {
  const _LanguagePreferenceCard({
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final Locale currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLanguageCode = currentLocale.languageCode;

    return WhitePremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.gold,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseLanguage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _LanguageChip(
            label: 'ID',
            semanticLabel: l10n.indonesian,
            selected: activeLanguageCode == 'id',
            onTap: () => onLocaleChanged?.call(const Locale('id')),
          ),
          const SizedBox(width: 8),
          _LanguageChip(
            label: 'EN',
            semanticLabel: l10n.english,
            selected: activeLanguageCode == 'en',
            onTap: () => onLocaleChanged?.call(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.borderSoft,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.action, required this.onTap});

  final _ProfileAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(action.icon, color: AppColors.navy, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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

String _profileInitials(ResidentUser? resident) {
  final source = _profileName(resident).trim();

  if (source.isEmpty) {
    return 'AH';
  }

  final parts = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final buffer = StringBuffer();

  for (final part in parts.take(2)) {
    buffer.write(part.substring(0, 1).toUpperCase());
  }

  final initials = buffer.toString();

  return initials.isEmpty ? 'AH' : initials;
}

String _profileName(ResidentUser? resident) {
  final name = resident?.name.trim() ?? '';

  return name.isEmpty ? 'Resident Profile' : name;
}

String _profileResidentType(ResidentUser? resident) {
  final type = resident?.residentType.trim() ?? '';

  return type.isEmpty ? 'Resident Account' : type;
}

String _profileResidence(ResidentUser? resident) {
  final unit = resident?.unit;
  final unitCode = unit?.code.trim() ?? '';
  final tower = unit?.tower.trim() ?? '';

  if (tower.isNotEmpty && unitCode.isNotEmpty) {
    return 'Tower $tower - Unit $unitCode';
  }

  if (unitCode.isNotEmpty) {
    return 'Unit $unitCode';
  }

  if (tower.isNotEmpty) {
    return 'Tower $tower';
  }

  return 'Assigned after activation';
}

String _profileTowerFloor(ResidentUser? resident) {
  final unit = resident?.unit;
  final tower = unit?.tower.trim() ?? '';
  final floor = unit?.floor ?? 0;

  final parts = <String>[
    if (tower.isNotEmpty) 'Tower $tower',
    if (floor > 0) 'Floor $floor',
  ];

  return parts.isEmpty ? 'Information unavailable' : parts.join(', ');
}

String _profileValue(String? value, {required String fallback}) {
  final text = value?.trim() ?? '';

  return text.isEmpty ? fallback : text;
}

String _profileContractEndDate(ResidentUser? resident) {
  final contractEndDate = resident?.contractEndDate.trim() ?? '';

  if (contractEndDate.isEmpty) {
    return 'Not provided';
  }

  final parsedDate = DateTime.tryParse(contractEndDate);

  if (parsedDate == null) {
    return contractEndDate;
  }

  return DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
}
