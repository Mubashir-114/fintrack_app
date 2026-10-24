import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/services/token_service.dart';
import '../../core/widgets/fintrack_loading_scene.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Checking your saved session…';
  bool _showRetry = false;
  bool _initializing = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;
    setState(() {
      _showRetry = false;
      _statusMessage = 'Checking your saved session…';
    });
    try {
      final token = await TokenService.getToken();
      if (!mounted) return;
      if (token == null) {
        context.go('/login');
        return;
      }
      setState(() => _statusMessage = 'Verifying your session…');
      _statusTimer?.cancel();
      _statusTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(
            () => _statusMessage =
                'Still waiting for the server. First connections can take a little longer.',
          );
        }
      });
      final success = await context.read<AuthProvider>().loadCurrentUser();
      _statusTimer?.cancel();
      if (!mounted) return;
      if (success) {
        context.go('/dashboard');
      } else {
        final remainingToken = await TokenService.getToken();
        if (!mounted) return;
        if (remainingToken == null) {
          context.go('/login');
        } else {
          _showError();
        }
      }
    } catch (_) {
      _statusTimer?.cancel();
      if (mounted) _showError();
    } finally {
      _initializing = false;
    }
  }

  void _showError() => setState(() {
    _showRetry = true;
    _statusMessage =
        'Unable to verify your session. Check your connection and try again.';
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: DisplayFeatureSubScreen(
        anchorPoint: Offset.zero,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Atmospheric Horizon Backdrop ─────────────────────────────
              Positioned(
                top: -80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tokens.electricIndigo.withValues(alpha: 0.22),
                          tokens.ionCyan.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main Content ─────────────────────────────────────────────
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Loading / Brand Scene
                        FinTrackLoadingScene(animate: !_showRetry),
                        const SizedBox(height: 16),

                        // Horizon Wordmark
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'FinTrack',
                              style: HorizonTypography.displayHero.copyWith(
                                color: tokens.textHigh,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: tokens.ionCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: tokens.ionCyan.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Eyebrow
                        Text(
                          'WELCOME TO FINTRACK',
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'Your money, beautifully in control.',
                          textAlign: TextAlign.center,
                          style: HorizonTypography.bodyMd.copyWith(
                            color: tokens.textMedium,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Telemetry Status Badge
                        HorizonSurface(
                          tier: HorizonSurfaceTier.surface1,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _showRetry ? tokens.outflow : tokens.ionCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _statusMessage,
                                    textAlign: TextAlign.center,
                                    style: HorizonTypography.bodySm.copyWith(
                                      color: tokens.textMedium,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_showRetry) ...[
                          const SizedBox(height: 24),
                          HorizonButton(
                            text: 'Retry Connection',
                            icon: Icons.refresh_rounded,
                            variant: HorizonButtonVariant.secondary,
                            onPressed: _initialize,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
