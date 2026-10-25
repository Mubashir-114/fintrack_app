import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';

/// Supporting text input: label above, hairline underline, no filled box.
///
/// Used for the lighter fields so the amount and category keep the visual
/// weight in the composer.
class TransactionQuietField extends StatelessWidget {
  const TransactionQuietField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.fieldKey,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final underline = UnderlineInputBorder(
      borderSide: BorderSide(color: tokens.rowDivider),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: HorizonTypography.labelMd.copyWith(
            color: tokens.textMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceXS),
        TextFormField(
          key: fieldKey,
          controller: controller,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          textInputAction: textInputAction,
          style: HorizonTypography.bodyMd.copyWith(
            color: tokens.textHigh,
            fontSize: 15,
          ),
          cursorColor: tokens.ionCyan,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: HorizonTypography.bodyMd.copyWith(
              color: tokens.textLow,
              fontSize: 15,
            ),
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.only(top: 4, bottom: 10),
            border: underline,
            enabledBorder: underline,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tokens.ionCyan, width: 1.4),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tokens.outflow),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tokens.outflow, width: 1.4),
            ),
            errorStyle: HorizonTypography.bodySm.copyWith(
              color: tokens.outflow,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact account / date row: quiet icon, label, current value and a clear
/// change affordance instead of a filled dropdown field.
class TransactionMetaRow extends StatelessWidget {
  const TransactionMetaRow({
    super.key,
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.actionLabel = 'Change',
  });

  final Key rowKey;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return HorizonPressable(
      key: rowKey,
      label: '$label: $value. $actionLabel',
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: tokens.textMedium),
            ),
            const SizedBox(width: HorizonDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textMedium,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HorizonTypography.bodyMd.copyWith(
                      color: tokens.textHigh,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HorizonDimensions.spaceSM),
            Text(
              actionLabel,
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.ionCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 17, color: tokens.textLow),
          ],
        ),
      ),
    );
  }
}
