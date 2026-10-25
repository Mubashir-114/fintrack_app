import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldFocusNodes = List.generate(4, (_) => FocusNode());

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    for (final node in _fieldFocusNodes) {
      node.dispose();
    }
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading || !_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      CustomToast.showWarning(context, "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess(context, "Registration Successful! Welcome!");
      context.go("/dashboard");
    } else {
      setState(() => _isLoading = false);
      CustomToast.showError(
        context,
        authProvider.errorMessage ?? "Registration Failed",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: tokens.textHigh,
          ),
          onPressed: () => context.go('/login'),
        ),
        title: Column(
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
                  'FINTRACK // IDENTITY',
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Text(
              'Create Account',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient lighting
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.ionCyan.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.electricIndigo.withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scaffold already consumes the keyboard inset. Only add any
                // remaining obstruction, avoiding a second keyboard-sized gap.
                final media = MediaQuery.of(context);
                final consumedInset = media.size.height - constraints.maxHeight;
                final remainingInset = (media.viewInsets.bottom - consumedInset)
                    .clamp(0.0, media.viewInsets.bottom);
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    HorizonDimensions.spaceXL,
                    24,
                    24 + remainingInset,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: HorizonDimensions.formMaxWidth,
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header Framing
                              Text(
                                'Create Account',
                                style: HorizonTypography.headlineLg.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: HorizonDimensions.spaceSM),
                              Text(
                                'Set up your financial operating system profile.',
                                style: HorizonTypography.bodyMd.copyWith(
                                  color: tokens.textMedium,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Form Module
                              HorizonSurface(
                                tier: HorizonSurfaceTier.surface2,
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Full Name Field
                                    HorizonTextField(
                                      inputHeight: 74,
                                      labelSpacing: HorizonDimensions.spaceMD,
                                      controller: nameController,
                                      focusNode: _fieldFocusNodes[0],
                                      onSubmitted: (_) =>
                                          _fieldFocusNodes[1].requestFocus(),
                                      label: 'Full Name',
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Email Field
                                    HorizonTextField(
                                      inputHeight: 74,
                                      labelSpacing: HorizonDimensions.spaceMD,
                                      controller: emailController,
                                      focusNode: _fieldFocusNodes[1],
                                      onSubmitted: (_) =>
                                          _fieldFocusNodes[2].requestFocus(),
                                      label: 'Email Address',
                                      hintText: 'Enter your email address',
                                      prefixIcon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!RegExp(
                                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value)) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Password Field
                                    HorizonTextField(
                                      inputHeight: 74,
                                      labelSpacing: HorizonDimensions.spaceMD,
                                      controller: passwordController,
                                      focusNode: _fieldFocusNodes[2],
                                      onSubmitted: (_) =>
                                          _fieldFocusNodes[3].requestFocus(),
                                      label: 'Password',
                                      hintText: 'At least 6 characters',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: tokens.textMedium,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
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

                                    // Confirm Password Field
                                    HorizonTextField(
                                      inputHeight: 74,
                                      labelSpacing: HorizonDimensions.spaceMD,
                                      controller: confirmPasswordController,
                                      focusNode: _fieldFocusNodes[3],
                                      label: 'Confirm Password',
                                      hintText: 'Re-enter your password',
                                      prefixIcon: Icons.lock_reset_rounded,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _register(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: tokens.textMedium,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirm your password';
                                        }
                                        if (value != passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    // Submit Button
                                    HorizonButton(
                                      key: const ValueKey('register-submit'),
                                      height: 68,
                                      text: 'Create Account',
                                      icon: Icons.arrow_forward_rounded,
                                      variant: HorizonButtonVariant.primary,
                                      isLoading: _isLoading,
                                      onPressed: _register,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Already have account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: HorizonTypography.bodyMd.copyWith(
                                      color: tokens.textMedium,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: Text(
                                      'Sign In',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
