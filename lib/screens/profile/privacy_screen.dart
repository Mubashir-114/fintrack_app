import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/horizon/horizon.dart';

/// Technical notice and telemetry privacy boundary control center.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textHigh),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HORIZON // PROTOCOL',
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.ionCyan,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Privacy & Security Control Center',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: HorizonDimensions.marginMobile,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Telemetry Status Ribbon
                  HorizonSurface(
                    tier: HorizonSurfaceTier.surface1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: tokens.ionCyan,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATA & PERMISSIONS',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.ionCyan,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your approved records are stored by the FinTrack backend.',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textHigh,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Handling Card
                  HorizonSurface(
                    tier: HorizonSurfaceTier.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Storage & Ledger Records',
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your name, email and password hash authenticate your account. Financial records you enter or approve are stored by the FinTrack backend in MySQL to provide tracking, budgets, reports and planning. Financial response caches use platform secure storage on native devices. Web financial caches stay in memory only. Cached responses expire after 24 hours; signing out clears app-managed caches.',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FIN Companion Boundaries Card
                  HorizonSurface(
                    tier: HorizonSurfaceTier.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIN Companion Privacy Boundaries',
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'FIN uses authorized records already stored in FinTrack. Financial records and your questions are blocked from external model providers. Optional external wording services can receive only fixed, context-free phrases. FIN cannot access your bank or independently read your SMS inbox.',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SMS Import Control Card
                  HorizonSurface(
                    tier: HorizonSurfaceTier.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS Import & Device Permissions',
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SMS import is optional and available on Android. A scan reads messages on your device and sends detected financial-message information to the backend for review. Nothing is added to your ledger until approved. You can decline scanning and continue using manual entry. Revoke SMS access in device settings at any time; revoking access does not delete previous imports.',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                            height: 1.5,
                          ),
                        ),
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.android ||
                                defaultTargetPlatform ==
                                    TargetPlatform.iOS)) ...[
                          const SizedBox(height: 14),
                          HorizonButton(
                            text: 'Open Device Permission Settings',
                            icon: Icons.settings_outlined,
                            variant: HorizonButtonVariant.secondary,
                            onPressed: () async {
                              var opened = false;
                              try {
                                opened = await openAppSettings();
                              } catch (_) {}
                              if (!context.mounted || opened) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Open your device settings and select FinTrack permissions.',
                                    style: HorizonTypography.bodySm,
                                  ),
                                  backgroundColor: tokens.surface3,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Analytics & Tracking Notice
                  HorizonSurface(
                    tier: HorizonSurfaceTier.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Advertising SDKs',
                          style: HorizonTypography.headlineSm.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No advertising, marketing subscription or analytics tracking SDK is bundled in this application. Exported reports are saved strictly at your request. Access tokens use platform secure storage.',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
