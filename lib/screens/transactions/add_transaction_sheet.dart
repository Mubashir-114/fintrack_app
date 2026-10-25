import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/horizon/components/horizon_pressable.dart';
import '../../core/utils/decimal_money.dart';
import '../../core/widgets/custom_toast.dart';
import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/fin_purse_moment.dart';
import 'widgets/transaction_amount_hero.dart';
import 'widgets/transaction_category_selector.dart';
import 'widgets/transaction_field_rows.dart';
import 'widgets/transaction_type_switch.dart';

/// Backwards-compatible wrapper so any external dialog callers stay functional.
class AddEditTransactionDialog extends StatelessWidget {
  final TransactionModel? transaction;
  const AddEditTransactionDialog({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    return AddEditTransactionSheet(transaction: transaction);
  }
}

/// Premium, mobile-first full-height bottom sheet for adding or editing a
/// transaction.
class AddEditTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionSheet({super.key, this.transaction});

  @override
  State<AddEditTransactionSheet> createState() =>
      _AddEditTransactionSheetState();
}

class _AccountSelection {
  const _AccountSelection(this.accountId);
  final int? accountId;
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedType;
  int? _selectedCategoryId;
  int? _selectedAccountId;

  bool get _isIncome => _selectedType == 'income';

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null
          ? DecimalMoney.formatMinor(
              DecimalMoney.parseToMinor(tx.amount.toString()),
            )
          : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx != null
        ? DateTime.tryParse(tx.transactionDate) ?? DateTime.now()
        : DateTime.now();
    _selectedType = tx?.type ?? 'expense';
    _selectedCategoryId = tx?.categoryId;
    _selectedAccountId = tx?.accountId;

