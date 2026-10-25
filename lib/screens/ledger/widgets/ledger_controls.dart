import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';

class LedgerHeader extends StatelessWidget {
  const LedgerHeader({
    super.key,
    required this.period,
    required this.count,
    required this.onManage,
    required this.onImport,
    this.compact = false,
  });
  final String period;
  final int? count;
  final VoidCallback onManage;
  final VoidCallback onImport;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ledger',
                style:
                    (compact
                            ? HorizonTypography.headlineMd
                            : HorizonTypography.headlineLg)
                        .copyWith(color: tokens.textHigh),
              ),
            ),
            _LedgerIconAction(
              key: const ValueKey('ledger-manage'),
              label: 'Manage all transactions',
              icon: Icons.tune_rounded,
              onPressed: onManage,
            ),
            _LedgerIconAction(
              key: const ValueKey('ledger-import'),
              label: 'SMS transactions',
              icon: Icons.sms_outlined,
              onPressed: onImport,
            ),
          ],
        ),
        const SizedBox(height: HorizonDimensions.spaceXS),
        Text(
          [
            period,
            if (count != null)
              '$count ${count == 1 ? 'transaction' : 'transactions'}',
          ].join(' · '),
          style: HorizonTypography.bodySm.copyWith(color: tokens.textMedium),
        ),
      ],
    );
  }
}

class _LedgerIconAction extends StatelessWidget {
  const _LedgerIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: HorizonPressable(
      label: label,
      onPressed: onPressed,
      child: SizedBox(
        width: HorizonDimensions.buttonHeight,
        child: Icon(
          icon,
          size: HorizonDimensions.spaceLG,
          color: HorizonThemeTokens.of(context).textMedium,
        ),
      ),
    ),
  );
}

class LedgerSearchField extends StatefulWidget {
  const LedgerSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  State<LedgerSearchField> createState() => _LedgerSearchFieldState();
}

class _LedgerSearchFieldState extends State<LedgerSearchField> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final border = OutlineInputBorder(
      borderRadius: HorizonDimensions.borderDefault,
      borderSide: BorderSide.none,
    );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : HorizonMotion.quick,
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: HorizonDimensions.borderDefault,
        border: Border.all(
          color: _focus.hasFocus ? tokens.primary : tokens.rimNeutral,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) => TextField(
          key: const ValueKey('ledger-search'),
          controller: widget.controller,
          focusNode: _focus,
          onChanged: widget.onChanged,
          style: HorizonTypography.bodyMd.copyWith(color: tokens.textHigh),
          cursorColor: tokens.primary,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _focus.unfocus(),
          decoration: InputDecoration(
            hintText: 'Search transactions',
            hintStyle: HorizonTypography.bodyMd.copyWith(
              color: tokens.textMedium,
            ),
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              vertical: HorizonDimensions.spaceMD,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: HorizonDimensions.spaceLG,
              color: tokens.textMedium,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: HorizonDimensions.buttonHeight,
              minHeight: HorizonDimensions.buttonHeight,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : _LedgerIconAction(
                    key: const ValueKey('ledger-search-clear'),
                    label: 'Clear search',
                    icon: Icons.close_rounded,
                    onPressed: widget.onClear,
                  ),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ),
    );
  }
}

class LedgerFilterRail extends StatelessWidget {
  const LedgerFilterRail({
    super.key,
    required this.selectedType,
    required this.dateLabel,
    required this.onTypeChanged,
    required this.onDate,
    required this.onReset,
    required this.hasFilters,
  });
  final String? selectedType;
  final String? dateLabel;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onDate;
  final VoidCallback onReset;
  final bool hasFilters;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in <String?, String>{
              null: 'All',
              'income': 'Income',
              'expense': 'Expenses',
            }.entries)
              _LedgerFilter(
                label: entry.value,
                selected: selectedType == entry.key,
                onPressed: () => onTypeChanged(entry.key),
                controlKey: ValueKey('ledger-filter-${entry.key ?? 'all'}'),
              ),
            _LedgerFilter(
              label: dateLabel ?? 'Date',
              icon: Icons.calendar_today_outlined,
              selected: dateLabel != null,
              onPressed: onDate,
              controlKey: const ValueKey('ledger-filter-date'),
            ),
            if (hasFilters)
              _LedgerFilter(
                label: 'Reset',
                onPressed: onReset,
                controlKey: const ValueKey('ledger-filter-reset'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerFilter extends StatelessWidget {
  const _LedgerFilter({
    required this.label,
    required this.onPressed,
    required this.controlKey,
    this.selected = false,
    this.icon,
  });
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onPressed;
  final Key controlKey;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      key: controlKey,
      label: label,
      selected: selected,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : HorizonMotion.quick,
        curve: HorizonMotion.emphasized,
        constraints: const BoxConstraints(
          minHeight: HorizonDimensions.buttonHeight,
        ),
        padding: const EdgeInsets.all(HorizonDimensions.spaceMD),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: selected
                  ? tokens.primary
                  : tokens.canvas.withValues(alpha: 0),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: HorizonDimensions.marginMobile,
                color: tokens.textMedium,
              ),
              const SizedBox(width: HorizonDimensions.spaceSM),
            ],
            Text(
              label,
              style: HorizonTypography.bodySm.copyWith(
                color: selected ? tokens.textHigh : tokens.textMedium,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LedgerAddTransactionAction extends StatelessWidget {
  const LedgerAddTransactionAction({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      key: const ValueKey('ledger-add-transaction'),
      label: 'Add transaction',
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.primary,
          borderRadius: HorizonDimensions.borderFull,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HorizonDimensions.spaceLG,
            vertical: HorizonDimensions.spaceMD,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: tokens.onPrimary,
                size: HorizonDimensions.spaceLG,
              ),
              const SizedBox(width: HorizonDimensions.spaceSM),
              Flexible(
                child: Text(
                  'Transaction',
                  style: HorizonTypography.bodyMd.copyWith(
                    color: tokens.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
