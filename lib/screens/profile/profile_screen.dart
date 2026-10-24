import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = HorizonThemeTokens.of(ctx);
        final themeProvider = ctx.watch<ThemeProvider>();
        return AlertDialog(
          title: Text(
            "About FinTrack",
            style: HorizonTypography.headlineSm.copyWith(
              color: tokens.textHigh,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: tokens.surface2,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinTrackLogo(
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/dashboard');
                },
                size: 64,
                collection: themeProvider.collection,
                borderRadius: 18,
                showBorder: true,
                showShadow: true,
              ),
              const SizedBox(height: 14),
              Text(
                "FinTrack 2.0 // HORIZON",
                style: HorizonTypography.headlineSm.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Version 1.0.0 (${themeProvider.collection.displayName} Edition)",
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "\u00a9 ${DateTime.now().year} FinTrack",
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Engineered with Flutter, Provider, and HORIZON cinematic tokens. Optimized for rapid transaction tracking and local deterministic analysis.",
                textAlign: TextAlign.center,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "CLOSE",
                style: TextStyle(
                  color: tokens.ionCyan,
                  fontWeight: FontWeight.w700,
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
        backgroundColor: tokens.surface2,
        title: Text(
          "Confirm Logout",
          style: HorizonTypography.headlineSm.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "Are you sure you want to log out of your account on this device?",
          style: HorizonTypography.bodySm.copyWith(
            color: tokens.textMedium,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: tokens.textMedium),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (!mounted) return;
              context.go("/login");
            },
            child: Text(
              "LOGOUT",
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final tokens = HorizonThemeTokens.of(context);

    final name = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : "FinTrack User";
    final email = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : "Email unavailable";

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.ionCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'FINTRACK // HORIZON',
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Text(
              'Profile & Identity Command Deck',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          HorizonDimensions.marginMobile,
          HorizonDimensions.spaceSM,
          HorizonDimensions.marginMobile,
          HorizonDimensions.dockClearance,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Atmospheric Horizon Arc & Profile Identity Header ────────
            HorizonSurface(
              tier: HorizonSurfaceTier.surface2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Light Arc Glow
                  Positioned(
                    top: -30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.ionCyan.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar Cluster with Ion Rim
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: tokens.ionCyan.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: ProfileAvatar(
                                  name: name,
                                  bytes: context.watch<AuthProvider>().avatarBytes,
                                  size: 72,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/profile/edit'),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: tokens.ionCyan,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: tokens.ionCyan.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    size: 15,
                                    color: Color(0xFF00363C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Identity Metadata
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HorizonTypography.headlineMd.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HorizonTypography.labelMd.copyWith(
                              color: tokens.ionCyan,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Honest Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tokens.surface3,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: tokens.rimNeutral),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: tokens.ionCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'FinTrack Member',
                                  style: HorizonTypography.labelCaps.copyWith(
                                    color: tokens.textMedium,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Quick Actions Bar ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: HorizonButton(
                    text: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    variant: HorizonButtonVariant.secondary,
                    onPressed: () => context.push('/profile/edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HorizonButton(
                    text: 'FIN Companion',
                    icon: Icons.auto_awesome_outlined,
                    variant: HorizonButtonVariant.secondary,
                    onPressed: () => context.push('/profile/fin'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Group 1: Preferences & Companion ─────────────────────────
            SettingsGroup(
              title: "Preferences & Appearance",
              children: [
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: "Appearance",
                  subtitle: "Visual themes, dark/light contrast",
                  onTap: () => context.push('/profile/appearance'),
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Accounts & Wallets",
                  subtitle: "Manage bank accounts, credit cards and cash wallets",
                  onTap: () => context.push('/accounts'),
                ),
                SettingsTile(
                  icon: Icons.attach_money_rounded,
                  title: "Display Currency",
                  showDivider: false,
                  subtitleWidget: Consumer<CurrencyProvider>(
                    builder: (context, currency, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current currency: ${currency.selectedCurrencyString}',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Consumer<CurrencyProvider>(
                    builder: (context, currency, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tokens.surface3,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.rimNeutral),
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
                  onTap: () {
                    final currencyProv = context.read<CurrencyProvider>();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          "Select Display Currency",
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: tokens.surface2,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            {'label': 'USD (\$)', 'code': 'USD'},
                            {'label': 'EUR (€)', 'code': 'EUR'},
                            {'label': 'GBP (£)', 'code': 'GBP'},
                            {'label': 'INR (₹)', 'code': 'INR'},
                          ].map(
                            (c) => ListTile(
                              title: Text(
                                c['label']!,
                                style: HorizonTypography.bodyMd.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: currencyProv.currencyCode == c['code']
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: tokens.ionCyan,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                currencyProv.setCurrency(c['code']!);
                                Navigator.pop(ctx);
                                CustomToast.showSuccess(
                                  context,
                                  "Currency updated to ${c['label']}",
                                );
                              },
                            ),
                          ).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Group 2: Security & Privacy ──────────────────────────────
            SettingsGroup(
              title: "Security & Control",
              children: [
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Security & Password",
                  subtitle: "Change password and credentials",
                  onTap: () => context.push('/profile/security'),
                ),
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: "Privacy & Data Controls",
                  subtitle: "Storage, SMS permissions and telemetry",
                  onTap: () => context.push('/profile/privacy'),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: "About Application",
                  subtitle: "Version 1.0.0 // HORIZON",
                  showDivider: false,
                  onTap: _showAbout,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Group 3: Account Operations ──────────────────────────────
            SettingsGroup(
              title: "Account Operations",
              children: [
                SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: "Delete account & data",
                  subtitle: "Password confirmation required",
                  isDestructive: true,
                  onTap: () => context.push('/profile/delete'),
                ),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: "Log Out",
                  subtitle: "Sign out of your active session on this device",
                  isDestructive: true,
                  showDivider: false,
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
