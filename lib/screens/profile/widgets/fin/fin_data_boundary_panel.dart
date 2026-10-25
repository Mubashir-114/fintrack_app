import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';

/// Reusable trustworthy privacy & data boundary panel for FIN.
class FinDataBoundaryPanel extends StatelessWidget {
  const FinDataBoundaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.rimNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with shield icon
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.luminousGold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: tokens.luminousGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Boundaries & Privacy',
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Strict safeguards on your financial information',
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textMedium,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Point 1: Authorized saved records
          _buildItem(
            tokens: tokens,
            icon: Icons.check_circle_outline,
            title: 'Authorized records only',
            detail:
                'FIN evaluates only your saved transactions and envelope limits stored on the FinTrack backend.',
          ),
          const SizedBox(height: 10),

          // Point 2: No direct bank access
          _buildItem(
            tokens: tokens,
            icon: Icons.account_balance_outlined,
            title: 'No direct bank account link',
            detail:
                'FIN never connects directly to your external banking credentials or account logins.',
          ),
          const SizedBox(height: 10),

          // Point 3: No independent SMS reading
          _buildItem(
            tokens: tokens,
            icon: Icons.phonelink_lock_outlined,
            title: 'No inbox or SMS access',
            detail:
                'FIN cannot independently read your SMS inbox or notifications without explicit user import.',
          ),
          const SizedBox(height: 14),

          // Verification badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.surface3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.rimNeutral.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: tokens.ionCyan,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bounded, deterministic backend analysis',
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.ionCyan,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required HorizonThemeTokens tokens,
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tokens.ionCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                detail,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
