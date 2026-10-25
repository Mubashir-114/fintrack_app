import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../models/companion_model.dart';
import '../../analytics/widgets/fin_character.dart';

/// Contextual FIN insight woven into the dashboard flow.
///
/// Presented as an open row rather than a floating card so the companion reads
/// as part of the financial narrative. Tapping opens FIN in the analytics tab.
class DashboardFinInsight extends StatelessWidget {
  const DashboardFinInsight({
    super.key,
    required this.message,
    required this.onTap,
    this.state = FinCharacterState.explaining,
    this.caption = 'FIN // TELEMETRY INSIGHT',
  });

  final String message;
  final VoidCallback onTap;
  final FinCharacterState state;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HorizonDimensions.borderMD,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: HorizonDimensions.borderMD,
                  border: Border.all(
                    color: tokens.ionCyan.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: FinCharacter(size: 36, state: state),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      caption,
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.ionCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.08 * 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textHigh,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: tokens.ionCyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
