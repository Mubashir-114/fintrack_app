import 'package:flutter/material.dart';

import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Open section header: a caps title, optional supporting caption and an
/// optional action. Sections built on this stay unboxed — rhythm comes from
/// typography and hairlines instead of nested containers.
class HorizonSectionHeader extends StatelessWidget {
  const HorizonSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? caption;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: HorizonDimensions.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: tokens.ionCyan),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: HorizonTypography.headlineSm.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textHigh,
              ),
            ),
          ),
          if (caption != null)
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  caption!,
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.textLow,
                    fontSize: 10,
                    letterSpacing: 0.08 * 10,
                  ),
                ),
              ),
            ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Semantics(
                  container: true,
                  button: true,
                  label: actionLabel,
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: HorizonDimensions.borderSM,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: HorizonTypography.labelCaps.copyWith(
                              color: tokens.ionCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.06 * 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: tokens.ionCyan,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
