import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';

/// Reusable guidance frequency and style selector card for FIN.
class FinGuidanceStyleCard extends StatelessWidget {
  final String frequency; // 'standard' | 'minimal'
  final ValueChanged<String> onFrequencyChanged;

  const FinGuidanceStyleCard({
    super.key,
    required this.frequency,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        final option1 = _buildCard(
          context: context,
          tokens: tokens,
          title: 'Helpful Insights',
          subtitle:
              'Active suggestions on recurring spends and envelope pacing.',
          isSelected: frequency == 'standard',
          onTap: () => onFrequencyChanged('standard'),
        );

        final option2 = _buildCard(
          context: context,
          tokens: tokens,
          title: 'Minimal Alerts',
          subtitle:
              'Quiet presence. Alerts only during critical threshold overruns.',
          isSelected: frequency == 'minimal',
          onTap: () => onFrequencyChanged('minimal'),
        );

        if (isNarrow) {
          return Column(
            children: [option1, const SizedBox(height: 8), option2],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: option1),
            const SizedBox(width: 8),
            Expanded(child: option2),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required HorizonThemeTokens tokens,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title guidance frequency option',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? tokens.ionCyan : tokens.rimNeutral,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? tokens.ionCyan
                            : tokens.textMedium.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.ionCyan,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
