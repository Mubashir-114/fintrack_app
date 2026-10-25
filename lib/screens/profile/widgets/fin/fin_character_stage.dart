import 'package:flutter/material.dart';

import '../../../../core/horizon/horizon.dart';
import 'fin_live_character.dart';
import 'fin_motion_state.dart';

/// Reusable living character stage with ambient lighting and mood preview controls.
class FinCharacterStage extends StatelessWidget {
  final FinMotionState currentMotion;
  final ValueChanged<FinMotionState>? onMotionChanged;
  final VoidCallback? onCharacterTap;
  final bool animationsEnabled;
  final double characterSize;
  final bool showMotionSelector;

  const FinCharacterStage({
    super.key,
    required this.currentMotion,
    this.onMotionChanged,
    this.onCharacterTap,
    this.animationsEnabled = true,
    this.characterSize = 125,
    this.showMotionSelector = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final responsiveCharSize = isCompact ? (characterSize * 0.88).clamp(95.0, 120.0) : characterSize;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: tokens.surface1.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.rimNeutral),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Atmospheric Ambient Glow
              Positioned(
                top: 0,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.ionCyan.withValues(alpha: 0.12),
                        tokens.luminousGold.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Stage pedestal rim beneath FIN
              Positioned(
                bottom: showMotionSelector ? 52 : 12,
                child: Container(
                  width: responsiveCharSize * 0.95,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tokens.surface3.withValues(alpha: 0.6),
                        tokens.surface2.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border.all(
                      color: tokens.rimNeutral.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                ),
              ),

              // 3. Central Content Column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Living Character with Live Motion
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FinLiveCharacter(
                      motionState: currentMotion,
                      size: responsiveCharSize,
                      animationsEnabled: animationsEnabled,
                      onTap: onCharacterTap,
                      showShadow: true,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Motion preview chips selector
                  if (showMotionSelector) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final motion in FinMotionState.values) ...[
                            _buildMotionChip(context, tokens, motion),
                            if (motion != FinMotionState.values.last)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMotionChip(
    BuildContext context,
    HorizonThemeTokens tokens,
    FinMotionState motion,
  ) {
    final isSelected = currentMotion == motion;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Set FIN motion state to ${motion.label}',
      child: GestureDetector(
        onTap: () => onMotionChanged?.call(motion),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? tokens.surface3 : tokens.surface2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? tokens.rimCyan : tokens.rimNeutral.withValues(alpha: 0.6),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                motion.icon,
                size: 13,
                color: isSelected ? tokens.ionCyan : tokens.textMedium,
              ),
              const SizedBox(width: 5),
              Text(
                motion.label,
                style: HorizonTypography.labelCaps.copyWith(
                  color: isSelected ? tokens.ionCyan : tokens.textMedium,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
