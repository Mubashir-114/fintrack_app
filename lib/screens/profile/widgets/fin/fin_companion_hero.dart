import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';
import 'fin_character_stage.dart';
import 'fin_motion_state.dart';
import 'fin_speech_panel.dart';
import 'fin_status_chip.dart';

/// Redesigned hero section for FIN Companion Settings.
///
/// Eliminates giant empty boxed cards, replaces static mascot images with
/// a living animated character stage, and provides clear visual hierarchy.
class FinCompanionHero extends StatelessWidget {
  final FinMotionState currentMotion;
  final ValueChanged<FinMotionState>? onMotionChanged;
  final bool isActive;
  final bool isDocked;
  final String placement;
  final String currentQuote;
  final int quoteIndex;
  final int totalQuotes;
  final VoidCallback? onCycleQuote;
  final bool animationsEnabled;

  const FinCompanionHero({
    super.key,
    required this.currentMotion,
    this.onMotionChanged,
    required this.isActive,
    required this.isDocked,
    required this.placement,
    required this.currentQuote,
    required this.quoteIndex,
    required this.totalQuotes,
    this.onCycleQuote,
    this.animationsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Companion Header & Subtitle
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FIN Companion',
                  style: HorizonTypography.headlineSm.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Financial guide and proactive insight partner',
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textMedium,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            // Current status indicator
            FinStatusChip(
              isActive: isActive,
              isDocked: isDocked,
              placement: placement,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Living Character Stage
        FinCharacterStage(
          currentMotion: currentMotion,
          onMotionChanged: onMotionChanged,
          onCharacterTap: onCycleQuote,
          animationsEnabled: animationsEnabled && isActive,
          showMotionSelector: isActive,
        ),
        const SizedBox(height: 12),

        // 3. Integrated Speech & Guidance Thought
        FinSpeechPanel(
          quote: currentQuote,
          quoteIndex: quoteIndex,
          totalQuotes: totalQuotes,
          onTap: onCycleQuote,
        ),
      ],
    );
  }
}
