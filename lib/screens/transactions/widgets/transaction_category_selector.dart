import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';

/// Category selector: one horizontally scrolling rail of quiet tiles.
///
/// Replaces the wrapped grid of padded chips so categories stay scannable and
/// the composer keeps a predictable height at every width.
class TransactionCategorySelector extends StatelessWidget {
  const TransactionCategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.isIncome,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final bool isIncome;
  final ValueChanged<CategoryModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    // Selection uses the primary accent: choosing a category is not a flow
    // direction, so it must not read as a warning colour.
    final accent = tokens.ionCyan;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5);
    final tileWidth = 96 * scale.clamp(1.0, 1.5);
    final labelLines = scale > 1.4 ? 3 : 2;
    final railHeight = math.max(
      82.0,
      20 + 6 + (11 * 1.2 * labelLines * scale) + 22,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Category',
          style: HorizonTypography.labelMd.copyWith(
            color: tokens.textMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceSM + 2),
        SizedBox(
          height: railHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < categories.length;
                        index++
                      ) ...[
                        if (index > 0)
                          const SizedBox(width: HorizonDimensions.spaceSM),
                        _CategoryTile(
                          category: categories[index],
                          selected: categories[index].id == selectedId,
                          accent: accent,
                          width: tileWidth,
                          labelLines: labelLines,
                          onPressed: () => onSelected(categories[index]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: HorizonDimensions.spaceLG,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tokens.surface1.withValues(alpha: 0),
                          tokens.surface1,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.accent,
    required this.width,
    required this.labelLines,
    required this.onPressed,
  });

  final CategoryModel category;
  final bool selected;
  final Color accent;
  final double width;
  final int labelLines;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return HorizonPressable(
      key: ValueKey('cat_chip_${category.id}'),
      label: category.name,
      selected: selected,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : HorizonMotion.quick,
        curve: HorizonMotion.emphasized,
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: HorizonDimensions.spaceSM + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: tokens.isDark ? 0.18 : 0.12)
              : tokens.surface2.withValues(alpha: tokens.isDark ? 0.55 : 1),
          borderRadius: HorizonDimensions.borderMD,
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getCategoryIcon(category.name),
              size: 20,
              color: selected ? accent : tokens.textMedium,
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: labelLines,
              overflow: TextOverflow.ellipsis,
              style: HorizonTypography.bodySm.copyWith(
                color: selected ? tokens.textHigh : tokens.textMedium,
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
