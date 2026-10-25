import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/horizon/components/horizon_pressable.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_collection.dart';
import '../../providers/auth_provider.dart';

/// FinTrack // HORIZON — focused account access.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _authErrorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authErrorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess(context, 'Welcome back! Login successful.');
      context.go('/dashboard');
    } else {
      final message =
          authProvider.errorMessage ?? 'Invalid credentials. Please try again.';
      setState(() {
        _isLoading = false;
        _authErrorMessage = message;
      });
      CustomToast.showError(context, message);
    }
  }

  void _clearAuthError(String _) {
    if (_authErrorMessage != null) {
      setState(() => _authErrorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                MediaQuery.sizeOf(context).width >=
                HorizonDimensions.breakpointDesktop;
            final horizontalPadding = isWide
                ? HorizonDimensions.marginDesktop
                : HorizonDimensions.marginMobile;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWide ? HorizonDimensions.spaceLG : HorizonDimensions.spaceSM,
                horizontalPadding,
                HorizonDimensions.spaceXL,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      (isWide
                          ? HorizonDimensions.spaceXL
                          : HorizonDimensions.spaceLG),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: _LoginEntrance(
                      child: isWide
                          ? _buildWideLayout(tokens)
                          : _buildMobileLayout(tokens),
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

  Widget _buildMobileLayout(HorizonThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(tokens),
        const SizedBox(height: HorizonDimensions.spaceXL),
        _buildFormSurface(tokens),
        const SizedBox(height: HorizonDimensions.spaceLG),
        _buildRegistrationAction(tokens),
        const SizedBox(height: HorizonDimensions.spaceLG),
        _buildFooter(tokens),
      ],
    );
  }

  Widget _buildWideLayout(HorizonThemeTokens tokens) {
    final availableWidth =
        MediaQuery.sizeOf(context).width -
        (HorizonDimensions.marginDesktop * 2);
    final formWidth = (availableWidth * 0.58).clamp(320.0, 430.0).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildBrandPanel(tokens)),
        const SizedBox(width: HorizonDimensions.spaceXL),
        SizedBox(
          width: formWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormSurface(tokens),
              const SizedBox(height: HorizonDimensions.spaceLG),
              _buildRegistrationAction(tokens),
              const SizedBox(height: HorizonDimensions.spaceLG),
              _buildFooter(tokens),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(HorizonThemeTokens tokens) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(tokens),
        SizedBox(
          height: compact
              ? HorizonDimensions.spaceLG
              : HorizonDimensions.spaceXL,
        ),
        Text(
          'Welcome back.',
          style:
              (compact
                      ? HorizonTypography.headlineMd
                      : HorizonTypography.headlineLg)
                  .copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w700,
                  ),
        ),
        const SizedBox(height: HorizonDimensions.spaceSM),
        Text(
          'Take control of your next move.',
          style: HorizonTypography.displayHero.copyWith(
            color: tokens.textHigh,
            fontSize: compact ? 30 : 34,
            height: 1.08,
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceMD),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 260 : 340),
          child: Text(
            compact
                ? 'Your finances, in focus.'
                : 'Your financial operating system is ready when you are.',
            style: HorizonTypography.bodyMd.copyWith(color: tokens.textMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    HorizonThemeTokens tokens, {
    bool compactOverride = false,
  }) {
    final canGoBack = Navigator.of(context).canPop();
    final compact =
        compactOverride ||
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: canGoBack
              ? IconButton(
                  key: const ValueKey('login-back'),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: tokens.textHigh,
                    size: 21,
                  ),
                )
              : null,
        ),
        const SizedBox(width: HorizonDimensions.spaceSM),
        FinTrackLogo(
          size: 34,
          collection: tokens.collection,
          showBorder: true,
          showShadow: false,
        ),
        const SizedBox(width: HorizonDimensions.spaceSM),
        Text(
          'FINTRACK',
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textHigh,
            fontSize: 11,
            letterSpacing: 1.8,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: HorizonDimensions.spaceXS),
          Text(
            '// HORIZON',
            style: HorizonTypography.labelCaps.copyWith(
              color: tokens.ionCyan,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
        const Spacer(),
        _StatusMarker(tokens: tokens, compact: compact),
      ],
    );
  }

  Widget _buildBrandPanel(HorizonThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(tokens, compactOverride: true),
        const SizedBox(height: 70),
        Container(
          width: 72,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.ionCyan,
            borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
            boxShadow: [
              BoxShadow(
                color: tokens.ionCyan.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceXL),
        Text(
          'A clearer view\nof your money.',
          style: HorizonTypography.displayHero.copyWith(
            color: tokens.textHigh,
            fontSize: 42,
          ),
        ),
        const SizedBox(height: HorizonDimensions.spaceLG),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            'Sign in to keep your accounts, spending and next decisions in one calm place.',
            style: HorizonTypography.bodyLg.copyWith(color: tokens.textMedium),
          ),
        ),
        const SizedBox(height: 48),
        _BrandTelemetry(tokens: tokens),
      ],
    );
  }

  Widget _buildFormSurface(HorizonThemeTokens tokens) {
    return HorizonSurface(
      tier: HorizonSurfaceTier.surface1,
      borderRadius: HorizonDimensions.borderLG,
      padding: const EdgeInsets.fromLTRB(
        HorizonDimensions.marginMobile,
        HorizonDimensions.spaceLG,
        HorizonDimensions.marginMobile,
        HorizonDimensions.marginMobile,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ACCOUNT ACCESS',
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.ionCyan,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: HorizonDimensions.spaceSM),
              Text(
                'Sign in to FinTrack',
                style: HorizonTypography.headlineSm.copyWith(
                  color: tokens.textHigh,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: HorizonDimensions.spaceXS),
              Text(
                'Use your account email and password to continue.',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                ),
              ),
              const SizedBox(height: HorizonDimensions.spaceXL),
              HorizonTextField(
                key: const ValueKey('login-email'),
                controller: emailController,
                label: 'Email address',
                showInlineLabel: false,
                hintText: 'name@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: _clearAuthError,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: HorizonDimensions.spaceLG),
              HorizonTextField(
                key: const ValueKey('login-password'),
                controller: passwordController,
                label: 'Password',
                showInlineLabel: false,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: _clearAuthError,
                onSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: tokens.textMedium,
                    size: 20,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (_authErrorMessage != null) ...[
                const SizedBox(height: HorizonDimensions.spaceMD),
                _AuthErrorBanner(message: _authErrorMessage!, tokens: tokens),
              ],
              const SizedBox(height: HorizonDimensions.spaceXL),
              HorizonButton(
                key: const ValueKey('login-submit'),
                text: 'Continue to FinTrack',
                icon: Icons.arrow_forward_rounded,
                variant: HorizonButtonVariant.primary,
                isLoading: _isLoading,
                onPressed: _login,
              ),
              AnimatedSwitcher(
                duration: HorizonMotion.quick,
                child: _isLoading
                    ? Padding(
                        key: const ValueKey('login-loading-message'),
                        padding: const EdgeInsets.only(
                          top: HorizonDimensions.spaceSM,
                        ),
                        child: Text(
                          'Checking your account…',
                          textAlign: TextAlign.center,
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationAction(HorizonThemeTokens tokens) {
    return HorizonPressable(
      key: const ValueKey('login-create-account'),
      label: 'Create an account',
      onPressed: () => context.push('/register'),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: HorizonDimensions.buttonHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: HorizonDimensions.marginMobile,
        ),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: HorizonDimensions.borderDefault,
          border: Border.all(color: tokens.rimCyanActive),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: HorizonDimensions.spaceSM,
          children: [
            Text(
              'New to FinTrack?',
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.textMedium,
              ),
            ),
            Text(
              'Create an account',
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.ionCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.arrow_outward_rounded, size: 15, color: tokens.ionCyan),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(HorizonThemeTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.tune_rounded, size: 14, color: tokens.textLow),
        const SizedBox(width: HorizonDimensions.spaceSM),
        Flexible(
          child: Text(
            'A focused view of your personal finance workspace.',
            textAlign: TextAlign.center,
            style: HorizonTypography.bodySm.copyWith(color: tokens.textLow),
          ),
        ),
      ],
    );
  }
}

class _LoginEntrance extends StatelessWidget {
  const _LoginEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : HorizonMotion.standard,
      curve: HorizonMotion.enter,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
    );
  }
}

class _StatusMarker extends StatelessWidget {
  const _StatusMarker({required this.tokens, required this.compact});

  final HorizonThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: tokens.surplus,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: HorizonDimensions.spaceSM),
        if (!compact)
          Text(
            'SECURE ACCESS',
            style: HorizonTypography.labelCaps.copyWith(
              color: tokens.textMedium,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
      ],
    );
  }
}

