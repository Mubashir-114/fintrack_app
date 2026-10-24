import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../providers/auth_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_busy || !_form.currentState!.validate()) return;
    final tokens = HorizonThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'Permanently delete your account?',
          style: HorizonTypography.headlineSm.copyWith(
            color: tokens.textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This removes your profile and financial records from the active database. This cannot be undone.',
          style: HorizonTypography.bodySm.copyWith(
            color: tokens.textMedium,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep account', style: TextStyle(color: tokens.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete account',
              style: TextStyle(
                color: tokens.outflow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final success = await auth.deleteAccount(password: _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = success ? null : auth.errorMessage;
    });
    if (success) {
      _password.clear();
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account deleted from the active database.',
            style: HorizonTypography.bodySm,
          ),
          backgroundColor: tokens.surface3,
        ),
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
                color: tokens.outflow,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Account Deletion',
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning Alert Hero
                    HorizonSurface(
                      tier: HorizonSurfaceTier.surface2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tokens.outflow.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tokens.outflow.withValues(alpha: 0.4)),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: tokens.outflow,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Irreversible Action',
                                  style: HorizonTypography.headlineSm.copyWith(
                                    color: tokens.outflow,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deleting your account removes your profile, accounts, transactions, budgets, savings goals, and FIN preferences from the active database.',
                                  style: HorizonTypography.bodySm.copyWith(
                                    color: tokens.textMedium,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirmation Form Card
                    HorizonSurface(
                      tier: HorizonSurfaceTier.surface2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authentication Required',
                            style: HorizonTypography.bodyMd.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          HorizonTextField(
                            controller: _password,
                            label: 'Current password',
                            hintText: 'Enter your password to verify identity',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: tokens.textMedium,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your current password'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          HorizonTextField(
                            controller: _confirmation,
                            label: 'Type DELETE to confirm',
                            hintText: 'DELETE',
                            prefixIcon: Icons.delete_outline,
                            validator: (value) =>
                                value != 'DELETE' ? 'Type DELETE exactly' : null,
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: tokens.outflow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tokens.outflow.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _error!,
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.outflow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    HorizonButton(
                      text: 'Delete Account Permanently',
                      icon: Icons.delete_forever_outlined,
                      variant: HorizonButtonVariant.destructive,
                      isLoading: _busy,
                      onPressed: _delete,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
