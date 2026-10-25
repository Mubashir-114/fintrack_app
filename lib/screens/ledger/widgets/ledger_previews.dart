import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_collection.dart';
import '../../../models/transaction_model.dart';
import 'ledger_cash_flow_summary.dart';
import 'ledger_controls.dart';
import 'ledger_transaction_row.dart';

@Preview(name: 'Journal · Midnight', group: 'Ledger', size: Size(393, 852))
@Preview(name: 'Journal · Compact', group: 'Ledger', size: Size(320, 568))
@Preview(
  name: 'Journal · Large text',
  group: 'Ledger',
  size: Size(393, 852),
  textScaleFactor: 2,
)
Widget ledgerJournalPreview() => const _LedgerPreview();

@Preview(name: 'Journal · Jade', group: 'Ledger', size: Size(393, 852))
Widget ledgerJadePreview() =>
    const _LedgerPreview(collection: ThemeCollection.obsidianJade);

@Preview(name: 'Journal · Champagne', group: 'Ledger', size: Size(393, 852))
Widget ledgerChampagnePreview() =>
    const _LedgerPreview(collection: ThemeCollection.graphiteChampagne);

@Preview(name: 'Journal · Arctic light', group: 'Ledger', size: Size(393, 852))
Widget ledgerArcticPreview() => const _LedgerPreview(
  collection: ThemeCollection.arcticBlue,
  brightness: Brightness.light,
);

@Preview(name: 'Journal · Ivory light', group: 'Ledger', size: Size(393, 852))
Widget ledgerIvoryPreview() => const _LedgerPreview(
  collection: ThemeCollection.ivorySand,
  brightness: Brightness.light,
);

@Preview(name: 'Journal · Amethyst', group: 'Ledger', size: Size(600, 960))
Widget ledgerAmethystPreview() =>
    const _LedgerPreview(collection: ThemeCollection.amethystPulse);

class _LedgerPreview extends StatefulWidget {
  const _LedgerPreview({
    this.collection = ThemeCollection.midnightAurora,
    this.brightness = Brightness.dark,
  });
  final ThemeCollection collection;
  final Brightness brightness;
  @override
  State<_LedgerPreview> createState() => _LedgerPreviewState();
}

class _LedgerPreviewState extends State<_LedgerPreview> {
  final _search = TextEditingController();
  String? _type;
  // Preview-only fixtures; no provider, API, persistence, or native plugins.
  static const _records = [
    TransactionModel(
      id: 1,
      userId: 1,
      categoryId: 1,
      type: 'expense',
      title: 'Taxi',
      amount: 1200,
      transactionDate: '2026-10-24',
      category: 'Transport',
      accountName: 'Everyday Savings',
      source: 'sms',
    ),
    TransactionModel(
      id: 2,
      userId: 1,
      categoryId: 2,
      type: 'income',
      title: 'Salary',
      amount: 210000,
      transactionDate: '2026-10-24',
      category: 'Salary',
      source: 'manual',
    ),
    TransactionModel(
      id: 3,
      userId: 1,
      categoryId: 3,
      type: 'expense',
      title: 'A long merchant name with an international payment reference',
      amount: 2899.50,
      transactionDate: '2026-10-23',
      category: 'Shopping',
      accountName: 'Shared Household Current Account',
      source: 'manual',
    ),
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final items = _records
        .where(
          (tx) =>
              (_type == null || tx.type == _type) &&
              tx.title.toLowerCase().contains(_search.text.toLowerCase()),
        )
        .toList();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(widget.collection, widget.brightness),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LedgerHeader(
                  period: 'October 2026',
                  count: items.length,
                  onManage: () {},
                  onImport: () {},
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),
                LedgerSearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(_search.clear),
                ),
                LedgerFilterRail(
                  selectedType: _type,
                  dateLabel: null,
                  onTypeChanged: (value) => setState(() => _type = value),
                  onDate: () {},
                  hasFilters: _type != null || _search.text.isNotEmpty,
                  onReset: () => setState(() {
                    _type = null;
                    _search.clear();
                  }),
                ),
                if (items.isNotEmpty)
                  LedgerCashFlowSummary(transactions: items),
                for (final tx in items)
                  LedgerTransactionRow(transaction: tx, onPressed: () {}),
                const SizedBox(height: HorizonDimensions.spaceLG),
                LedgerAddTransactionAction(onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
