import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/cache_service.dart';
import '../../models/category_model.dart';
import '../../models/detected_transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/sms_provider.dart';
import '../../providers/transaction_provider.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});
  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _scanPromptOpen = false;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountProvider>().loadAccounts();
      context.read<SmsProvider>().loadDetectedTransactions();
      _requestScan();
    });
  }

  Future<void> _requestScan() async {
    if (_scanPromptOpen) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SMS import is available on Android. You can add transactions manually.',
          ),
        ),
      );
      return;
    }
    final userId = CacheService.userId;
    _scanPromptOpen = true;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Optional SMS import'),
        scrollable: true,
        content: const Text(
          'FinTrack reads SMS on this device to find financial messages. Only parsed financial candidates (amount, type, merchant, bank, masked account last four digits, date, reference, sender and duplicate hash) are sent to your FinTrack account for review. Full message text and unrelated messages stay on your device. Nothing changes your ledger until you confirm. FIN cannot read SMS. You can decline, use manual entry, or revoke SMS permission in Android Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue to scan'),
          ),
        ],
      ),
    );
    _scanPromptOpen = false;
    if (approved == true && mounted && userId == CacheService.userId) {
      await context.read<SmsProvider>().scanAndDetectSmartTransactions(
        userConsented: true,
      );
    }
  }

  Future<void> _refreshLedger() async {
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<DashboardProvider>().loadDashboardData(),
      context.read<AccountProvider>().refresh(),
      context.read<ReportProvider>().loadAllReports(),
      context.read<BudgetProvider>().loadAllBudgetData(forceRefresh: true),
    ]);
  }

  Future<void> _confirm(DetectedTransactionModel tx) async {
    final sms = context.read<SmsProvider>();
    final userId = CacheService.userId;
    if (_saving || sms.isOperating) return;
    setState(() => _saving = true);
    final ok = await sms.confirmDetected(tx.id);
    if (!mounted) return;
    if (userId != CacheService.userId) {
      setState(() => _saving = false);
      return;
    }
    if (ok) await _refreshLedger();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Transaction saved to your history.'
              : sms.detectedErrorMessage ?? 'Could not confirm. Please retry.',
        ),
      ),
    );
  }

  Future<void> _addBatch({required bool all}) async {
    final sms = context.read<SmsProvider>();
    if (_saving || sms.isOperating) return;
    final userId = CacheService.userId;
    setState(() => _saving = true);
    await sms.batchConfirmSelected(all: all);
    if (!mounted) return;
    if (userId != CacheService.userId) {
      setState(() => _saving = false);
      return;
    }
    final result = sms.batchResult;
    if ((result?.added ?? 0) > 0) await _refreshLedger();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result?.message ??
              sms.detectedErrorMessage ??
              'No transactions selected.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sms = context.watch<SmsProvider>();
    final busy =
        _saving || sms.isScanning || sms.isLoadingDetected || sms.isOperating;
    final error = sms.errorMessage ?? sms.detectedErrorMessage;
    final denied =
        sms.permissionStatus?.isPermanentlyDenied == true ||
        sms.permissionStatus?.isRestricted == true;
    final symbol = context.watch<CurrencyProvider>().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Import'),
        actions: [
          IconButton(
            tooltip: 'Rescan SMS',
            onPressed: busy ? null : _requestScan,
            icon: const Icon(Icons.sms_outlined),
          ),
          IconButton(
            tooltip: 'Reload pending review',
            onPressed: busy ? null : () => sms.loadDetectedTransactions(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Review before saving',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              FilledButton.icon(
                onPressed: busy || sms.eligibleDetectedCount == 0
                    ? null
                    : () => _addBatch(all: true),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text('Add All (${sms.eligibleDetectedCount})'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pending candidates do not affect balances. Confirm detected details, or use Edit to correct them.',
          ),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(),
          if (sms.batchResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(sms.batchResult!.message),
            ),
          if (sms.detectedTransactions.isNotEmpty)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: sms.isAllDetectedSelected,
                      onChanged: busy
                          ? null
                          : (v) => sms.toggleSelectAllDetected(v ?? false),
                    ),
                    const Text('Select all'),
                  ],
                ),
                OutlinedButton(
                  onPressed: busy || sms.selectedDetectedCount == 0
                      ? null
                      : () => _addBatch(all: false),
                  child: Text('Add Selected (${sms.selectedDetectedCount})'),
                ),
              ],
            ),
          if (error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(error),
                    if (sms.permissionStatus?.isDenied == true || denied)
                      const Text(
                        'Android Settings > Apps > FinTrack > Permissions > SMS. Return here and scan again. Some devices or managed profiles restrict SMS access.',
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (denied)
                          TextButton(
                            onPressed: openAppSettings,
                            child: const Text('Open Android Settings'),
                          ),
                        if (sms.errorMessage != null || denied)
                          TextButton(
                            onPressed: busy ? null : _requestScan,
                            child: const Text('Retry scan'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (!busy && sms.detectedTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('No financial candidates awaiting review.'),
                  const Text(
                    'Scan eligible bank messages, or add a transaction manually.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _requestScan,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Scan financial SMS'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('Manual transaction entry'),
                  ),
                ],
              ),
            ),
          for (final tx in sms.detectedTransactions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: sms.selectedDetectedIds.contains(tx.id),
                          onChanged: busy
                              ? null
                              : (_) => sms.toggleDetectedSelection(tx.id),
                        ),
                        Expanded(
                          child: Text(
                            tx.merchantClean,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$symbol${tx.amount} / ${tx.classification} / ${tx.transactionDate}',
                    ),
                    Text(
                      'Category: ${tx.categoryName ?? tx.suggestedCategoryName ?? 'Choose category'}',
                    ),
                    Text(
                      'Account: ${tx.accountName ?? tx.suggestedAccountName ?? 'Choose account'}',
                    ),
                    if (tx.bank != null) Text(tx.bank!),
                    if (sms.confirmationErrors[tx.id] ??
                            sms.confirmationIssue(tx)
                        case final String issue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          issue,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => _edit(tx),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  await sms.rejectDetected(tx.id);
                                  if (context.mounted &&
                                      sms.detectedErrorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          sms.detectedErrorMessage!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: const Text('Reject'),
                        ),
                        FilledButton(
                          onPressed: busy ? null : () => _confirm(tx),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(DetectedTransactionModel tx) async {
    final merchant = TextEditingController(text: tx.merchantClean);
    final amount = TextEditingController(text: tx.amount);
    final date = TextEditingController(text: tx.transactionDate);
    final form = GlobalKey<FormState>();
    final accounts = context
        .read<AccountProvider>()
        .accounts
        .where((a) => a.status == 'active')
        .toList();
    int? account = tx.accountId ?? tx.suggestedAccountId;
    if (!accounts.any((a) => a.id == account)) account = null;
    int? category = tx.categoryId ?? tx.suggestedCategoryId;
    final categories = CategoryModel.categories;
    if (!categories.any((c) => c.id == category)) category = null;
    const classifications = [
      'expense',
      'income',
      'refund',
      'credit_card_purchase',
      'credit_card_repayment',
      'transfer',
    ];
    String? classification = classifications.contains(tx.classification)
        ? tx.classification
        : null;
    final sms = context.read<SmsProvider>();
    final userId = CacheService.userId;
    bool saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const Text('Correct transaction'),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: merchant,
                      decoration: const InputDecoration(labelText: 'Merchant'),
                      maxLength: 150,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a merchant'
                          : null,
                    ),
                    TextFormField(
                      controller: amount,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null ||
                                !n.isFinite ||
                                n <= 0 ||
                                n > 9999999999.99
                            ? 'Enter a positive amount'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: date,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                      ),
                      validator: (v) {
                        final parsed = DateTime.tryParse(v ?? '');
                        return parsed == null ||
                                parsed.toIso8601String().substring(0, 10) != v
                            ? 'Enter a valid date'
                            : null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: classification,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        for (final type in [
                          'expense',
                          'income',
                          'refund',
                          'credit_card_purchase',
                          'credit_card_repayment',
                          'transfer',
                        ])
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.replaceAll('_', ' ')),
                          ),
                      ],
                      onChanged: saving ? null : (v) => classification = v,
                      validator: (v) =>
                          v == null ? 'Choose a transaction type' : null,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: account,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: [
                        for (final a in accounts)
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: saving ? null : (v) => account = v,
                      validator: (v) => v == null
                          ? 'Choose an account (create one in Accounts first)'
                          : null,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: saving ? null : (v) => category = v,
                      validator: (v) => v == null ? 'Choose a category' : null,
                    ),
                    if (error != null) Text(error!),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate() ||
                            userId != CacheService.userId) {
                          return;
                        }
                        update(() => saving = true);
                        final ok = await sms.updateDetected(tx.id, {
                          'merchantClean': merchant.text.trim(),
                          'amount': amount.text,
                          'transactionDate': date.text,
                          'classification': classification,
                          'accountId': account,
                          'categoryId': category,
                        });
                        if (!dialog.mounted) return;
                        if (ok) {
                          Navigator.pop(dialog);
                        } else {
                          update(() {
                            saving = false;
                            error = sms.detectedErrorMessage;
                          });
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save corrections'),
              ),
            ],
          ),
        ),
      ),
    );
    merchant.dispose();
    amount.dispose();
    date.dispose();
  }
}
