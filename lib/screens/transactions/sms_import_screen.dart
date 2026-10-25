import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/horizon/horizon.dart';
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
  String _selectedFilter = 'all'; // all, ready, duplicate, review

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
    final tokens = HorizonThemeTokens.of(context);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SMS import is available on Android. You can add transactions manually.',
            style: HorizonTypography.bodySm,
          ),
          backgroundColor: tokens.surface3,
        ),
      );
      return;
    }
    final userId = CacheService.userId;
    _scanPromptOpen = true;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'Optional SMS import',
          style: HorizonTypography.headlineSm.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        scrollable: true,
        content: Text(
          'FinTrack reads SMS on this device to find financial messages. Only parsed financial candidates (amount, type, merchant, bank, masked account last four digits, date, reference, sender and duplicate hash) are sent to your FinTrack account for review. Full message text and unrelated messages stay on your device. Nothing changes your ledger until you confirm. FIN cannot read SMS. You can decline, use manual entry, or revoke SMS permission in Android Settings.',
          style: HorizonTypography.bodySm.copyWith(
            color: tokens.textMedium,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not now', style: TextStyle(color: tokens.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Continue to scan',
              style: TextStyle(
                color: tokens.ionCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  Future<bool> _promptChooseDefaultAccount() async {
    final tokens = HorizonThemeTokens.of(context);
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts
        .where((a) => a.status == 'active' && a.isAsset)
        .toList();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No active asset accounts found. Please create an account in Money Storage first.',
            style: HorizonTypography.bodySm,
          ),
          backgroundColor: tokens.surface3,
        ),
      );
      return false;
    }

    int? selectedId = accounts.first.id;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: tokens.surface2,
          title: Text(
            'Designate Default Account',
            style: HorizonTypography.headlineSm.copyWith(
              color: tokens.textHigh,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When an imported transaction does not specify an account, it will automatically save to your designated default account. Choose one now:',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                dropdownColor: tokens.surface2,
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textHigh,
                ),
                decoration: InputDecoration(
                  labelText: 'Default Account',
                  labelStyle: TextStyle(color: tokens.textMedium),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.rimNeutral),
                  ),
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem<int>(
                    value: acc.id,
                    child: Text(
                      acc.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Cancel', style: TextStyle(color: tokens.textMedium)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                'Set Default & Continue',
                style: TextStyle(
                  color: tokens.ionCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedId != null) {
      final success = await accountProvider.setDefault(selectedId!);
      return success;
    }
    return false;
  }

  Future<void> _confirm(DetectedTransactionModel tx) async {
    final sms = context.read<SmsProvider>();
    final accountProvider = context.read<AccountProvider>();
    final defaultAcc = accountProvider.defaultAccount;

    final hasResolvedAccount =
        tx.accountId != null ||
        (tx.suggestedAccountId != null && !tx.isAccountAmbiguous) ||
        defaultAcc != null;

    if (!hasResolvedAccount) {
      final designated = await _promptChooseDefaultAccount();
      if (!designated || !mounted) return;
    }

    final userId = CacheService.userId;
    if (_saving || sms.isOperating) return;
    setState(() => _saving = true);
    final fallbackId = context.read<AccountProvider>().defaultAccount?.id;
    final ok = await sms.confirmDetected(
      tx.id,
      fallbackDefaultAccountId: fallbackId,
    );
    if (!mounted) return;
    if (userId != CacheService.userId) {
      setState(() => _saving = false);
      return;
    }
    if (ok) await _refreshLedger();
    if (!mounted) return;
    setState(() => _saving = false);
    final tokens = HorizonThemeTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Transaction saved to your history.'
              : sms.detectedErrorMessage ?? 'Could not confirm. Please retry.',
          style: HorizonTypography.bodySm,
        ),
        backgroundColor: tokens.surface3,
      ),
    );
  }

  Future<void> _addBatch({required bool all}) async {
    final sms = context.read<SmsProvider>();
    final accountProvider = context.read<AccountProvider>();
    final defaultAcc = accountProvider.defaultAccount;

    final candidates = sms.detectedTransactions
        .where((tx) => all || sms.selectedDetectedIds.contains(tx.id))
        .toList();
    final needsDefault = candidates.any(
      (tx) =>
          tx.accountId == null &&
          (tx.suggestedAccountId == null || tx.isAccountAmbiguous),
    );

    if (needsDefault && defaultAcc == null) {
      final designated = await _promptChooseDefaultAccount();
      if (!designated || !mounted) return;
    }

    if (_saving || sms.isOperating) return;
    final userId = CacheService.userId;
    setState(() => _saving = true);
    final fallbackId = context.read<AccountProvider>().defaultAccount?.id;
    await sms.batchConfirmSelected(
      all: all,
      fallbackDefaultAccountId: fallbackId,
    );
    if (!mounted) return;
    if (userId != CacheService.userId) {
      setState(() => _saving = false);
      return;
    }
    final result = sms.batchResult;
    if ((result?.added ?? 0) > 0) await _refreshLedger();
    if (!mounted) return;
    setState(() => _saving = false);
    final tokens = HorizonThemeTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result?.message ??
              sms.detectedErrorMessage ??
              'No transactions selected.',
          style: HorizonTypography.bodySm,
        ),
        backgroundColor: tokens.surface3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sms = context.watch<SmsProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final busy =
        _saving || sms.isScanning || sms.isLoadingDetected || sms.isOperating;
    final error = sms.errorMessage ?? sms.detectedErrorMessage;
    final denied =
        sms.permissionStatus?.isPermanentlyDenied == true ||
        sms.permissionStatus?.isRestricted == true;
    final symbol = context.watch<CurrencyProvider>().currencySymbol;

    final defaultAccId = context.watch<AccountProvider>().defaultAccount?.id;

    // Filter calculations
    final List<DetectedTransactionModel> filteredList;
    if (_selectedFilter == 'ready') {
      filteredList = sms.detectedTransactions
          .where(
            (t) =>
                sms.confirmationIssue(
                  t,
                  fallbackDefaultAccountId: defaultAccId,
                ) ==
                null,
          )
          .toList();
    } else if (_selectedFilter == 'review') {
      filteredList = sms.detectedTransactions
          .where(
            (t) =>
                sms.confirmationIssue(
                  t,
                  fallbackDefaultAccountId: defaultAccId,
                ) !=
                null,
          )
          .toList();
    } else {
      filteredList = sms.detectedTransactions;
    }

    // Telemetry inflow/outflow metrics
    double detectedInflow = 0.0;
    double detectedOutflow = 0.0;
    int inflowCount = 0;
    int outflowCount = 0;
    for (final tx in sms.detectedTransactions) {
      final amt = double.tryParse(tx.amount) ?? 0.0;
      if (tx.classification == 'income' || tx.classification == 'refund') {
        detectedInflow += amt;
        inflowCount++;
      } else {
        detectedOutflow += amt;
        outflowCount++;
      }
    }

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textHigh),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.ionCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'SMART SMS // IMPORT',
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.ionCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Detected Batch Review',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rescan SMS',
            onPressed: busy ? null : _requestScan,
            icon: Icon(Icons.sms_outlined, color: tokens.ionCyan),
          ),
          IconButton(
            tooltip: 'Reload pending review',
            onPressed: busy ? null : () => sms.loadDetectedTransactions(),
            icon: Icon(Icons.refresh, color: tokens.textMedium),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HorizonDimensions.marginMobile,
          HorizonDimensions.spaceSM,
          HorizonDimensions.marginMobile,
          HorizonDimensions.dockClearance,
        ),
        children: [
          // ── Top Auxiliary Action Strip ─────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tokens.ionCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SMS Import Review',
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.textMedium,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (sms.detectedTransactions.isNotEmpty)
                InkWell(
                  onTap: busy
                      ? null
                      : () => sms.toggleSelectAllDetected(
                          !sms.isAllDetectedSelected,
                        ),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surface3,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.rimNeutral),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sms.isAllDetectedSelected
                              ? Icons.done_all
                              : Icons.select_all,
                          size: 14,
                          color: tokens.ionCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sms.isAllDetectedSelected
                              ? 'Deselect All'
                              : 'Select All (${sms.detectedTransactions.length})',
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Telemetry Scan Summary Hero Module ─────────────────────
          if (sms.detectedTransactions.isNotEmpty) ...[
            HorizonSurface(
              tier: HorizonSurfaceTier.surface2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.cell_tower,
                            color: tokens.ionCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${sms.detectedTransactions.length} Transactions Found',
                            style: HorizonTypography.headlineSm.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.rimNeutral),
                        ),
                        child: Text(
                          'REVIEW',
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tokens.surface3,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DETECTED INFLOW',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+$symbol${detectedInflow.toStringAsFixed(2)}',
                                style: HorizonTypography.tabularAmountMd
                                    .copyWith(
                                      color: tokens.surplus,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '$inflowCount Detected Credits',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tokens.surface3,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DETECTED OUTFLOW',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '-$symbol${detectedOutflow.toStringAsFixed(2)}',
                                style: HorizonTypography.tabularAmountMd
                                    .copyWith(
                                      color: tokens.outflow,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '$outflowCount Detected Debits',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Batch Confirm Action Row
                  Row(
                    children: [
                      Expanded(
                        child: HorizonButton(
                          text:
                              'Add Eligible (${sms.eligibleCount(fallbackDefaultAccountId: defaultAccId)})',
                          icon: Icons.done_all,
                          variant: HorizonButtonVariant.primary,
                          isLoading: busy,
                          onPressed:
                              busy ||
                                  sms.eligibleCount(
                                        fallbackDefaultAccountId: defaultAccId,
                                      ) ==
                                      0
                              ? null
                              : () => _addBatch(all: true),
                        ),
                      ),
                      if (sms.selectedDetectedCount > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: HorizonButton(
                            text: 'Add Selected (${sms.selectedDetectedCount})',
                            variant: HorizonButtonVariant.secondary,
                            isLoading: busy,
                            onPressed: busy
                                ? null
                                : () => _addBatch(all: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter Chips ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  HorizonChip(
                    label: 'All (${sms.detectedTransactions.length})',
                    selected: _selectedFilter == 'all',
                    onSelected: (_) => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  HorizonChip(
                    label: 'Ready to Import',
                    selected: _selectedFilter == 'ready',
                    onSelected: (_) =>
                        setState(() => _selectedFilter = 'ready'),
                  ),
                  const SizedBox(width: 8),
                  HorizonChip(
                    label: 'Needs Review',
                    selected: _selectedFilter == 'review',
                    onSelected: (_) =>
                        setState(() => _selectedFilter = 'review'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (busy) ...[
            LinearProgressIndicator(
              color: tokens.ionCyan,
              backgroundColor: tokens.surface3,
            ),
            const SizedBox(height: 12),
          ],

          // Error card
          if (error != null) ...[
            HorizonSurface(
              tier: HorizonSurfaceTier.surface2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error,
                    style: HorizonTypography.bodyMd.copyWith(
                      color: tokens.outflow,
                    ),
                  ),
                  if (sms.permissionStatus?.isDenied == true || denied) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Android Settings > Apps > FinTrack > Permissions > SMS. Return here and scan again.',
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (denied)
                        HorizonButton(
                          text: 'Open Android Settings',
                          variant: HorizonButtonVariant.secondary,
                          expandWidth: false,
                          height: 36,
                          onPressed: openAppSettings,
                        ),
                      if (sms.errorMessage != null || denied)
                        HorizonButton(
                          text: 'Retry Scan',
                          variant: HorizonButtonVariant.ghost,
                          expandWidth: false,
                          height: 36,
                          onPressed: busy ? null : _requestScan,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Empty state
          if (!busy && sms.detectedTransactions.isEmpty) ...[
            HorizonEmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'No candidates awaiting review',
              description:
                  'Scan eligible bank messages, or enter transactions manually.',
              actionLabel: 'Scan Financial SMS',
              onAction: _requestScan,
            ),
          ],

          // Detected Transaction Cards
          for (final tx in filteredList) ...[
            HorizonSurface(
              tier: HorizonSurfaceTier.surface2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: sms.selectedDetectedIds.contains(tx.id),
                        activeColor: tokens.ionCyan,
                        onChanged: busy
                            ? null
                            : (_) => sms.toggleDetectedSelection(tx.id),
                      ),
                      Expanded(
                        child: Text(
                          tx.merchantClean,
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        tx.classification == 'income' ||
                                tx.classification == 'refund'
                            ? '+$symbol${tx.amount}'
                            : '-$symbol${tx.amount}',
                        style: HorizonTypography.tabularAmountMd.copyWith(
                          color:
                              tx.classification == 'income' ||
                                  tx.classification == 'refund'
                              ? tokens.surplus
                              : tokens.outflow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.rimNeutral),
                        ),
                        child: Text(
                          tx.classification.replaceAll('_', ' ').toUpperCase(),
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.rimNeutral),
                        ),
                        child: Text(
                          tx.transactionDate,
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.textMedium,
                          ),
                        ),
                      ),
                      if (tx.bank != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface3,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Text(
                            tx.bank!,
                            style: HorizonTypography.labelCaps.copyWith(
                              color: tokens.textMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Resolved Account Routing (Requirement 6 & 7)
                  Builder(
                    builder: (context) {
                      final defaultAcc = context
                          .watch<AccountProvider>()
                          .defaultAccount;
                      final String resolvedAccountDisplay;
                      final bool hasAccount;

                      if (tx.accountId != null) {
                        resolvedAccountDisplay =
                            tx.accountName ?? 'Account #${tx.accountId}';
                        hasAccount = true;
                      } else if (tx.suggestedAccountId != null &&
                          !tx.isAccountAmbiguous) {
                        resolvedAccountDisplay =
                            tx.suggestedAccountName ??
                            'Account #${tx.suggestedAccountId}';
                        hasAccount = true;
                      } else if (defaultAcc != null) {
                        resolvedAccountDisplay =
                            '${defaultAcc.displayName} (Default)';
                        hasAccount = true;
                      } else {
                        resolvedAccountDisplay =
                            'No default account designated';
                        hasAccount = false;
                      }

                      return Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 13,
                            color: hasAccount ? tokens.ionCyan : tokens.outflow,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Saving to: ',
                                    style: HorizonTypography.bodySm.copyWith(
                                      color: tokens.textMedium,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: resolvedAccountDisplay,
                                    style: HorizonTypography.bodySm.copyWith(
                                      color: hasAccount
                                          ? tokens.textHigh
                                          : tokens.outflow,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: busy ? null : () => _edit(tx),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Change',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.ionCyan,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${tx.categoryName ?? tx.suggestedCategoryName ?? 'Choose category'}',
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textMedium,
                      fontSize: 11,
                    ),
                  ),
                  if (sms.confirmationErrors[tx.id] ??
                          sms.confirmationIssue(
                            tx,
                            fallbackDefaultAccountId: defaultAccId,
                          )
                      case final String issue) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.outflow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tokens.outflow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        issue,
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.outflow,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      HorizonButton(
                        text: 'Edit',
                        variant: HorizonButtonVariant.secondary,
                        expandWidth: false,
                        height: 34,
                        onPressed: busy ? null : () => _edit(tx),
                      ),
                      const SizedBox(width: 8),
                      HorizonButton(
                        text: 'Reject',
                        variant: HorizonButtonVariant.ghost,
                        expandWidth: false,
                        height: 34,
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
                                        style: HorizonTypography.bodySm,
                                      ),
                                      backgroundColor: tokens.surface3,
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(width: 8),
                      HorizonButton(
                        text: 'Confirm',
                        variant: HorizonButtonVariant.primary,
                        expandWidth: false,
                        height: 34,
                        onPressed: busy ? null : () => _confirm(tx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(DetectedTransactionModel tx) async {
    final tokens = HorizonThemeTokens.of(context);
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
            backgroundColor: tokens.surface2,
            title: Text(
              'Correct Transaction',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: merchant,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Merchant',
                        labelStyle: TextStyle(color: tokens.textMedium),
                      ),
                      maxLength: 150,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a merchant'
                          : null,
                    ),
                    TextFormField(
                      controller: amount,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: tokens.textMedium),
                      ),
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
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: tokens.textMedium),
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
                      dropdownColor: tokens.surface2,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: tokens.textMedium),
                      ),
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
                      dropdownColor: tokens.surface2,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Account',
                        labelStyle: TextStyle(color: tokens.textMedium),
                      ),
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
                      dropdownColor: tokens.surface2,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: tokens.textMedium),
                      ),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: saving ? null : (v) => category = v,
                      validator: (v) => v == null ? 'Choose a category' : null,
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          style: TextStyle(color: tokens.outflow),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialog),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: tokens.textMedium),
                ),
              ),
              TextButton(
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
                child: Text(
                  saving ? 'Saving...' : 'Save Corrections',
                  style: TextStyle(
                    color: tokens.ionCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
