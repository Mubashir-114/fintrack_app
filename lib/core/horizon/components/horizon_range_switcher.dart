import 'package:flutter/material.dart';

import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Animated segmented range switch for financial periods.
///
/// A single sliding pill marks the active segment so period changes read as
/// one continuous instrument rather than three independent chips.
class HorizonRangeSwitcher extends StatelessWidget {
  const HorizonRangeSwitcher({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.customLabel,
    this.onCustomSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? customLabel;
  final VoidCallback? onCustomSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool hasCustom = onCustomSelected != null;

    return Container(
      height: MediaQuery.textScalerOf(context).scale(12) > 16 ? 76 : 40,
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: HorizonDimensions.borderFull,
        border: Border.all(color: tokens.rimNeutral),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++)
            _Segment(
              label: options[i],
              selected: i == selectedIndex,
              isFirst: i == 0,
              onTap: () => onSelected(i),
            ),
          if (hasCustom) ...[
            Container(width: 1, height: 22, color: tokens.rimNeutral),
            _CustomSegment(label: customLabel, onTap: onCustomSelected!),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: HorizonDimensions.borderFull,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : HorizonMotion.quick,
            curve: HorizonMotion.emphasized,
            height: MediaQuery.textScalerOf(context).scale(12) > 16 ? 76 : 40,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: isFirst ? 3 : 0, right: 0),
            decoration: BoxDecoration(
              color: selected ? tokens.surface3 : Colors.transparent,
              borderRadius: HorizonDimensions.borderFull,
            ),
            child: Text(
              label,
              maxLines: MediaQuery.textScalerOf(context).scale(12) > 16 ? 2 : 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: HorizonTypography.labelMd.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? tokens.textHigh : tokens.textMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomSegment extends StatelessWidget {
  const _CustomSegment({required this.label, required this.onTap});

  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool active = label != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HorizonDimensions.borderFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: active ? tokens.ionCyan : tokens.textMedium,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 88),
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HorizonTypography.labelMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.ionCyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
