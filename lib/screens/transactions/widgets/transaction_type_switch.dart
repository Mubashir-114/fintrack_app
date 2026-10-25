import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';

/// Income / expense switch with a sliding accent pill.
///
/// One track, two labels and a moving selection instead of two boxed buttons,
/// so the composer keeps a single focal surface.
class TransactionTypeSwitch extends StatelessWidget {
  const TransactionTypeSwitch({
    super.key,
    required this.isIncome,
    required this.onChanged,
  });

  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final accent = isIncome ? tokens.surplus : tokens.outflow;
    final duration = reduceMotion ? Duration.zero : HorizonMotion.quick;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: HorizonDimensions.borderFull,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = (constraints.maxWidth - 3) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: isIncome
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                duration: duration,
                curve: HorizonMotion.emphasized,
                child: AnimatedContainer(
                  duration: duration,
                  curve: HorizonMotion.emphasized,
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: tokens.isDark ? 0.16 : 0.1),
                    borderRadius: HorizonDimensions.borderFull,
                    border: Border.all(color: accent.withValues(alpha: 0.38)),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _Segment(
                      key: const ValueKey('transaction-type-expense'),
                      label: 'Expense',
                      icon: Icons.north_east_rounded,
                      selected: !isIncome,
                      accent: tokens.outflow,
                      onPressed: () => onChanged(false),
                    ),
                  ),
                  Expanded(
                    child: _Segment(
                      key: const ValueKey('transaction-type-income'),
                      label: 'Income',
                      icon: Icons.south_west_rounded,
                      selected: isIncome,
                      accent: tokens.surplus,
                      onPressed: () => onChanged(true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      label: label,
      selected: selected,
      onPressed: onPressed,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? accent : tokens.textMedium),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.bodyMd.copyWith(
                  color: selected ? tokens.textHigh : tokens.textMedium,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
