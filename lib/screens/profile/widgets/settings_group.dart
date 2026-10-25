import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// A settings section in the Profile deck.
///
/// The label plus hairline establishes the group instead of an enclosing card,
/// so several sections read as one page rather than stacked panels.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title!,
                    style: HorizonTypography.labelMd.copyWith(
                      color: tokens.textMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: HorizonDimensions.spaceMD),
                Expanded(child: Container(height: 1, color: tokens.rowDivider)),
              ],
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceXS),
        ],
        ...children,
      ],
    );
  }
}
