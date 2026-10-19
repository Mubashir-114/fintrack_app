import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
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
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !_form.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete your account?'),
        content: const Text(
          'This removes your profile and financial records from the active database. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
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
        const SnackBar(
          content: Text('Account deleted from the active database.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Delete account & data')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Deleting your account removes your profile, accounts, transactions, budgets, savings goals, imported SMS review records and FIN preferences from the active database. Your bank accounts and phone messages are unaffected.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Other devices may retain cached copies until signed out. Exported reports remain wherever you saved them. Backup expiry and any legally required retention must be confirmed by the operator; this action does not certify erasure of backups.',
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _password,
                    label: 'Current password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmation,
                    label: 'Type DELETE to confirm',
                    prefixIcon: Icons.delete_outline,
                    validator: (value) =>
                        value != 'DELETE' ? 'Type DELETE exactly' : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(liveRegion: true, child: Text(_error!)),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Delete account permanently',
                    isLoading: _busy,
                    onPressed: _delete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
