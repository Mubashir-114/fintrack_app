import 'package:flutter/material.dart';
import '../../../../core/horizon/horizon.dart';

/// Reusable status badge for FIN companion's current presence and state.
class FinStatusChip extends StatelessWidget {
  final bool isActive;
  final bool isDocked;
  final String? placement;
  final String? subtitle;

  const FinStatusChip({
    super.key,
    required this.isActive,
    this.isDocked = false,
    this.placement,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    Color dotColor;
    String statusLabel;
    IconData icon;

    if (!isActive) {
      dotColor = tokens.outflow.withValues(alpha: 0.8);
      statusLabel = 'DEACTIVATED';
      icon = Icons.visibility_off_outlined;
    } else if (isDocked) {
      dotColor = tokens.luminousGold;
      statusLabel = 'DOCKED REST';
      icon = Icons.nightlight_outlined;
    } else {
      dotColor = tokens.ionCyan;
      statusLabel = 'ACTIVE & PRESENT';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surface3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? (isDocked
                  ? tokens.luminousGold.withValues(alpha: 0.35)
                  : tokens.rimCyan)
              : tokens.rimNeutral,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: dotColor),
            const SizedBox(width: 5),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: HorizonTypography.labelCaps.copyWith(
                color: dotColor,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
            if (placement != null && isActive) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: tokens.textMedium.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                placement!.toUpperCase(),
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textMedium,
                  letterSpacing: 0.8,
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
