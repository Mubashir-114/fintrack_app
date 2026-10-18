import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
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
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: DisplayFeatureSubScreen(
        anchorPoint: Offset.zero,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FinTrackLoadingScene(animate: !_showRetry),
                          const SizedBox(height: 12),
                          Text(
                            'FinTrack',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your money, beautifully in control.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          if (_showRetry) ...[
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _initialize,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry connection'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
