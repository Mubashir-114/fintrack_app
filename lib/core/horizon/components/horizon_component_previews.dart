import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_collection.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';
import 'horizon_count_up_text.dart';
import 'horizon_icon_button.dart';
import 'horizon_metric_strip.dart';
import 'horizon_range_switcher.dart';
import 'horizon_section_header.dart';
import 'horizon_trend_line.dart';
import 'horizon_transaction_row.dart';

Widget _previewSurface(
  Widget child, {
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
    home: Scaffold(
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

@Preview(
  name: 'Range switcher — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 110),
  brightness: Brightness.dark,
)
Widget horizonRangeSwitcherPreview() =>
    _previewSurface(const _RangeSwitcherPreview());

class _RangeSwitcherPreview extends StatefulWidget {
  const _RangeSwitcherPreview();

  @override
  State<_RangeSwitcherPreview> createState() => _RangeSwitcherPreviewState();
}

class _RangeSwitcherPreviewState extends State<_RangeSwitcherPreview> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => HorizonRangeSwitcher(
    options: const ['Current Month', 'Previous Month'],
    selectedIndex: selected,
    onSelected: (value) => setState(() => selected = value),
  );
}

@Preview(
  name: 'Range switcher (custom month) — Light',
  group: 'FinTrack // HORIZON',
  size: Size(360, 110),
  brightness: Brightness.light,
)
Widget horizonRangeSwitcherCustomPreview() => _previewSurface(
  HorizonRangeSwitcher(
    options: const ['Current Month', 'Previous Month'],
    selectedIndex: -1,
    onSelected: (_) {},
    customLabel: '2026-09',
    onCustomSelected: () {},
  ),
  brightness: Brightness.light,
);

@Preview(
  name: 'Metric strip — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 170),
  brightness: Brightness.dark,
)
Widget horizonMetricStripPreview() {
  return _previewSurface(
    Builder(
      builder: (context) {
        final tokens = HorizonThemeTokens.of(context);
        return HorizonMetricStrip(
          metrics: [
            HorizonMetric(
              label: 'Income',
              value: 84500,
              accent: tokens.surplus,
              caption: 'INFLOW MTD',
            ),
            HorizonMetric(
              label: 'Expenses',
              value: 32400,
              accent: tokens.outflow,
              caption: 'OUTFLOW MTD',
            ),
            HorizonMetric(
              label: 'Savings',
              value: 52100,
              accent: tokens.ionCyan,
              caption: 'SURPLUS',
            ),
          ],
        );
      },
    ),
  );
}

@Preview(
  name: 'Section header — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 90),
  brightness: Brightness.dark,
)
Widget horizonSectionHeaderPreview() => _previewSurface(
  const HorizonSectionHeader(
    title: 'Recent Transactions',
    icon: Icons.receipt_long_rounded,
    actionLabel: 'View all',
  ),
);

@Preview(
  name: 'Count-up amount — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 100),
  brightness: Brightness.dark,
)
Widget horizonCountUpPreview() => _previewSurface(
  Center(
    child: HorizonCountUpAmount(
      amount: 1258400.5,
      style: HorizonTypography.tabularAmountLg.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
);

@Preview(
  name: 'Trend line draw — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 130),
  brightness: Brightness.dark,
)
Widget horizonTrendLinePreview() {
  return _previewSurface(
    Builder(
      builder: (context) {
        final tokens = HorizonThemeTokens.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CASH-FLOW TREND',
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.textMedium,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            HorizonTrendLine(
              values: const [4, 9, 6, 12, 8, 15, 11, 18],
              color: tokens.ionCyan,
              dotSurfaceColor: tokens.surface2,
              height: 72,
            ),
          ],
        );
      },
    ),
  );
}

@Preview(
  name: 'Icon button with badge — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 100),
  brightness: Brightness.dark,
)
Widget horizonIconButtonPreview() => _previewSurface(
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      HorizonIconButton(
        icon: Icons.notifications_none_rounded,
        semanticLabel: 'Open updates',
        badgeCount: 3,
        onPressed: () {},
      ),
      const SizedBox(width: 12),
      HorizonIconButton(
        icon: Icons.add_rounded,
        semanticLabel: 'Add',
        filledAccent: true,
        onPressed: () {},
      ),
      const SizedBox(width: 12),
      HorizonIconButton(
        icon: Icons.close_rounded,
        semanticLabel: 'Close',
        onPressed: () {},
      ),
    ],
  ),
);

@Preview(
  name: 'Transaction row with note — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 160),
  brightness: Brightness.dark,
)
Widget horizonTransactionRowPreview() {
  return _previewSurface(
    const Center(
      child: SizedBox(
        width: 360,
        child: HorizonTransactionRow(
          title: 'BigBasket Run',
          amount: 1500,
          isExpense: true,
          category: 'Groceries',
          accountName: 'Everyday Savings',
          dateString: 'Today',
          note: 'Weekly household restock',
          categoryIcon: Icons.shopping_basket_rounded,
        ),
      ),
    ),
  );
}
