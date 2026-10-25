import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';
import 'animated_budget_progress.dart';

String resolveCategoryVisualDescriptor(String category) {
  final norm = category.toLowerCase().trim();
  if (norm.contains('health') || norm.contains('medic') || norm.contains('doctor') || norm.contains('hospital') || norm.contains('pharm')) {
    return 'Vitals: Healthy Range';
  }
  if (norm.contains('food') || norm.contains('dining') || norm.contains('grocer') || norm.contains('restaurant')) {
    return 'Dining Allowance';
  }
  if (norm.contains('transport') || norm.contains('transit') || norm.contains('commute') || norm.contains('fuel') || norm.contains('travel') || norm == 'car' || norm.contains('vehicle')) {
    return 'Commute Route Track';
  }
  if (norm.contains('shop') || norm.contains('retail') || norm.contains('cloth') || norm.contains('store')) {
    return 'Retail Spending Gauge';
  }
  if (norm.contains('utilit') || norm.contains('bill') || norm.contains('electric') || norm.contains('water') || norm.contains('gas')) {
    return 'Recurring Billing Segments';
  }
  if (norm.contains('entertain') || norm.contains('movie') || norm.contains('stream') || norm.contains('game')) {
    return 'Media & Leisure Arc';
  }
  return 'General Allowance';
}

/// FinTrack HORIZON — Modern, Open Financial Category Budget Row.
///
/// Replaces the legacy 220dp boxed card with a clean, approximately 92dp row
/// featuring category icon identity, plain financial amounts, animated hairline progress,
/// and smooth tap-to-expand insights.
class CategoryBudgetRow extends StatefulWidget {
  const CategoryBudgetRow({
    super.key,
    required this.budget,
    required this.currency,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetCategoryProgressModel budget;
  final CurrencyProvider currency;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<CategoryBudgetRow> createState() => _CategoryBudgetRowState();
}

class _CategoryBudgetRowState extends State<CategoryBudgetRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delayMs = (widget.index * 45).clamp(0, 260);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.value = 1.0;
        } else {
          _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion && !_controller.isCompleted) {
      _controller.value = 1.0;
    }

    final b = widget.budget;
    final limitNum = double.tryParse(b.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(b.actualSpending) ?? 0.0;
    final remainingNum = double.tryParse(b.remainingAmount) ?? (limitNum - spentNum);
    final utilizationNum = double.tryParse(b.utilizationPercentage) ??
        (limitNum > 0 ? (spentNum / limitNum * 100) : 0.0);
    final projectedNum = double.tryParse(b.projectedSpending) ?? spentNum;

    final isOver = b.status == "exceeded" || spentNum > limitNum;
    final isApproaching = b.status == "approaching_limit" ||
        (!isOver && utilizationNum >= 80.0);

    final progressRatio = limitNum > 0 ? (spentNum / limitNum).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusLabel;
    if (isOver) {
      statusColor = tokens.outflow;
      statusLabel = "OVER BUDGET";
    } else if (isApproaching) {
      statusColor = tokens.warning;
      statusLabel = "80%+ USED";
    } else {
      statusColor = tokens.surplus;
      statusLabel = "ON TRACK";
    }

    final catIcon = getCategoryIcon(b.category);
    final catAccentColor = getCategoryColor(b.category);
    final descriptor = resolveCategoryVisualDescriptor(b.category);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: reduceMotion ? const AlwaysStoppedAnimation(1.0) : _fadeAnimation,
          child: SlideTransition(
            position: reduceMotion ? const AlwaysStoppedAnimation(Offset.zero) : _slideAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: tokens.surface1,
          borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
          border: Border.all(
            color: isOver
                ? tokens.outflow.withValues(alpha: 0.35)
                : (isApproaching ? tokens.warning.withValues(alpha: 0.35) : tokens.rimNeutral),
            width: isOver || isApproaching ? 1.2 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Category icon, Name + Descriptor (Expanded vertical stack), Status badge, Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Compact icon badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: catAccentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
                      ),
                      alignment: Alignment.center,
                      child: Icon(catIcon, size: 17, color: catAccentColor),
                    ),
                    const SizedBox(width: 10),

                    // Category Name & Descriptor (Safe multi-line title block)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            b.category,
                            style: HorizonTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: tokens.textHigh,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (descriptor.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              descriptor,
                              style: HorizonTypography.bodySm.copyWith(
                                fontSize: 10,
                                color: tokens.textLow,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Compact Semantic Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    // Action Menu (Edit / Delete)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert_rounded, size: 18, color: tokens.textMedium),
                        color: tokens.surface2,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                          side: BorderSide(color: tokens.rimNeutral),
                        ),
                        onSelected: (action) {
                          if (action == 'edit') {
                            widget.onEdit();
                          } else if (action == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: tokens.textHigh),
                                const SizedBox(width: 10),
                                Text(
                                  'Edit Amount',
                                  style: HorizonTypography.bodySm.copyWith(
                                    color: tokens.textHigh,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: tokens.outflow),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: HorizonTypography.bodySm.copyWith(
                                    color: tokens.outflow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 2: Spent and Limit Line (Full Width, Safe Wrap)
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Spent: ${widget.currency.format(spentNum)}",
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: isOver ? tokens.outflow : tokens.textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "·",
                      style: TextStyle(color: tokens.textLow, fontSize: 11),
                    ),
                    Text(
                      "Limit: ${widget.currency.format(limitNum)}",
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: tokens.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 3: Animated Hairline Progress Bar
                AnimatedBudgetProgress(
                  progressRatio: progressRatio,
                  color: statusColor,
                  trackColor: tokens.surface3.withValues(alpha: 0.7),
                  height: 4.0,
                ),

                const SizedBox(height: 8),

                // Row 4: Remaining amount on left, days left on right (Safe Layout)
                Builder(
                  builder: (context) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                    if (textScale > 1.3) {
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            remainingNum >= 0
                                ? "Remaining: ${widget.currency.format(remainingNum)}"
                                : "Over by: ${widget.currency.format(remainingNum.abs())}",
                            style: HorizonTypography.bodySm.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: remainingNum >= 0 ? tokens.textHigh : tokens.outflow,
                              fontFeatures: HorizonTypography.tabularFigures,
                            ),
                          ),
                          Text(
                            b.daysRemaining > 0
                                ? "${b.daysRemaining} days left"
                                : "${utilizationNum.toStringAsFixed(1)}% used",
                            style: HorizonTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: tokens.textLow,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            remainingNum >= 0
                                ? "Remaining: ${widget.currency.format(remainingNum)}"
                                : "Over by: ${widget.currency.format(remainingNum.abs())}",
                            style: HorizonTypography.bodySm.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: remainingNum >= 0 ? tokens.textHigh : tokens.outflow,
                              fontFeatures: HorizonTypography.tabularFigures,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b.daysRemaining > 0
                              ? "${b.daysRemaining} days left"
                              : "${utilizationNum.toStringAsFixed(1)}% used",
                          style: HorizonTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: tokens.textLow,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Expandable Details (Category Spending Insights)
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: tokens.rowDivider),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Category Spending Insights",
                          style: HorizonTypography.labelCaps.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tokens.textHigh,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      HorizonPressable(
                        label: "Edit Limit",
                        onPressed: widget.onEdit,
                        child: Text(
                          "Edit Limit",
                          style: HorizonTypography.labelCaps.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tokens.ionCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Projected EOM Spend:",
                          style: HorizonTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: tokens.textMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.currency.format(projectedNum),
                        style: HorizonTypography.bodySm.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.textHigh,
                          fontFeatures: HorizonTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
