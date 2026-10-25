import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import 'widgets/profile_identity_hero.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _twoColumnBreakpoint = 720;
  static const double _maxContentWidth = 780;

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = HorizonThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.surface1,
          title: Text(
            'About FinTrack',
            style: HorizonTypography.headlineSm.copyWith(
              color: tokens.textHigh,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinTrackLogo(
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/dashboard');
                },
                size: 64,
                collection: tokens.collection,
                borderRadius: 18,
                showBorder: true,
                showShadow: true,
              ),
              const SizedBox(height: 14),
              Text(
                'FinTrack',
                style: HorizonTypography.headlineSm.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Version 1.0.0 · ${tokens.collection.displayName}',
                textAlign: TextAlign.center,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '© ${DateTime.now().year} FinTrack',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textLow,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(
                  color: tokens.ionCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    final provider = context.read<AuthProvider>();
    final tokens = HorizonThemeTokens.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface1,
        title: Text(
          'Log out?',
          style: HorizonTypography.headlineSm.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will need your email and password to sign in again on this device.',
          style: HorizonTypography.bodySm.copyWith(
            color: tokens.textMedium,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.textMedium)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (!mounted) return;
              context.go('/login');
            },
            child: Text(
              'Log out',
              style: TextStyle(
                color: tokens.outflow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    final tokens = HorizonThemeTokens.of(context);
    final currencyProvider = context.read<CurrencyProvider>();
    const options = [
      {'label': 'USD (\$)', 'code': 'USD'},
      {'label': 'EUR (€)', 'code': 'EUR'},
      {'label': 'GBP (£)', 'code': 'GBP'},
      {'label': 'INR (₹)', 'code': 'INR'},
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface1,
        title: Text(
          'Display currency',
          style: HorizonTypography.headlineSm.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (c) => InkWell(
                  onTap: () {
                    currencyProvider.setCurrency(c['code']!);
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(
                      context,
                      'Display currency set to ${c['label']}',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HorizonDimensions.marginTablet,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c['label']!,
                            style: HorizonTypography.bodyMd.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (currencyProvider.currencyCode == c['code'])
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: tokens.ionCyan,
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final user = auth.currentUser;

    final name = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : 'FinTrack User';
    final email = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : 'Email unavailable';

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= _twoColumnBreakpoint;
            final horizontal = twoColumn
                ? HorizonDimensions.marginDesktop
                : HorizonDimensions.marginMobile;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                HorizonDimensions.spaceLG,
                horizontal,
                HorizonDimensions.dockClearance,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: _ProfileEntrance(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(tokens: tokens),
                        const SizedBox(height: HorizonDimensions.spaceXL),
                        ProfileIdentityHero(
                          name: name,
                          email: email,
                          avatarBytes: auth.avatarBytes,
                          onEdit: () => context.push('/profile/edit'),
                          onOpenFin: () => context.push('/profile/fin'),
                        ),
                        const SizedBox(height: HorizonDimensions.spaceXL + 4),
                        if (twoColumn)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _preferences(tokens),
                                    const SizedBox(
                                      height: HorizonDimensions.spaceXL,
                                    ),
                                    _finTrack(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: HorizonDimensions.spaceXL),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _security(),
                                    const SizedBox(
                                      height: HorizonDimensions.spaceXL,
                                    ),
                                    _account(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _preferences(tokens),
                              const SizedBox(height: HorizonDimensions.spaceXL),
                              _security(),
                              const SizedBox(height: HorizonDimensions.spaceXL),
                              _finTrack(),
                              const SizedBox(height: HorizonDimensions.spaceXL),
                              _account(),
                            ],
                          ),
                        const SizedBox(height: HorizonDimensions.spaceXL),
                        _buildAboutFooter(tokens),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _preferences(HorizonThemeTokens tokens) {
    return SettingsGroup(
      title: 'Preferences',
      children: [
        SettingsTile(
          key: const ValueKey('profile-appearance'),
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme and display mode',
          onTap: () => context.push('/profile/appearance'),
        ),
        SettingsTile(
          key: const ValueKey('profile-accounts'),
          icon: Icons.account_balance_wallet_outlined,
          title: 'Accounts & money storage',
          subtitle: 'Bank accounts, cards and cash',
          onTap: () => context.push('/accounts'),
        ),
        SettingsTile(
          key: const ValueKey('profile-currency'),
          icon: Icons.payments_outlined,
          title: 'Display currency',
          showDivider: false,
          subtitleWidget: Consumer<CurrencyProvider>(
            builder: (context, currency, child) => Text(
              'Showing amounts in ${currency.selectedCurrencyString}',
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.textMedium,
                height: 1.35,
              ),
            ),
          ),
          trailing: Consumer<CurrencyProvider>(
            builder: (context, currency, child) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.spaceSM,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: HorizonDimensions.borderSM,
              ),
              child: Text(
                currency.currencyCode,
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          onTap: _showCurrencyPicker,
        ),
      ],
    );
  }

  Widget _security() {
    return SettingsGroup(
      title: 'Security',
      children: [
        SettingsTile(
          key: const ValueKey('profile-security'),
          icon: Icons.lock_outline_rounded,
          title: 'Security & password',
          subtitle: 'Password and sign-in credentials',
          onTap: () => context.push('/profile/security'),
        ),
        SettingsTile(
          key: const ValueKey('profile-privacy'),
          icon: Icons.shield_outlined,
          title: 'Privacy',
          subtitle: 'Data storage and permissions',
          showDivider: false,
          onTap: () => context.push('/profile/privacy'),
        ),
      ],
    );
  }

  Widget _finTrack() {
    return SettingsGroup(
      title: 'FinTrack',
      children: [
        SettingsTile(
          key: const ValueKey('profile-fin-settings'),
          icon: Icons.auto_awesome_outlined,
          title: 'FIN companion',
          subtitle: 'Presence and preferences',
          onTap: () => context.push('/profile/fin'),
        ),
        SettingsTile(
          key: const ValueKey('profile-sms-import'),
          icon: Icons.sms_outlined,
          title: 'SMS import',
          subtitle: 'Import transactions from messages',
          showDivider: false,
          onTap: () => context.push('/sms-import'),
        ),
      ],
    );
  }

  Widget _account() {
    return SettingsGroup(
      title: 'Account',
      children: [
        SettingsTile(
          key: const ValueKey('profile-logout'),
          icon: Icons.logout_rounded,
          title: 'Log out',
          subtitle: 'End this session on this device',
          isDestructive: true,
          onTap: _confirmLogout,
        ),
        SettingsTile(
          key: const ValueKey('profile-delete'),
          icon: Icons.delete_outline_rounded,
          title: 'Delete account',
          subtitle: 'Remove your account and data',
          isDestructive: true,
          showDivider: false,
          onTap: () => context.push('/profile/delete'),
        ),
      ],
    );
  }

  Widget _buildAboutFooter(HorizonThemeTokens tokens) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _showAbout,
        borderRadius: HorizonDimensions.borderDefault,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HorizonDimensions.spaceSM,
            vertical: HorizonDimensions.spaceSM,
          ),
          child: Text(
            'FinTrack 1.0.0 · ${tokens.collection.displayName}',
            style: HorizonTypography.bodySm.copyWith(color: tokens.textLow),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.tokens});

  final HorizonThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: HorizonTypography.headlineLg.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceSM),
        Text(
          'Your account, security and preferences.',
          style: HorizonTypography.bodyMd.copyWith(color: tokens.textMedium),
        ),
      ],
    );
  }
}

class _ProfileEntrance extends StatelessWidget {
  const _ProfileEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: HorizonMotion.enter,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
    );
  }
}
