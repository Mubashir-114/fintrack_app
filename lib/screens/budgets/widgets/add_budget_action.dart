import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// FinTrack HORIZON — Modern Floating Add Budget Action.
///
/// Compact visual footprint, crisp press feedback, and proper dock clearance.
class AddBudgetAction extends StatelessWidget {
  const AddBudgetAction({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: tokens.ionCyan,
      foregroundColor: tokens.isDark ? Colors.black : Colors.white,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        "Add Budget",
        style: HorizonTypography.labelCaps.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
          color: tokens.isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