    _ensureValidCategorySelection();
  }

  void _ensureValidCategorySelection() {
    final available = _isIncome
        ? CategoryModel.getIncomeCategories()
        : CategoryModel.getExpenseCategories();

    if (_selectedCategoryId != null) {
      final matching = CategoryModel.findById(_selectedCategoryId);
      if (matching == null || matching.type != _selectedType) {
        final byName = widget.transaction != null
            ? CategoryModel.findByName(
                widget.transaction!.category,
                type: _selectedType,
              )
            : null;
        if (byName != null) {
          _selectedCategoryId = byName.id;
        } else if (available.isNotEmpty) {
          _selectedCategoryId = available.first.id;
        }
      }
    } else if (available.isNotEmpty) {
      _selectedCategoryId = available.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(bool income) {
    final newType = income ? 'income' : 'expense';
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      final available = income
          ? CategoryModel.getIncomeCategories()
          : CategoryModel.getExpenseCategories();
      final current = CategoryModel.findById(_selectedCategoryId);
      if (current == null || current.type != newType) {
        _selectedCategoryId = available.isNotEmpty ? available.first.id : null;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickAccount(List<AccountModel> accounts) async {
    final tokens = HorizonThemeTokens.of(context);
    final selection = await showModalBottomSheet<_AccountSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: tokens.surface1,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(HorizonDimensions.radiusXL),
          ),
          border: Border(top: BorderSide(color: tokens.rimNeutral)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.62,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HorizonDimensions.spaceLG,
                    HorizonDimensions.spaceXS,
                    HorizonDimensions.spaceSM,
                    HorizonDimensions.spaceSM,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose account',
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      HorizonPressable(
                        label: 'Close account picker',
                        onPressed: () => Navigator.pop(ctx),
                        child: SizedBox(
                          width: HorizonDimensions.buttonHeight,
                          child: Icon(
                            Icons.close_rounded,
                            color: tokens.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      bottom: HorizonDimensions.spaceMD,
                    ),
                    children: [
                      _AccountOption(
                        key: const ValueKey('account-option-default'),
                        icon: Icons.bookmark_outline_rounded,
                        title: 'Default account',
                        subtitle: 'Use the account currently set as default',
                        selected: _selectedAccountId == null,
                        onTap: () =>
                            Navigator.pop(ctx, const _AccountSelection(null)),
                      ),
                      for (final account in accounts)
                        _AccountOption(
                          key: ValueKey('account-option-${account.id}'),
                          icon: Icons.account_balance_outlined,
                          title: account.displayName,
                          subtitle: account.isDefault
                              ? '${account.currencyCode} · Default account'
                              : account.currencyCode,
                          selected: _selectedAccountId == account.id,
                          onTap: () =>
                              Navigator.pop(ctx, _AccountSelection(account.id)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() => _selectedAccountId = selection.accountId);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      CustomToast.showError(context, "Please choose a category");
      return;
    }

    final provider = context.read<TransactionProvider>();
    final trimmedAmount = _amountController.text.trim();
    final minor = DecimalMoney.parseToMinor(trimmedAmount);
    final amountDouble = double.parse(DecimalMoney.formatMinor(minor));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    bool success;
    if (widget.transaction != null) {
      success = await provider.editTransaction(
        id: widget.transaction!.id,
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amountDouble,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountId: _selectedAccountId,
      );
    } else {
      success = await provider.addTransaction(
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amountDouble,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountId: _selectedAccountId,
      );
    }

    if (success && mounted) {
      context.read<DashboardProvider>().loadDashboardData();
      context.read<ReportProvider>().loadAllReports();
      context.read<BudgetProvider>().loadBudgetStatus();

      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        widget.transaction != null
            ? "Transaction updated"
            : "Transaction added",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "An error occurred",
      );
    }
  }

  String _accountValue(AccountModel? selected, AccountModel? defaultAccount) {
    if (selected != null) return selected.displayName;
    if (defaultAccount != null) {
      return '${defaultAccount.displayName} · default';
    }
    return 'Default account';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final provider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final currency = context.watch<CurrencyProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final categories = _isIncome
        ? CategoryModel.getIncomeCategories()
        : CategoryModel.getExpenseCategories();

    AccountModel? selectedAccount;
    for (final account in accountProvider.accounts) {
      if (account.id == _selectedAccountId) {
        selectedAccount = account;
        break;
      }
    }

    final amountHero = TransactionAmountHero(
      controller: _amountController,
      isIncome: _isIncome,
      currencySymbol: currency.currencySymbol,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Amount is required';
        }
        final clean = value.trim();
        if (!DecimalMoney.isValidDecimal(clean)) {
          return 'Enter a valid positive number';
        }
        if (DecimalMoney.parseToMinor(clean) <= BigInt.zero) {
          return 'Amount must be greater than zero';
        }
        return null;
      },
    );

    final categorySelector = TransactionCategorySelector(
      categories: categories,
      selectedId: _selectedCategoryId,
      isIncome: _isIncome,
      onSelected: (category) =>
          setState(() => _selectedCategoryId = category.id),
    );

    final titleField = TransactionQuietField(
      label: 'Title / Merchant',
      hintText: 'e.g. Corner cafe',
      fieldKey: const ValueKey('transaction-merchant'),
      controller: _titleController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.trim().length < 2) {
          return 'Title must be at least 2 characters';
        }
        return null;
      },
    );

    final accountRow = TransactionMetaRow(
      rowKey: const ValueKey('transaction-account'),
      icon: Icons.account_balance_wallet_outlined,
      label: 'Account',
      value: _accountValue(selectedAccount, accountProvider.defaultAccount),
      actionLabel: 'Change',
      onTap: () => _pickAccount(accountProvider.accounts),
    );

    final dateRow = TransactionMetaRow(
      rowKey: const ValueKey('transaction-date'),
      icon: Icons.calendar_today_outlined,
      label: 'Date',
      value: DateFormat('d MMM yyyy').format(_selectedDate),
      onTap: _selectDate,
    );

    final noteField = TransactionQuietField(
      label: 'Note (optional)',
      hintText: 'Add a detail for later',
      fieldKey: const ValueKey('transaction-note'),
      controller: _noteController,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface1,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(HorizonDimensions.radiusXL),
              ),
              border: Border(top: BorderSide(color: tokens.rimNeutral)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: tokens.isDark ? 0.45 : 0.08,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHeader(
                    title: isEditing ? 'Edit Transaction' : 'New Transaction',
                    onClose: () => Navigator.pop(context),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        HorizonDimensions.spaceLG,
                        0,
                        HorizonDimensions.spaceLG,
                        HorizonDimensions.spaceLG,
                      ),
                      child: Form(
                        key: _formKey,
                        child: _ComposerEntrance(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 660;
                              final typeRow = _TypeRow(
                                isIncome: _isIncome,
                                onChanged: _onTypeChanged,
                              );

                              if (wide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          typeRow,
                                          const SizedBox(
                                            height: HorizonDimensions.spaceXL,
                                          ),
                                          amountHero,
                                          const SizedBox(
                                            height: HorizonDimensions.spaceXL,
                                          ),
                                          categorySelector,
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: HorizonDimensions.spaceXL,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          titleField,
                                          const SizedBox(
                                            height: HorizonDimensions.spaceLG,
                                          ),
                                          accountRow,
                                          _InsetDivider(tokens: tokens),
                                          dateRow,
                                          const SizedBox(
                                            height: HorizonDimensions.spaceLG,
                                          ),
                                          noteField,
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  typeRow,
                                  const SizedBox(
                                    height: HorizonDimensions.spaceXL,
                                  ),
                                  amountHero,
                                  const SizedBox(
                                    height: HorizonDimensions.spaceXL,
                                  ),
                                  categorySelector,
                                  const SizedBox(
                                    height: HorizonDimensions.spaceXL,
                                  ),
                                  titleField,
                                  const SizedBox(
                                    height: HorizonDimensions.spaceLG,
                                  ),
                                  accountRow,
                                  _InsetDivider(tokens: tokens),
                                  dateRow,
                                  const SizedBox(
                                    height: HorizonDimensions.spaceLG,
                                  ),
                                  noteField,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  _StickyActionBar(
                    isEditing: isEditing,
                    isIncome: _isIncome,
                    isLoading: provider.isActionLoading,
                    onPressed: provider.isActionLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: HorizonDimensions.spaceSM),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.textLow.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HorizonDimensions.spaceLG,
            HorizonDimensions.spaceXS,
            HorizonDimensions.spaceSM,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: HorizonTypography.headlineSm.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              HorizonPressable(
                key: const ValueKey('transaction-close'),
                label: 'Close transaction',
                onPressed: onClose,
                child: SizedBox(
                  width: HorizonDimensions.buttonHeight,
                  child: Icon(Icons.close_rounded, color: tokens.textMedium),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.isIncome, required this.onChanged});

  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Only very large text forces the companion onto its own line; the switch
    // fits beside it at every phone width.
    final switchWidget = TransactionTypeSwitch(
      isIncome: isIncome,
      onChanged: onChanged,
    );
    final companion = FinPurseMoment(isIncome: isIncome);

    if (scale > 1.4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switchWidget,
          const SizedBox(height: HorizonDimensions.spaceSM),
          Align(alignment: Alignment.centerRight, child: companion),
        ],
      );
    }

    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: switchWidget,
          ),
        ),
        const SizedBox(width: HorizonDimensions.spaceMD),
        companion,
      ],
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider({required this.tokens});

  final HorizonThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 46),
      child: Container(height: 1, color: tokens.rowDivider),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({
    required this.isEditing,
    required this.isIncome,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isEditing;
  final bool isIncome;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final label = isEditing
        ? 'Save changes'
        : (isIncome ? 'Add income' : 'Add expense');

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.rowDivider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        HorizonDimensions.spaceLG,
        HorizonDimensions.spaceMD,
        HorizonDimensions.spaceLG,
        HorizonDimensions.spaceMD,
      ),
      child: HorizonButton(
        key: const ValueKey('transaction-save'),
        text: label,
        icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
        isLoading: isLoading,
        onPressed: onPressed,
      ),
    );
  }
}

class _ComposerEntrance extends StatelessWidget {
  const _ComposerEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: HorizonMotion.enter,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      label: title,
      selected: selected,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HorizonDimensions.spaceLG,
          vertical: HorizonDimensions.spaceSM,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? tokens.ionCyan.withValues(alpha: 0.14)
                    : tokens.surface2,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? tokens.ionCyan : tokens.textMedium,
              ),
            ),
            const SizedBox(width: HorizonDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HorizonTypography.bodyMd.copyWith(
                      color: tokens.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: tokens.ionCyan),
          ],
        ),
      ),
    );
  }
}
