import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

class FinSettingsScreen extends StatelessWidget {
  const FinSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final prefs = provider.companionPreferences;
    return Scaffold(
      appBar: AppBar(title: const Text('FIN Companion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Manage FIN presence. FIN only analyzes financial records you have approved.',
          ),
          SwitchListTile(
            title: const Text('Show FIN across the app'),
            value: prefs.showAcrossApp,
            onChanged: (value) => provider.updateCompanionPreferences(
              prefs.copyWith(showAcrossApp: value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore FIN now'),
            subtitle: const Text('Bring FIN back after dismissal'),
            onTap: provider.restoreFinNow,
          ),
          ListTile(
            title: const Text('Screen edge'),
            trailing: DropdownButton<String>(
              value: prefs.edgePosition,
              items: const [
                DropdownMenuItem(value: 'left', child: Text('Left')),
                DropdownMenuItem(value: 'right', child: Text('Right')),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.updateCompanionPreferences(
                    prefs.copyWith(edgePosition: value),
                  );
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Character animations'),
            subtitle: const Text('System reduced motion is always respected'),
            value: prefs.animationsEnabled,
            onChanged: (value) => provider.updateCompanionPreferences(
              prefs.copyWith(animationsEnabled: value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Reset FIN appearance and visibility'),
            onTap: provider.resetCompanionPreferences,
          ),
        ],
      ),
    );
  }
}
