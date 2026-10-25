import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || _isChangingPassword) return;

    setState(() {
      _isChangingPassword = true;
    });

    final provider = context.read<AuthProvider>();
    final success = await provider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isChangingPassword = false;
    });

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      CustomToast.showSuccess(context, "Password updated. Sign in again.");
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go('/login');
      } else {
        Navigator.of(context).pop();
      }
    } else {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to update password",
      );
    }
  }

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
              'Change Password',
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: HorizonDimensions.marginMobile,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Header Card
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tokens.ionCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.rimNeutral),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: tokens.ionCyan,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password Security",
                              style: HorizonTypography.bodyMd.copyWith(
                                color: tokens.textHigh,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Choose a strong password with at least 6 characters.",
                              style: HorizonTypography.bodySm.copyWith(
                                color: tokens.textMedium,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  child: Column(
                    children: [
                      HorizonTextField(
                        controller: _currentPasswordController,
                        label: "Current Password",
                        hintText: "Enter current password",
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureCurrent,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: tokens.textMedium,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Current password is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      HorizonTextField(
                        controller: _newPasswordController,
                        label: "New Password",
                        hintText: "At least 6 characters",
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: _obscureNew,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: tokens.textMedium,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "New password is required";
                          }
                          if (val.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      HorizonTextField(
                        controller: _confirmPasswordController,
                        label: "Confirm New Password",
                        hintText: "Re-enter new password",
                        prefixIcon: Icons.check_circle_outline_rounded,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleChangePassword(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: tokens.textMedium,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Please confirm your password";
                          }
                          if (val != _newPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                HorizonButton(
                  text: "Update Password",
                  icon: Icons.check_circle_outline,
                  variant: HorizonButtonVariant.primary,
                  isLoading: _isChangingPassword,
                  onPressed: _handleChangePassword,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
