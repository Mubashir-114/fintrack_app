import 'package:flutter/material.dart';
import '../horizon/horizon.dart';

/// Compatibility entry point for the shell's HORIZON navigation dock.
class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  static const double cardHeight = 64;
  static const double activePillHeight = 52;

  @override
  Widget build(BuildContext context) => HorizonNavigationDock(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
  );
}
