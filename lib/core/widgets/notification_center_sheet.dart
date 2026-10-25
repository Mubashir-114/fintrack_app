import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../horizon/horizon.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sms_provider.dart';

/// In-app update center for the shell header.
///
/// Every entry is backed by real provider data (budget alerts, staged SMS
/// candidates, FIN insights) — nothing is fabricated. When there is nothing to
/// report the sheet says so instead of showing an empty scroll view.
class NotificationCenterSheet extends StatefulWidget {
  const NotificationCenterSheet({super.key, this.onNavigate});

  /// Called with the destination route after the sheet closes.
  final ValueChanged<String>? onNavigate;

  /// Number of actionable updates for the header badge. `0` hides the badge.
  static int pendingCount(BuildContext context) {
    final alerts = context.read<BudgetProvider?>()?.alerts;
    final smsCount =
        context.read<SmsProvider?>()?.detectedTransactions.length ?? 0;
    return (alerts?.totalAlertsCount ?? 0) + smsCount;
  }

  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onNavigate,
  }) {
    final tokens = HorizonThemeTokens.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          SafeArea(child: NotificationCenterSheet(onNavigate: onNavigate)),
    );
  }

  @override
  State<NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final budget = context.read<BudgetProvider?>();
      if (budget != null && budget.alerts == null) budget.loadBudgetAlerts();
    });
  }

  void _open(String route) {
    Navigator.of(context).pop();
    final navigate = widget.onNavigate;
    if (navigate == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => navigate(route));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    final alerts = context.watch<BudgetProvider?>()?.alerts;
    final smsCount =
        context.watch<SmsProvider?>()?.detectedTransactions.length ?? 0;
    final insights = context.watch<DashboardProvider?>()?.insights ?? [];

    final exceeded = alerts?.exceeded ?? const [];
    final approaching = alerts?.approachingLimit ?? [];

    final rows = <_UpdateEntry>[
      for (final alert in exceeded)
        _UpdateEntry(
          icon: Icons.error_outline_rounded,
          accent: tokens.outflow,
          title: 'Budget exceeded',
          message: alert.message,
          route: '/budgets',
        ),
      for (final alert in approaching)
        _UpdateEntry(
          icon: Icons.trending_up_rounded,
          accent: tokens.luminousGold,
          title: 'Approaching limit',
          message: alert.message,
          route: '/budgets',
        ),
      if (smsCount > 0)
        _UpdateEntry(
          icon: Icons.sms_outlined,
          accent: tokens.ionCyan,
          title: '$smsCount SMS candidates to review',
          message: 'Excluded from balances until you confirm them.',
          route: '/sms-import',
        ),
      if (insights.isNotEmpty)
        _UpdateEntry(
          icon: Icons.auto_awesome_outlined,
          accent: tokens.electricIndigo,
          title: 'FIN insight',
          message: insights.first.message,
          route: '/analytics',
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.rimNeutral,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updates',
                      style: HorizonTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rows.isEmpty
                          ? 'Nothing needs your attention'
                          : '${rows.length} ${rows.length == 1 ? 'item' : 'items'} need a look',
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              HorizonIconButton(
                icon: Icons.close_rounded,
                semanticLabel: 'Close updates',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
            child: HorizonEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'You are all caught up',
              description:
                  'Budget warnings, pending imports and FIN insights will appear here as soon as they happen.',
              accentColor: tokens.surplus,
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _UpdateRow(entry: row, onTap: () => _open(row.route));
              },
            ),
          ),
      ],
    );
  }
}

class _UpdateEntry {
  const _UpdateEntry({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.route,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String route;
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.entry, required this.onTap});

  final _UpdateEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: 0.12),
                  borderRadius: HorizonDimensions.borderDefault,
                ),
                alignment: Alignment.center,
                child: Icon(entry.icon, size: 17, color: entry.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: HorizonTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textHigh,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.message,
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textMedium,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: tokens.textLow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
