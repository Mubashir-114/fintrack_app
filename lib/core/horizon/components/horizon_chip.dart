import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Telemetry filter and selection chip for FinTrack // HORIZON.
/// Selected state features a solid cyan rim, glowing surface, and a 4px active dot.
class HorizonChip extends StatelessWidget {
  const HorizonChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    final bgColor = selected ? tokens.surface2 : tokens.surface1;
    final borderColor = selected ? tokens.ionCyan : tokens.rimNeutral;
    final fgColor = selected ? tokens.ionCyan : tokens.textMedium;

    return Semantics(
      button: true,
      selected: selected,
      label: count != null ? '$label, $count items' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!selected),
          borderRadius: HorizonDimensions.borderDefault,
          child: AnimatedContainer(
            duration: HorizonMotion.quick,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: HorizonDimensions.borderDefault,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  // 4px circular active dot in Ion Cyan
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.ionCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, size: 14, color: fgColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: HorizonTypography.labelMd.copyWith(
                    color: fgColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '($count)',
                    style: HorizonTypography.bodySm.copyWith(
                      color: selected ? tokens.ionCyan : tokens.textLow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
