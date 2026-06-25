import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/white_premium_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

class VisitorQrCard extends StatelessWidget {
  const VisitorQrCard({
    super.key,
    required this.title,
    required this.code,
    required this.visitorName,
    required this.schedule,
    required this.status,
    this.qrPayload,
    this.countdownText,
    this.onShare,
  });

  final String title;
  final String code;
  final String visitorName;
  final String schedule;
  final String status;
  final String? qrPayload;
  final String? countdownText;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final qrData = (qrPayload?.trim().isNotEmpty == true ? qrPayload : code)
        ?.trim();

    return WhitePremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Visitor Pass - $visitorName - $schedule',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData?.isNotEmpty == true
                  ? qrData!
                  : 'VISITOR-PASS-UNAVAILABLE',
              version: QrVersions.auto,
              size: 176,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: [
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (countdownText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    countdownText!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (onShare != null) ...[
            const SizedBox(height: 14),
            LuxuryButton(
              label: l10n.shareQr,
              icon: Icons.ios_share_outlined,
              onPressed: onShare!,
            ),
          ],
        ],
      ),
    );
  }
}
