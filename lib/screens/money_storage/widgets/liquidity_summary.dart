import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// Net liquidity summary for Money Storage.
///
/// One anchoring surface with a count-up balance, an honest inflow caption
/// and an open metric strip — replacing the boxed sub-metric ticker grid.
class LiquiditySummary extends StatelessWidget {
  const LiquiditySummary({
    super.key,
    required this.netLiquidity,
    required this.inflowMonthToDate,
    required this.reconciledCount,
    required this.inHand,
    required this.termVault,
    required this.exposure,
  });

  final String netLiquidity;
  final String inflowMonthToDate;
  final int reconciledCount;
  final double inHand;
  final double termVault;
  final double exposure;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final double netValue = double.tryParse(netLiquidity) ?? 0;

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      cornerAccentColor: tokens.ionCyan,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
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
                        color: tokens.ionCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NET CONSOLIDATED LIQUIDITY',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.textMedium,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$reconciledCount NODES RECONCILED',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.ionCyan,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: HorizonCountUpAmount(
              amount: netValue,
              style: HorizonTypography.displayHero.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '+₹$inflowMonthToDate INFLOW MTD',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.ionCyan,
                  fontSize: 9,
                ),
              ),
              Text(
                'Real-time ledger sync',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          HorizonMetricStrip(
            metrics: [
              HorizonMetric(
                label: 'In-Hand',
                value: inHand,
                accent: tokens.ionCyan,
                caption: 'ACTIVE CASH',
              ),
              HorizonMetric(
                label: 'Term Vault',
                value: termVault,
                accent: tokens.luminousGold,
                caption: 'RECORDED ASSETS',
              ),
              HorizonMetric(
                label: 'Exposure',
                value: exposure,
                accent: tokens.outflow,
                caption: 'CREDIT OWED',
                signed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
