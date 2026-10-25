import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_collection.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../analytics/widgets/fin_character.dart';

/// Profile identity masthead.
///
/// The identity is expressed with type, spacing and a single tonal action
/// instead of an oversized outlined card, and FIN stands beside the profile
/// block as a companion rather than an overlay pinned to the viewport edge.
class ProfileIdentityHero extends StatelessWidget {
  const ProfileIdentityHero({
    super.key,
    required this.name,
    required this.email,
    required this.onEdit,
    required this.onOpenFin,
    this.avatarBytes,
  });

  final String name;
  final String email;
  final Uint8List? avatarBytes;
  final VoidCallback onEdit;
  final VoidCallback onOpenFin;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 360;
        final largeText = textScale > 1.5;
        final avatarSize = compact ? 52.0 : 64.0;
        final finSize = compact ? 76.0 : 100.0;

        final identity = _IdentityLine(
          name: name,
          email: email,
          avatarBytes: avatarBytes,
          avatarSize: avatarSize,
          compact: compact,
          onEditAvatar: onEdit,
        );
        final edit = _TonalAction(
          key: const ValueKey('profile-edit'),
          label: 'Edit profile',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        );

        if (largeText || width < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: HorizonDimensions.spaceLG),
              edit,
              const SizedBox(height: HorizonDimensions.spaceXS),
              _FinCompanionRow(onTap: onOpenFin),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: HorizonDimensions.spaceLG),
                  edit,
                ],
              ),
            ),
            const SizedBox(width: HorizonDimensions.spaceMD),
            _FinPresence(size: finSize, onTap: onOpenFin),
          ],
        );
      },
    );
  }
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({
    required this.name,
    required this.email,
    required this.avatarSize,
    required this.compact,
    required this.onEditAvatar,
    this.avatarBytes,
  });

  final String name;
  final String email;
  final double avatarSize;
  final bool compact;
  final VoidCallback onEditAvatar;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HorizonPressable(
          label: 'Edit profile photo',
          onPressed: onEditAvatar,
          child: ProfileAvatar(
            name: name,
            bytes: avatarBytes,
            size: avatarSize,
          ),
        ),
        SizedBox(width: compact ? 14 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.headlineSm.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 18 : 21,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: compact ? 12 : 13,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// FIN standing beside the profile block: fully in frame, captioned and tappable.
class _FinPresence extends StatelessWidget {
  const _FinPresence({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return HorizonPressable(
      key: const ValueKey('profile-fin-presence'),
      label: 'Open FIN companion',
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: HorizonMotion.enter,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.94 + 0.06 * value,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: SizedBox(
              width: size * 0.72,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: size * 0.03,
                    child: Container(
                      width: size * 0.58,
                      height: size * 0.46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tokens.ionCyan.withValues(
                              alpha: tokens.isDark ? 0.14 : 0.09,
                            ),
                            tokens.ionCyan.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FinCharacter(size: size),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FIN',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textMedium,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 13,
                color: tokens.textLow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact FIN access for very large text, where the full figure would crowd
/// the identity.
class _FinCompanionRow extends StatelessWidget {
  const _FinCompanionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      key: const ValueKey('profile-fin-presence'),
      label: 'Open FIN companion',
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: HorizonDimensions.spaceSM),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FinCharacter(size: 48),
            const SizedBox(width: HorizonDimensions.spaceSM),
            Flexible(
              child: Text(
                'FIN companion',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.ionCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: tokens.textLow),
          ],
        ),
      ),
    );
  }
}

class _TonalAction extends StatelessWidget {
  const _TonalAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return HorizonPressable(
      label: label,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HorizonDimensions.marginMobile,
        ),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: HorizonDimensions.borderDefault,
          border: Border.all(color: tokens.rimCyanActive),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tokens.ionCyan),
            const SizedBox(width: HorizonDimensions.spaceSM),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _previewHero(ThemeCollection collection, Brightness brightness) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(collection, brightness),
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
          child: ProfileIdentityHero(
            name: 'Alex Morgan',
            email: 'alex.morgan@example.com',
            onEdit: () {},
            onOpenFin: () {},
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Profile identity hero — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 220),
  brightness: Brightness.dark,
)
Widget profileIdentityHeroDarkPreview() =>
    _previewHero(ThemeCollection.midnightAurora, Brightness.dark);

@Preview(
  name: 'Profile identity hero — Light',
  group: 'FinTrack // HORIZON',
  size: Size(393, 220),
  brightness: Brightness.light,
)
Widget profileIdentityHeroLightPreview() =>
    _previewHero(ThemeCollection.midnightAurora, Brightness.light);

@Preview(
  name: 'Profile identity hero — 2x text',
  group: 'FinTrack // HORIZON',
  size: Size(320, 320),
  brightness: Brightness.dark,
  textScaleFactor: 2,
)
Widget profileIdentityHeroLargeTextPreview() =>
    _previewHero(ThemeCollection.midnightAurora, Brightness.dark);
