import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';
import 'horizon_navigation_dock.dart';

/// Responsive cockpit navigation rail for tablet and desktop viewports (width >= 600px).
class HorizonNavigationRail extends StatelessWidget {
  const HorizonNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = HorizonNavigationDock.defaultDestinations,
    this.header,
    this.trailing,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<HorizonNavigationDestination> destinations;
  final Widget? header;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: tokens.surface1,
        border: Border(
          right: BorderSide(
            color: tokens.rimNeutral,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            if (header != null) ...[
              const SizedBox(height: 16),
              header!,
            ] else ...[
              const SizedBox(height: 24),
              // FinTrack HORIZON minimal orbital logo badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: HorizonDimensions.borderMD,
                  border: Border.all(
                    color: tokens.rimCyan,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.all_inclusive_rounded,
                  color: tokens.ionCyan,
                  size: 24,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: destinations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final isSelected = index == selectedIndex;
                  return _HorizonRailItem(
                    destination: dest,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                  );
                },
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _HorizonRailItem extends StatelessWidget {
  const _HorizonRailItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final HorizonNavigationDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: HorizonDimensions.borderMD,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: HorizonMotion.quick,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? tokens.surface2 : Colors.transparent,
                      borderRadius: HorizonDimensions.borderMD,
                      border: isSelected
                          ? Border.all(color: tokens.rimCyanActive, width: 1)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected
                              ? (destination.selectedIcon ?? destination.icon)
                              : destination.icon,
                          size: 22,
                          color: isSelected ? tokens.ionCyan : tokens.textMedium,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: tokens.ionCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination.label,
                    style: HorizonTypography.labelCaps.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tokens.textHigh : tokens.textLow,
                    ),
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
