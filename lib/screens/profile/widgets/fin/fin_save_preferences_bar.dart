import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';

/// Reusable save preferences button bar for FIN.
class FinSavePreferencesBar extends StatelessWidget {
  final VoidCallback onSave;
  final bool isLoading;

  const FinSavePreferencesBar({
    super.key,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return HorizonButton(
      text: 'SAVE PREFERENCES',
      icon: Icons.tune,
      isLoading: isLoading,
      variant: HorizonButtonVariant.primary,
      onPressed: onSave,
    );
  }
}
