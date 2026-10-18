import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import '../constants/app_motion.dart';

/// Native focus, keyboard and touch feedback share the same enabled state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
      ),
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.quick,
        child: isLoading
            ? Semantics(
                label: '$text, loading',
                liveRegion: true,
                child: const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(
                text,
                key: const ValueKey('label'),
                textAlign: TextAlign.center,
              ),
      ),
    ),
  );
}