class _BrandTelemetry extends StatelessWidget {
  const _BrandTelemetry({required this.tokens});

  final HorizonThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: tokens.rimCyanActive)),
            const SizedBox(width: HorizonDimensions.spaceSM),
            Icon(Icons.arrow_upward_rounded, size: 15, color: tokens.ionCyan),
          ],
        ),
        const SizedBox(height: HorizonDimensions.spaceSM),
        Text(
          'HORIZON ACCESS / 01',
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textMedium,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message, required this.tokens});

  final String message;
  final HorizonThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HorizonDimensions.spaceMD,
        vertical: HorizonDimensions.spaceSM,
      ),
      decoration: BoxDecoration(
        color: tokens.outflow.withValues(alpha: tokens.isDark ? 0.12 : 0.08),
        borderRadius: HorizonDimensions.borderDefault,
        border: Border.all(color: tokens.outflow.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: tokens.outflow),
          const SizedBox(width: HorizonDimensions.spaceSM),
          Expanded(
            child: Text(
              message,
              style: HorizonTypography.bodySm.copyWith(color: tokens.outflow),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'FinTrack Login — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 852),
  brightness: Brightness.dark,
)
Widget loginScreenDarkPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, Brightness.dark),
    home: const LoginScreen(),
  );
}

@Preview(
  name: 'FinTrack Login — Light',
  group: 'FinTrack // HORIZON',
  size: Size(393, 852),
  brightness: Brightness.light,
)
Widget loginScreenLightPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(
      ThemeCollection.midnightAurora,
      Brightness.light,
    ),
    home: const LoginScreen(),
  );
}
