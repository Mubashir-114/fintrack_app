import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// A single settings row in the Profile deck.
///
/// Deliberately flat: hierarchy comes from the icon container, type weight and
/// row rhythm rather than an enclosing card or heavy border.
class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showDivider;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final accent = widget.isDestructive ? tokens.outflow : tokens.ionCyan;
    final titleColor = widget.isDestructive ? tokens.outflow : tokens.textHigh;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: widget.onTap != null,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_pressed != value) setState(() => _pressed = value);
              },
              splashColor: accent.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: HorizonMotion.emphasized,
                color: _pressed
                    ? accent.withValues(alpha: tokens.isDark ? 0.06 : 0.05)
                    : Colors.transparent,
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: tokens.isDark ? 0.12 : 0.09,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isDestructive
                            ? tokens.outflow
                            : tokens.textHigh.withValues(
                                alpha: tokens.isDark ? 0.92 : 0.86,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: HorizonTypography.bodyMd.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              height: 1.3,
                            ),
                          ),
                          if (widget.subtitleWidget != null) ...[
                            const SizedBox(height: 3),
                            widget.subtitleWidget!,
                          ] else if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle!,
                              style: HorizonTypography.bodySm.copyWith(
                                color: tokens.textMedium,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: HorizonDimensions.spaceMD),
                      widget.trailing!,
                    ],
                    if (widget.onTap != null) ...[
                      const SizedBox(width: HorizonDimensions.spaceSM),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: tokens.textLow,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Container(height: 1, color: tokens.rowDivider),
          ),
      ],
    );
  }
}
