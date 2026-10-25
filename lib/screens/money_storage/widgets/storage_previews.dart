import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_collection.dart';
import '../../../core/horizon/theme/horizon_theme_tokens.dart';
import '../../../models/account_model.dart';
import 'liquidity_summary.dart';
import 'storage_action_row.dart';
import 'storage_node_row.dart';

Widget _previewSurface(
  Widget child, {
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Liquidity summary — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 420),
  brightness: Brightness.dark,
)
Widget liquiditySummaryPreview() => _previewSurface(
  const LiquiditySummary(
    netLiquidity: '382450.75',
    inflowMonthToDate: '84500.00',
    reconciledCount: 4,
    inHand: 148900.25,
    termVault: 208550.50,
    exposure: 25000.00,
  ),
);

@Preview(
  name: 'Storage action row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 110),
  brightness: Brightness.dark,
)
Widget storageActionRowPreview() {
  return _previewSurface(
    Builder(
      builder: (context) {
        final tokens = HorizonThemeTokens.of(context);
        return StorageActionRow(
          actions: [
            StorageAction(
              icon: Icons.sync_rounded,
              label: 'Reconcile',
              caption: '4 NODES',
              accent: tokens.ionCyan,
              onTap: () {},
            ),
            StorageAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              caption: 'ZERO FEE',
              accent: tokens.electricIndigo,
              onTap: () {},
            ),
            StorageAction(
              icon: Icons.add_link_rounded,
              label: 'Link node',
              caption: '+ BANK / UPI',
              accent: tokens.luminousGold,
              onTap: () {},
            ),
          ],
        );
      },
    ),
  );
}

@Preview(
  name: 'Storage node row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 160),
  brightness: Brightness.dark,
)
Widget storageNodeRowPreview() {
  return _previewSurface(
    Builder(
      builder: (context) {
        final tokens = HorizonThemeTokens.of(context);
        return StorageNodeRow(
          account: const AccountModel(
            id: 1,
            type: 'bank',
            subtype: 'savings',
            displayName: 'HDFC Priority Checking',
            institutionName: 'HDFC Bank',
            maskedLast4: '4821',
            currencyCode: 'INR',
            openingAmount: '124580.00',
            isDefault: true,
            status: 'active',
          ),
          balance: '124580.00',
          balanceLabel: 'RECORDED BALANCE',
          accent: tokens.ionCyan,
          icon: Icons.account_balance_rounded,
          statusLabel: 'ACTIVE RECORD',
          subStatusLabel: 'Default account',
          badgeLabel: 'BANK ACCOUNT',
          onViewDetails: () {},
        );
      },
    ),
  );
}

@Preview(
  name: 'Storage node row — Light',
  group: 'FinTrack // HORIZON',
  size: Size(393, 160),
  brightness: Brightness.light,
)
Widget storageNodeRowLightPreview() {
  return _previewSurface(
    Builder(
      builder: (context) {
        final tokens = HorizonThemeTokens.of(context);
        return StorageNodeRow(
          account: const AccountModel(
            id: 2,
            type: 'credit_card',
            subtype: 'credit',
            displayName: 'Platinum Rewards Card',
            institutionName: 'ICICI Bank',
            maskedLast4: '9932',
            currencyCode: 'INR',
            openingAmount: '25000.00',
            isDefault: false,
            status: 'active',
          ),
          balance: '25000.00',
          balanceLabel: 'CURRENT OUTSTANDING',
          accent: tokens.outflow,
          icon: Icons.credit_card_rounded,
          statusLabel: 'ACTIVE RECORD',
          subStatusLabel: 'Saved transactions only',
          badgeLabel: 'CREDIT CARD',
          onViewDetails: () {},
        );
      },
    ),
    brightness: Brightness.light,
  );
}
