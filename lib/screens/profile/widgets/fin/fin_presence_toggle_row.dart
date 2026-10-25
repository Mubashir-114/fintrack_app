import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';

/// Reusable toggle row for FIN presence controls across app screens.
class FinPresenceToggleRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const FinPresenceToggleRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final effectiveIconColor = iconColor ?? tokens.ionCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tokens.surface3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.rimNeutral),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HorizonTypography.bodyMd.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: tokens.ionCyan,
            activeTrackColor: tokens.ionCyan.withValues(alpha: 0.35),
            inactiveThumbColor: tokens.textMedium,
            inactiveTrackColor: tokens.surface3,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Specialized row for deactivating or restoring FIN completely.
class FinDeactivateCard extends StatelessWidget {
  final bool isDeactivated;
  final VoidCallback onToggle;

  const FinDeactivateCard({
    super.key,
    required this.isDeactivated,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDeactivated
              ? tokens.outflow.withValues(alpha: 0.4)
              : tokens.rimNeutral,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isDeactivated
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDeactivated ? tokens.outflow : tokens.textMedium,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isDeactivated
                            ? 'FIN is currently hidden'
                            : 'Hide FIN Completely',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodyMd.copyWith(
                          color: tokens.textHigh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: tokens.surface3,
                  foregroundColor:
                      isDeactivated ? tokens.ionCyan : tokens.outflow,
                  side: BorderSide(
                    color: isDeactivated
                        ? tokens.ionCyan
                        : tokens.outflow.withValues(alpha: 0.4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onToggle,
                child: Text(
                  isDeactivated ? 'RESTORE' : 'DEACTIVATE',
                  style: HorizonTypography.labelCaps.copyWith(
                    color: isDeactivated ? tokens.ionCyan : tokens.outflow,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isDeactivated
                ? 'FIN is silenced across the application. Tap Restore to re-enable.'
                : 'Silences all floating companion moments. You can restore FIN at any time.',
            style: HorizonTypography.bodySm.copyWith(
              color: tokens.textMedium,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
