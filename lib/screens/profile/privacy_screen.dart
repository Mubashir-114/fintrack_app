import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Technical notice, deliberately separate from unapproved legal policy drafts.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & data controls')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How FinTrack handles your data',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your name, email and password hash support your account. Financial records you enter or approve are stored by the FinTrack backend in MySQL to provide tracking, budgets, reports and planning. Financial response caches use platform secure storage on native devices. Web financial caches stay in memory only. Cached responses expire after 24 hours; signing out clears app-managed caches. Older plaintext response caches are removed when the updated app starts.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'FIN uses authorized records already stored in FinTrack. Financial records and your questions are blocked from external model providers. Optional external wording services can receive only fixed, context-free phrases. FIN cannot access your bank or independently read your SMS inbox.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'SMS import is optional and available on Android. A scan reads messages on your device and sends detected financial-message information to the backend for review. Nothing is added to your ledger until approved. You can decline scanning and continue using manual entry. Revoke SMS access in device settings at any time; revoking access does not delete previous imports.',
                ),
                const SizedBox(height: 12),
                if (!kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS))
                  OutlinedButton(
                    onPressed: () async {
                      var opened = false;
                      try {
                        opened = await openAppSettings();
                      } catch (_) {
                        /* Show platform-independent recovery below. */
                      }
                      if (!context.mounted || opened) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Open your device settings and select FinTrack permissions.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Open device permission settings'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'No advertising, marketing subscription or analytics tracking SDK was identified in this build. Hosting and database operators process data to deliver the service. Exported reports are saved at your request. Access tokens use platform secure storage; web storage has different security properties from native storage.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete your account through Profile → Delete account & data. Account deletion requires your password and backend confirmation. Backup schedules, operator identity, privacy contact, grievance process, age policy and distribution regions still require owner review. Legal policies are being reviewed; this technical notice is not a finalized Privacy Policy or Terms of Service.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
