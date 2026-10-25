import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_collection.dart';
import '../../../models/category_model.dart';
import 'fin_purse_moment.dart';
import 'transaction_amount_hero.dart';
import 'transaction_category_selector.dart';
import 'transaction_field_rows.dart';
import 'transaction_type_switch.dart';

Widget _previewSurface(
  Widget child, {
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HorizonDimensions.spaceLG),
          child: child,
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Transaction type switch — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 120),
  brightness: Brightness.dark,
)
Widget transactionTypeSwitchDarkPreview() =>
    _previewSurface(TransactionTypeSwitch(isIncome: false, onChanged: (_) {}));

@Preview(
  name: 'Transaction type switch — Income light',
  group: 'FinTrack // HORIZON',
  size: Size(360, 120),
  brightness: Brightness.light,
)
Widget transactionTypeSwitchIncomePreview() => _previewSurface(
  TransactionTypeSwitch(isIncome: true, onChanged: (_) {}),
  brightness: Brightness.light,
);

@Preview(
  name: 'Amount hero — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 160),
  brightness: Brightness.dark,
)
Widget transactionAmountHeroPreview() => _previewSurface(
  TransactionAmountHero(
    controller: TextEditingController(),
    isIncome: false,
    currencySymbol: '₹',
    validator: (_) => null,
  ),
);

@Preview(
  name: 'Category selector — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 160),
  brightness: Brightness.dark,
)
Widget transactionCategorySelectorPreview() => _previewSurface(
  TransactionCategorySelector(
    categories: CategoryModel.getExpenseCategories(),
    selectedId: 3,
    isIncome: false,
    onSelected: (_) {},
  ),
);

@Preview(
  name: 'Account and date rows — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 200),
  brightness: Brightness.dark,
)
Widget transactionMetaRowsPreview() => _previewSurface(
  Column(
    children: [
      TransactionMetaRow(
        rowKey: const ValueKey('preview-account'),
        icon: Icons.account_balance_wallet_outlined,
        label: 'Account',
        value: 'Everyday Savings · default',
        onTap: () {},
      ),
      TransactionMetaRow(
        rowKey: const ValueKey('preview-date'),
        icon: Icons.calendar_today_outlined,
        label: 'Date',
        value: '25 Oct 2026',
        onTap: () {},
      ),
    ],
  ),
);

@Preview(
  name: 'Quiet field — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(360, 140),
  brightness: Brightness.dark,
)
Widget transactionQuietFieldPreview() => _previewSurface(
  TransactionQuietField(
    label: 'Title / Merchant',
    hintText: 'e.g. Corner cafe',
    controller: TextEditingController(),
  ),
);

@Preview(
  name: 'FIN purse moment — Income',
  group: 'FinTrack // HORIZON',
  size: Size(160, 140),
  brightness: Brightness.dark,
)
Widget finPurseIncomePreview() =>
    _previewSurface(const FinPurseMoment(isIncome: true));

@Preview(
  name: 'FIN purse moment — Expense',
  group: 'FinTrack // HORIZON',
  size: Size(160, 140),
  brightness: Brightness.light,
)
Widget finPurseExpensePreview() => _previewSurface(
  const FinPurseMoment(isIncome: false),
  brightness: Brightness.light,
);
