import 'package:flutter/material.dart';

import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';
import 'horizon_count_up_text.dart';

/// One figure inside a [HorizonMetricStrip].
class HorizonMetric {
  const HorizonMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.caption,
    this.signed = false,
  });

  final String label;
  final double value;
  final Color accent;
  final String? caption;

  /// Renders the absolute value; the sign is conveyed by [accent] and label.
  final bool signed;
}

/// Open financial summary strip: key figures separated by hairlines instead
/// of individual boxes, each counting up when its value changes.
class HorizonMetricStrip extends StatelessWidget {
  const HorizonMetricStrip({super.key, required this.metrics});

  final List<HorizonMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final vertical = MediaQuery.textScalerOf(context).scale(15) > 20;

    Widget metric(HorizonMetric item) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: item.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.label,
                    style: HorizonTypography.labelCaps.copyWith(
                      fontSize: 10,
                      color: item.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: HorizonCountUpAmount(
                amount: item.signed ? item.value.abs() : item.value,
                style: HorizonTypography.tabularAmountMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.textHigh,
                ),
              ),
            ),
            if (item.caption != null) ...[
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.caption!,
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.textLow,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      return vertical ? content : Expanded(child: content);
    }

    final separators = <Widget>[];
    for (int i = 1; i < metrics.length; i++) {
      separators.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(width: 1, height: 34, color: tokens.rimNeutral),
        ),
      );
    }

    final children = <Widget>[];
    for (int i = 0; i < metrics.length; i++) {
      if (i > 0) children.add(separators[i - 1]);
      children.add(metric(metrics[i]));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
        const SizedBox(height: 12),
        if (vertical)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [for (final item in metrics) metric(item)],
          )
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
      ],
    );
  }
}
