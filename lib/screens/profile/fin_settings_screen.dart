import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../models/companion_model.dart';
import '../../providers/analytics_provider.dart';
import '../analytics/widgets/fin_character.dart';

class FinSettingsScreen extends StatefulWidget {
  const FinSettingsScreen({super.key});

  @override
  State<FinSettingsScreen> createState() => _FinSettingsScreenState();
}

class _FinSettingsScreenState extends State<FinSettingsScreen> {
  final List<String> _quotes = [
    "I'm here to help you spot spending patterns and keep budgets on track!",
    "Tip: Review your envelopes during the month to track spending.",
    "FIN analyzes your authorized saved records on the FinTrack backend.",
    "Need a customized category alert? Just adjust your envelope thresholds.",
  ];

  int _quoteIndex = 0;
  bool _showOnHome = true;
  bool _showOnBudgets = true;
  bool _isDeactivated = false;
  String _placement = 'Right Edge'; // 'Right Edge', 'Left Edge', 'Dock Trigger'
  String _frequency = 'standard'; // 'standard', 'minimal'

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AnalyticsProvider>().companionPreferences;
    _showOnHome = prefs.showAcrossApp;
    _showOnBudgets = prefs.showAcrossApp;
    _placement = prefs.edgePosition.toLowerCase() == 'left' ? 'Left Edge' : 'Right Edge';
    _frequency = prefs.proactiveHints ? 'standard' : 'minimal';
  }

  void _cycleQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final provider = context.watch<AnalyticsProvider>();
    final prefs = provider.companionPreferences;

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textHigh),
          onPressed: () => Navigator.of(context).maybePop(),
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
              'FIN COMPANION SETTINGS',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: tokens.ionCyan,
              child: Icon(Icons.person, size: 18, color: tokens.canvas),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HorizonDimensions.marginMobile,
          HorizonDimensions.spaceSM,
          HorizonDimensions.marginMobile,
          HorizonDimensions.dockClearance + 32,
        ),
        children: [
          // ── 1. Interactive Character Showcase Card ───────────────────────
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Atmospheric ambient glow
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.ionCyan.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -10,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.luminousGold.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      // Companion Type Badge (overflow proof)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tokens.rimNeutral),
                        ),
                        child: Row(
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
                            Flexible(
                              child: Text(
                                'FIN COMPANION · FINANCIAL GUIDE',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.ionCyan,
                                  letterSpacing: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Speech Bubble with pointing beak
                      GestureDetector(
                        onTap: _cycleQuote,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: tokens.surface3,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tokens.rimNeutral),
                              ),
                              child: Text(
                                '"${_quotes[_quoteIndex]}"',
                                textAlign: TextAlign.center,
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full-Body 2.5D FIN Companion Illustration / Rig
                      GestureDetector(
                        onTap: _cycleQuote,
                        child: Column(
                          children: [
                            FinCharacter(
                              size: 140,
                              state: FinCharacterState.idle,
                              animationsEnabled: prefs.animationsEnabled,
                              animationActive: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Telemetry Status Line
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user, color: tokens.ionCyan, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'AUTHORIZED SAVED RECORDS',
                                  style: HorizonTypography.labelCaps.copyWith(
                                    color: tokens.ionCyan,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'v2.4 Telemetry',
                              style: HorizonTypography.tabularAmountSm.copyWith(
                                color: tokens.textMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceLG),

          // ── 2. Visibility Controls ───────────────────────────────────────
          Text(
            'VISIBILITY & PRESENCE',
            style: HorizonTypography.labelCaps.copyWith(
              color: tokens.textMedium,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          HorizonSurface(
            tier: HorizonSurfaceTier.surface2,
            padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
            child: Column(
              children: [
                // Toggle 1: Home Dashboard
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.surface3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.dashboard_outlined, color: tokens.ionCyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show FIN on Home Dashboard',
                            style: HorizonTypography.bodyMd.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Real-time daily telemetry and balance summaries',
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showOnHome,
                      activeThumbColor: tokens.ionCyan,
                      onChanged: (val) => setState(() => _showOnHome = val),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: tokens.rimNeutral),
                ),

                // Toggle 2: Budgets & Envelopes
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.surface3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.mail_outline, color: tokens.electricIndigo, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show FIN in Budgets & Envelopes',
                            style: HorizonTypography.bodyMd.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Category pacing and rollover advice',
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showOnBudgets,
                      activeThumbColor: tokens.ionCyan,
                      onChanged: (val) => setState(() => _showOnBudgets = val),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: tokens.rimNeutral),
                ),

                // Module: Hide FIN Completely
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surface1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.visibility_off_outlined, color: tokens.outflow, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Hide FIN Completely',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HorizonTypography.bodyMd.copyWith(
                                      color: tokens.textHigh,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.surface3,
                              foregroundColor: _isDeactivated ? tokens.ionCyan : tokens.outflow,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: _isDeactivated ? tokens.ionCyan : tokens.outflow.withValues(alpha: 0.4)),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isDeactivated = !_isDeactivated;
                                if (_isDeactivated) {
                                  _showOnHome = false;
                                  _showOnBudgets = false;
                                  provider.visualController.dismissFloating();
                                } else {
                                  _showOnHome = true;
                                  _showOnBudgets = true;
                                  provider.restoreFinNow();
                                }
                              });
                            },
                            child: Text(
                              _isDeactivated ? 'RESTORE' : 'DEACTIVATE',
                              style: HorizonTypography.labelCaps.copyWith(
                                color: _isDeactivated ? tokens.ionCyan : tokens.outflow,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deactivates all interactive FIN widgets. You can restore FIN at any time from this screen.',
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceLG),

          // ── 3. Layout & Calibration ──────────────────────────────────────
          Text(
            'LAYOUT & CALIBRATION',
            style: HorizonTypography.labelCaps.copyWith(
              color: tokens.textMedium,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          HorizonSurface(
            tier: HorizonSurfaceTier.surface2,
            padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Placement Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Screen Placement',
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _placement.toUpperCase(),
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.ionCyan,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3 Segmented buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      for (final mode in ['Right Edge', 'Left Edge', 'Dock Trigger'])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _placement = mode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _placement == mode ? tokens.surface3 : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: _placement == mode ? Border.all(color: tokens.rimCyan) : null,
                              ),
                              child: Text(
                                mode,
                                textAlign: TextAlign.center,
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: _placement == mode ? tokens.ionCyan : tokens.textMedium,
                                  fontWeight: _placement == mode ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Reset position button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repositioned accidentally?',
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textHigh,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Return avatar to standard anchor point',
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textHigh,
                        side: BorderSide(color: tokens.rimNeutral),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        provider.restoreFinNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Position reset to standard anchor', style: HorizonTypography.bodySm),
                            backgroundColor: tokens.surface3,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.restart_alt, size: 16, color: tokens.textHigh),
                      label: Text(
                        'RESET POSITION',
                        style: HorizonTypography.labelCaps.copyWith(color: tokens.textHigh),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: tokens.rimNeutral),
                ),

                // Contextual Guidance Frequency
                Text(
                  'Contextual Guidance Frequency',
                  style: HorizonTypography.bodyMd.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Option 1: Helpful Insights
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _frequency = 'standard'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _frequency == 'standard' ? tokens.ionCyan : tokens.rimNeutral,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Helpful Insights',
                                    style: HorizonTypography.bodyMd.copyWith(
                                      color: tokens.textHigh,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _frequency == 'standard' ? tokens.ionCyan : tokens.surface3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active suggestions on recurring spends and envelopes.',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Option 2: Minimal
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _frequency = 'minimal'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _frequency == 'minimal' ? tokens.ionCyan : tokens.rimNeutral,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Minimal',
                                    style: HorizonTypography.bodyMd.copyWith(
                                      color: tokens.textHigh,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _frequency == 'minimal' ? tokens.ionCyan : tokens.surface3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alerts only during critical threshold overruns.',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceLG),

          // ── 4. Zero-Cloud Data Boundary Card ─────────────────────────────
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.luminousGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.security, size: 16, color: tokens.luminousGold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FIN DATA BOUNDARIES',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.luminousGold,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'FIN analyzes your authorized saved records on the FinTrack backend. Outbound guards block financial data from external model providers. FIN cannot connect to your bank or independently read your SMS inbox.',
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: tokens.ionCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DETERMINISTIC BACKEND ANALYSIS',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.textMedium,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceLG),

          // ── 5. Save Preferences Action Button ────────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.ionCyan,
                foregroundColor: tokens.canvas,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final newPosition = _placement == 'Left Edge' ? 'left' : 'right';
                final updated = prefs.copyWith(
                  showAcrossApp: !_isDeactivated && (_showOnHome || _showOnBudgets),
                  edgePosition: newPosition,
                  proactiveHints: _frequency == 'standard',
                );
                provider.updateCompanionPreferences(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.task_alt, color: tokens.ionCyan, size: 18),
                        const SizedBox(width: 8),
                        Text('Preferences Synchronized', style: HorizonTypography.bodySm),
                      ],
                    ),
                    backgroundColor: tokens.surface3,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.tune, size: 20, color: tokens.canvas),
              label: Text(
                'SAVE PREFERENCES',
                style: HorizonTypography.headlineSm.copyWith(
                  color: tokens.canvas,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
