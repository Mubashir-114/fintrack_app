import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fin_surface.dart';
import '../../accounts/widgets/money_text.dart';

class PremiumSummaryCard extends StatelessWidget {
  const PremiumSummaryCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(18),
    this.animatedHighlight = false,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final bool animatedHighlight;

  @override
  Widget build(BuildContext context) {
    final surface = FinSurface(
      accent: accent,
      emphasized: true,
      padding: padding,
      child: child,
    );
    return animatedHighlight ? FinReveal(child: surface) : surface;
  }
}

class PremiumMetricCard extends StatefulWidget {
  const PremiumMetricCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.accent,
    this.trend,
    this.trendIsPositive,
    this.currencyCode = 'INR',
    this.trailing,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color accent;
  final String? trend;
  final bool? trendIsPositive;
  final String currencyCode;
  final Widget? trailing;

  @override
  State<PremiumMetricCard> createState() => _PremiumMetricCardState();
}

class _PremiumMetricCardState extends State<PremiumMetricCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label:
          '${widget.label}, ${MoneyText.format(widget.amount, widget.currencyCode)}',
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? .985 : 1,
          duration: AppMotion.press,
          child: FinSurface(
            accent: widget.accent,
            emphasized: true,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FinIconTile(
                      icon: widget.icon,
                      color: widget.accent,
                      size: 34,
                    ),
                    const Spacer(),
                    if (widget.trend != null)
                      _TrendPill(
                        value: widget.trend!,
                        positive: widget.trendIsPositive ?? true,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedAmountText(
                  decimalString: widget.amount,
                  currencyCode: widget.currencyCode,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.45,
                    color: widget.accent,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(height: 9),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.35,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(fontSize: 11, color: muted)),
              ],
            ],
          ),
        ),
        ?trailing,
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 15),
            label: Text(actionLabel!),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

class PremiumEmptyStateCard extends StatelessWidget {
  const PremiumEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final accent = this.accent ?? colors.primary;
    final muted = colors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [accent.withValues(alpha: .1), colors.surface]
              : [accent.withValues(alpha: .07), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -18,
            top: -35,
            child: Icon(icon, size: 112, color: accent.withValues(alpha: .045)),
          ),
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .25)),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.4, color: muted),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(132, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedAmountText extends StatelessWidget {
  const AnimatedAmountText({
    super.key,
    required this.decimalString,
    this.currencyCode = 'INR',
    this.style,
    this.showSign = false,
  });

  final String decimalString;
  final String currencyCode;
  final TextStyle? style;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final amount = MoneyText(
      key: ValueKey('$currencyCode:$decimalString:$showSign'),
      decimalString: decimalString,
      currencyCode: currencyCode,
      showSign: showSign,
      style: style,
    );
    if (reduceMotion) return amount;
    return AnimatedSwitcher(
      duration: AppMotion.reveal,
      switchInCurve: AppMotion.enter,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .22),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: amount,
    );
  }
}

class DashboardGlowChip extends StatelessWidget {
  const DashboardGlowChip({
    super.key,
    required this.label,
    this.icon = Icons.verified_rounded,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.of(context).secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .08), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .25,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSkeletonCard extends StatelessWidget {
  const DashboardSkeletonCard({super.key, this.height = 120, this.accent});

  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final accent = this.accent ?? colors.primary;
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [accent.withValues(alpha: .08), colors.surface]
              : [accent.withValues(alpha: .05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(width: 82, height: 10, borderRadius: 5),
          SizedBox(height: 11),
          ShimmerLoading(width: 168, height: 24, borderRadius: 7),
          SizedBox(height: 15),
          ShimmerLoading(width: double.infinity, height: 8, borderRadius: 4),
        ],
      ),
    );
  }
}

class DashboardEntrance extends StatelessWidget {
  const DashboardEntrance({
    super.key,
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return FinReveal(child: child);
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.value, required this.positive});

  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = positive ? colors.success : colors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
