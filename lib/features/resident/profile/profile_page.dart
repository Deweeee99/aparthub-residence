import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/luxury_button.dart';
import '../../../core/widgets/white_premium_card.dart';
import '../../../data/data_dummy/resident_profile_dummy.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'NP',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ResidentProfileDummy.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ResidentProfileDummy.role,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StatusPill(
                    label: ResidentProfileDummy.status,
                    color: AppColors.success,
                  ),
                  _StatusPill(
                    label: ResidentProfileDummy.accessStatus,
                    color: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const WhitePremiumCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.apartment_rounded,
                label: 'Residence',
                value: ResidentProfileDummy.unitLabel,
              ),
              _InfoRow(
                icon: Icons.layers_rounded,
                label: 'Tower & Floor',
                value:
                    '${ResidentProfileDummy.tower}, ${ResidentProfileDummy.floor}',
              ),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: ResidentProfileDummy.email,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: ResidentProfileDummy.phone,
              ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Membership',
                value: ResidentProfileDummy.joinedDate,
              ),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'Emergency',
                value: ResidentProfileDummy.emergencyContact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final item in ResidentProfileDummy.preferences)
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
      ],
    );
  }
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
