import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

/// FinTrack // HORIZON — Authentication Screen.
/// Clean, single-hierarchy vertical layout with keyboard resilience,
/// autofill compatibility, and zero duplicate headings.
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
      CustomToast.showError(
        context,
        authProvider.errorMessage ?? 'Invalid credentials. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;

    return Scaffold(
      backgroundColor: tokens.canvas,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: tokens.textHigh,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: tokens.ionCyan,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tokens.ionCyan.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FINTRACK // HORIZON',
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.ionCyan,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient lighting glows
          Positioned(
            top: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.ionCyan.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.electricIndigo.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: HorizonDimensions.marginMobile,
                    vertical: isCompact ? 12 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (isCompact ? 24 : 48),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Hero Emblem & Single Title
                                Center(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: tokens.surface2,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: tokens.rimCyanActive,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 22,
                                      color: tokens.ionCyan,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sign In',
                                  textAlign: TextAlign.center,
                                  style: HorizonTypography.headlineLg.copyWith(
                                    color: tokens.textHigh,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter your credentials to access your financial vault.',
                                  textAlign: TextAlign.center,
                                  style: HorizonTypography.bodyMd.copyWith(
                                    color: tokens.textMedium,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 20 : 28),

                                // Interactive Form Module
                                HorizonSurface(
                                  tier: HorizonSurfaceTier.surface2,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Email Field
                                      HorizonTextField(
                                        controller: emailController,
                                        label: 'Email address',
                                        hintText: 'name@example.com',
                                        prefixIcon: Icons.alternate_email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.email],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Email is required';
                                          }
                                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value.trim())) {
                                            return 'Enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Password Field
                                      HorizonTextField(
                                        controller: passwordController,
                                        label: 'Password',
                                        hintText: 'Enter your password',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
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
                                          onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword,
                                          ),
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
                                      const SizedBox(height: 24),

                                      // Sign In Button
                                      HorizonButton(
                                        text: 'Sign In',
                                        icon: Icons.arrow_forward_rounded,
                                        variant: HorizonButtonVariant.primary,
                                        isLoading: _isLoading,
                                        onPressed: _login,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Navigation Link to Register
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'New to FinTrack? ',
                                      style: HorizonTypography.bodyMd.copyWith(
                                        color: tokens.textMedium,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/register'),
                                      child: Text(
                                        'Create an account',
                                        style: HorizonTypography.bodyMd.copyWith(
                                          color: tokens.ionCyan,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
