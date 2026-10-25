import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';

/// Reusable placement and screen docking selector for FIN companion.
class FinPlacementSelector extends StatelessWidget {
  final String placement;
  final ValueChanged<String> onPlacementChanged;
  final VoidCallback onResetPosition;

  static const List<String> placementModes = [
    'Right Edge',
    'Left Edge',
    'Dock Trigger',
  ];

  const FinPlacementSelector({
    super.key,
    required this.placement,
    required this.onPlacementChanged,
    required this.onResetPosition,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Subheader & Selected indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Screen Placement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.surface3,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.rimNeutral),
              ),
              child: Text(
                placement.toUpperCase(),
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.ionCyan,
                  letterSpacing: 1.0,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3 Segmented buttons with responsive flex
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tokens.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.rimNeutral),
          ),
          child: Row(
            children: [
              for (final mode in placementModes)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: placement == mode,
                    label: 'Set placement to $mode',
                    child: GestureDetector(
                      onTap: () => onPlacementChanged(mode),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: placement == mode
                              ? tokens.surface3
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: placement == mode
                              ? Border.all(color: tokens.rimCyan, width: 1.2)
                              : null,
                        ),
                        child: Text(
                          mode,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HorizonTypography.labelCaps.copyWith(
                            color: placement == mode
                                ? tokens.ionCyan
                                : tokens.textMedium,
                            fontWeight: placement == mode
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Reset position row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Repositioned accidentally?',
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Return avatar to standard screen anchor',
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textMedium,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.textHigh,
                side: BorderSide(color: tokens.rimNeutral),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onResetPosition,
              icon: Icon(Icons.restart_alt, size: 15, color: tokens.textHigh),
              label: Text(
                'RESET ANCHOR',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textHigh,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
