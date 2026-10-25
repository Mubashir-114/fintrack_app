import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

class HorizonNavigationDestination {
  const HorizonNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Floating cockpit telemetry navigation dock for FinTrack // HORIZON.
/// Anchored 24px above display edge, rendered in Level 3 surface with 95% opacity,
/// hairline cyan rim, and sharp 4px cyan telemetry dot beneath the active glyph.
class HorizonNavigationDock extends StatelessWidget {
  const HorizonNavigationDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = defaultDestinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<HorizonNavigationDestination> destinations;

  static const List<HorizonNavigationDestination> defaultDestinations = [
    HorizonNavigationDestination(
      label: 'Home',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    HorizonNavigationDestination(
      label: 'Ledger',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    HorizonNavigationDestination(
      label: 'Budgets',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    HorizonNavigationDestination(
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    HorizonNavigationDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final media = MediaQuery.of(context);
    final horizontalMargin = media.size.width <= 360
        ? 12.0
        : HorizonDimensions.marginMobile;
    final dockRadius = HorizonDimensions.borderFull;

    final dockBg = tokens.surface3.withValues(alpha: 0.95);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(
        bottom: HorizonDimensions.bottomDockClearance,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalMargin, 6, horizontalMargin, 0),
        child: Semantics(
          container: true,
          label: 'Primary navigation',
          child: ClipRRect(
            key: const ValueKey('floating_navigation_card'),
            borderRadius: dockRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dockBg,
                  borderRadius: dockRadius,
                  border: Border.all(color: tokens.rimDock, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: tokens.isDark ? 0.65 : 0.15,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: HorizonDimensions.dockHeight,
                  child: Row(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        Expanded(
                          flex: index == selectedIndex ? 2 : 1,
                          child: _HorizonDockItem(
                            destination: destinations[index],
                            selected: index == selectedIndex,
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

class _HorizonDockItem extends StatelessWidget {
  const _HorizonDockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final HorizonNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : HorizonMotion.quick;
    final itemRadius = HorizonDimensions.borderFull;

    return Semantics(
      key: ValueKey('floating_navigation_${destination.label.toLowerCase()}'),
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
              curve: HorizonMotion.emphasized,
              height: 52,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 12 : 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? tokens.surface2.withValues(alpha: 0.90)
                    : Colors.transparent,
                borderRadius: itemRadius,
                border: selected
                    ? Border.all(color: tokens.rimCyanActive, width: 1)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: tokens.ionCyan.withValues(alpha: 0.16),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: selected
                      ? Row(
                          key: ValueKey('${destination.label}_selected'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destination.selectedIcon ?? destination.icon,
                                  size: 20,
                                  color: tokens.ionCyan,
                                ),
                                const SizedBox(height: 3),
                                // 4px circular active cyan dot anchored beneath the glyph
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: tokens.ionCyan,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: tokens.ionCyan.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                destination.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          key: ValueKey('${destination.label}_unselected'),
                          destination.icon,
                          size: 22,
                          color: tokens.textMedium,
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
