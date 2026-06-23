import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../models/resident_user.dart';
import '../../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.apiService, this.resident});

  final ApiService? apiService;
  final ResidentUser? resident;

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
    final resident = widget.resident;
    final residentName = _profileName(resident);
    final residentType = _profileResidentType(resident);
    final residenceLabel = _profileResidence(resident);
    final towerFloorLabel = _profileTowerFloor(resident);
    final emailLabel = _profileValue(resident?.email, fallback: 'Not provided');
    final phoneLabel = _profileValue(
      resident?.mobileNo,
      fallback: 'Not provided',
    );
    final contractLabel = _profileContractEndDate(resident);
    final residentIdLabel = resident == null
        ? 'Pending sync'
        : '#${resident.id}';
    final profileActions = const [
      ('Notifications', 'Building alerts, visitor pass, service updates'),
      ('Privacy', 'Profile visibility and contact preferences'),
      ('Help Center', 'Concierge support and resident assistance'),
    ];

    void showDemoSnack(String label) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label is simulated for demo.')));
    }

    return ListView(
      key: const ValueKey('profile-page'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
      children: [
        Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your resident identity, access status, and account settings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        WhitePremiumCard(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  _profileInitials(resident),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                residentName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(residentType, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  const _StatusPill(
                    label: 'Profile Linked',
                    color: AppColors.success,
                  ),
                  _StatusPill(
                    label: resident?.unit.code.trim().isNotEmpty == true
                        ? 'Unit Registered'
                        : 'Awaiting Unit Sync',
                    color: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WhitePremiumCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.apartment_rounded,
                label: 'Residence',
                value: residenceLabel,
              ),
              _InfoRow(
                icon: Icons.layers_rounded,
                label: 'Tower & Floor',
                value: towerFloorLabel,
              ),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: emailLabel,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phoneLabel,
              ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Contract End',
                value: contractLabel,
              ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Resident ID',
                value: residentIdLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final item in profileActions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActionTile(
              title: item.$1,
              subtitle: item.$2,
              onTap: () => showDemoSnack(item.$1),
            ),
          ),
        const SizedBox(height: 4),
        LuxuryButton(
          label: 'Edit Profile',
          icon: Icons.edit_outlined,
          onPressed: () => showDemoSnack('Edit Profile'),
        ),
        const SizedBox(height: 12),
        AbsorbPointer(
          absorbing: _isLoggingOut,
          child: Opacity(
            opacity: _isLoggingOut ? 0.72 : 1,
            child: LuxuryButton(
              key: const ValueKey('logout-button'),
              label: _isLoggingOut ? 'Signing Out...' : 'Logout',
              icon: Icons.logout_rounded,
              danger: true,
              variant: LuxuryButtonVariant.secondary,
              onPressed: _handleLogout,
            ),
          ),
        ),
      ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhitePremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.settings_outlined, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
