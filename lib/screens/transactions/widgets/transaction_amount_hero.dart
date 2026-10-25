import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// The composer's focal point: a symbol-integrated, oversized amount entry with
/// no container chrome, ruled by a single accent hairline.
class TransactionAmountHero extends StatelessWidget {
  const TransactionAmountHero({
    super.key,
    required this.controller,
    required this.isIncome,
    required this.currencySymbol,
    required this.validator,
    this.focusNode,
  });

  final TextEditingController controller;
  final bool isIncome;
  final String currencySymbol;
  final FormFieldValidator<String> validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final accent = isIncome ? tokens.surplus : tokens.outflow;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isIncome ? 'Amount received' : 'Amount spent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.labelMd.copyWith(
                  color: tokens.textMedium,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: HorizonDimensions.spaceSM),
            AnimatedContainer(
              duration: reduceMotion ? Duration.zero : HorizonMotion.quick,
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: reduceMotion ? Duration.zero : HorizonMotion.quick,
              style: HorizonTypography.labelCaps.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              child: Text(isIncome ? 'Inflow' : 'Outflow'),
            ),
          ],
        ),
        const SizedBox(height: HorizonDimensions.spaceMD),
        FormField<String>(
          validator: (_) => validator(controller.text),
          builder: (field) {
            final hasError = field.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        currencySymbol,
                        style: HorizonTypography.headlineLg.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: HorizonDimensions.spaceSM),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('transaction-amount'),
                        controller: controller,
                        focusNode: focusNode,
                        style: HorizonTypography.displayHero.copyWith(
                          color: tokens.textHigh,
                          fontSize: 44,
                          height: 1.05,
                          letterSpacing: -1.4,
                          fontFeatures: HorizonTypography.tabularFigures,
                        ),
                        cursorColor: accent,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (field.hasError) field.validate();
                        },
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: HorizonTypography.displayHero.copyWith(
                            color: tokens.textLow.withValues(alpha: 0.55),
                            fontSize: 44,
                            height: 1.05,
                            letterSpacing: -1.4,
                            fontFeatures: HorizonTypography.tabularFigures,
                          ),
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HorizonDimensions.spaceSM),
                AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : HorizonMotion.quick,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: (hasError ? tokens.outflow : accent).withValues(
                      alpha: hasError ? 0.9 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    field.errorText!,
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.outflow,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
