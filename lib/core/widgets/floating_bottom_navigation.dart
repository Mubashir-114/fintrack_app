import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import '../constants/app_motion.dart';
import '../constants/app_colors.dart';

/// A compact, floating primary navigation control for phone layouts.
///
/// The selected destination expands in place so all five destinations remain
/// reachable on compact devices without a horizontal overflow.
class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  // Keep the shell's bottomNavigationBar child intrinsically bounded. A
  // bottomNavigationBar can receive loose vertical constraints; using only a
  // minimum height there lets the card (and its selected pill) stretch.
  static const double cardHeight = 64;
  static const double activePillHeight = 52;

  static const _destinations = <_FloatingNavigationDestination>[
    _FloatingNavigationDestination('Home', Icons.grid_view_rounded),
    _FloatingNavigationDestination('Ledger', Icons.receipt_long_rounded),
    _FloatingNavigationDestination(
      'Budgets',
      Icons.account_balance_wallet_rounded,
    ),
    _FloatingNavigationDestination('Reports', Icons.bar_chart_rounded),
    _FloatingNavigationDestination('Profile', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontalMargin = media.size.width <= 360 ? 12.0 : AppDimensions.md;
    final cardRadius = BorderRadius.circular(AppDimensions.radiusXL);
    final glassColor = Color.lerp(
      colors.surface,
      colors.elevated,
      isDark ? .30 : .12,
    )!.withValues(alpha: isDark ? .88 : .94);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalMargin, 10, horizontalMargin, 0),
        child: Semantics(
          container: true,
          label: 'Primary navigation',
          child: ClipRRect(
            key: const ValueKey('floating_navigation_card'),
            borderRadius: cardRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: cardRadius,
                  border: Border.all(
                    color: colors.cardBorder.withValues(alpha: isDark ? .82 : .9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? .28 : .13),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: cardHeight,
                  child: Row(
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        Expanded(
                          flex: index == selectedIndex ? 2 : 1,
                          child: _FloatingNavigationItem(
                            destination: _destinations[index],
                            selected: index == selectedIndex,
                            reduceMotion: reduceMotion,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavigationDestination {
  const _FloatingNavigationDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _FloatingNavigationItem extends StatelessWidget {
  const _FloatingNavigationItem({
    required this.destination,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final _FloatingNavigationDestination destination;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.quick;
    final itemRadius = BorderRadius.circular(AppDimensions.radiusLG);

    return Semantics(
      key: ValueKey('floating_navigation_${destination.label.toLowerCase()}'),
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: itemRadius,
            child: AnimatedContainer(
              key: selected
                  ? const ValueKey('floating_navigation_active_pill')
                  : null,
              duration: duration,
              curve: AppMotion.emphasized,
              height: FloatingBottomNavigation.activePillHeight,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 12 : 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [colors.primary, colors.primaryDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: itemRadius,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .24),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.center,
                    fit: StackFit.passthrough,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: 0,
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    key: ValueKey(selected ? destination.label : 'icon-only'),
                    height: 50,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          destination.icon,
                          size: 22,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : colors.textSecondary,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
