import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// One command in the operational action row.
class StorageAction {
  const StorageAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color accent;
  final VoidCallback onTap;
}

/// Compact operational actions row for Money Storage.
///
/// Replaces the three boxed command tiles: actions read as one instrument
/// strip separated by hairlines instead of a deck of rounded rectangles.
class StorageActionRow extends StatelessWidget {
  const StorageActionRow({super.key, required this.actions});

  final List<StorageAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final vertical =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(13) > 17;

    Widget action(StorageAction item) {
      final control = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.12),
                    borderRadius: HorizonDimensions.borderDefault,
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, size: 17, color: item.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        maxLines: vertical ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textHigh,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item.caption,
                        maxLines: vertical ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.textLow,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return vertical ? control : Expanded(child: control);
    }

    final children = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0 && !vertical) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(width: 1, color: tokens.rimNeutral),
          ),
        );
      }
      children.add(action(actions[i]));
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: HorizonDimensions.borderLG,
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : Row(children: children),
    );
  }
}
