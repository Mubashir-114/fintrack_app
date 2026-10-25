import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../providers/analytics_provider.dart';
import 'widgets/fin/fin_companion_widgets.dart';

/// FinTrack HORIZON — Redesigned FIN Companion Settings Screen.
///
/// Presents FIN as a living, moving, integrated companion with:
/// - A dedicated living character stage with ambient glow and live motion preview
/// - Clear operational presence badges and interactive guidance thoughts
/// - Tactile presence and edge placement controls
/// - Responsive guidance frequency selector
/// - Trustworthy, structured data boundary & privacy panel
/// - Tactile save preferences action bar
class FinSettingsScreen extends StatefulWidget {
  const FinSettingsScreen({super.key});

  @override
  State<FinSettingsScreen> createState() => _FinSettingsScreenState();
}

class _FinSettingsScreenState extends State<FinSettingsScreen> {
  final List<String> _quotes = [
    "I'm here to help you spot spending patterns and keep envelopes on track!",
    "Tip: Review your envelope limits mid-month to stay ahead of pace.",
    "FIN analyzes only your authorized saved records on the FinTrack backend.",
    "Need a custom alert? Just adjust your threshold settings anytime.",
  ];

  int _quoteIndex = 0;
  bool _showOnHome = true;
  bool _showOnBudgets = true;
  bool _isDeactivated = false;
  String _placement = 'Right Edge'; // 'Right Edge', 'Left Edge', 'Dock Trigger'
  String _frequency = 'standard'; // 'standard', 'minimal'
  FinMotionState _currentMotion = FinMotionState.idle;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AnalyticsProvider>().companionPreferences;
    _showOnHome = prefs.showAcrossApp;
    _showOnBudgets = prefs.showAcrossApp;
    _isDeactivated = !prefs.showAcrossApp;
    _placement = prefs.edgePosition.toLowerCase() == 'left'
        ? 'Left Edge'
        : 'Right Edge';
    _frequency = prefs.proactiveHints ? 'standard' : 'minimal';
  }

  void _cycleQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  void _handleResetPosition(
    AnalyticsProvider provider,
    HorizonThemeTokens tokens,
  ) {
    provider.restoreFinNow();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Position reset to standard anchor',
          style: HorizonTypography.bodySm.copyWith(color: tokens.textHigh),
        ),
        backgroundColor: tokens.surface3,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _savePreferences(AnalyticsProvider provider, HorizonThemeTokens tokens) {
    final prefs = provider.companionPreferences;
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
            Text(
              'Preferences Synchronized',
              style: HorizonTypography.bodySm.copyWith(color: tokens.textHigh),
            ),
          ],
        ),
        backgroundColor: tokens.surface3,
        duration: const Duration(seconds: 2),
      ),
    );
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
              'FINTRACK HORIZON',
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.ionCyan,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              'Companion Settings',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                fontSize: 18,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          final double horizontalPadding = isTablet
              ? (constraints.maxWidth - 680) / 2
              : HorizonDimensions.marginMobile;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              HorizonDimensions.spaceSM,
              horizontalPadding,
              HorizonDimensions.dockClearance + 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. FIN Companion Hero (Living Preview Stage) ────────────────
                FinCompanionHero(
                  currentMotion: _isDeactivated
                      ? FinMotionState.docked
                      : _currentMotion,
                  onMotionChanged: (motion) =>
                      setState(() => _currentMotion = motion),
                  isActive: !_isDeactivated,
                  isDocked:
                      _placement == 'Dock Trigger' ||
                      _currentMotion == FinMotionState.docked,
                  placement: _placement,
                  currentQuote: _quotes[_quoteIndex],
                  quoteIndex: _quoteIndex,
                  totalQuotes: _quotes.length,
                  onCycleQuote: _cycleQuote,
                  animationsEnabled: prefs.animationsEnabled,
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── 2. Presence & Visibility ────────────────────────────────────
                _buildSectionHeader(tokens, 'PRESENCE & VISIBILITY'),
                const SizedBox(height: 8),
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
                  child: Column(
                    children: [
                      FinPresenceToggleRow(
                        icon: Icons.dashboard_outlined,
                        iconColor: tokens.ionCyan,
                        title: 'Show FIN on Home Dashboard',
                        subtitle:
                            'Daily balance highlights and proactive spending pacing',
                        value: _showOnHome,
                        onChanged: _isDeactivated
                            ? null
                            : (val) => setState(() => _showOnHome = val),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: tokens.rimNeutral),
                      ),
                      FinPresenceToggleRow(
                        icon: Icons.mail_outline,
                        iconColor: tokens.electricIndigo,
                        title: 'Show FIN in Budgets & Envelopes',
                        subtitle:
                            'Envelope pacing, category limits, and rollover advice',
                        value: _showOnBudgets,
                        onChanged: _isDeactivated
                            ? null
                            : (val) => setState(() => _showOnBudgets = val),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: tokens.rimNeutral),
                      ),
                      FinDeactivateCard(
                        isDeactivated: _isDeactivated,
                        onToggle: () {
                          setState(() {
                            _isDeactivated = !_isDeactivated;
                            if (_isDeactivated) {
                              _showOnHome = false;
                              _showOnBudgets = false;
                              _currentMotion = FinMotionState.docked;
                              provider.visualController.dismissFloating();
                            } else {
                              _showOnHome = true;
                              _showOnBudgets = true;
                              _currentMotion = FinMotionState.idle;
                              provider.restoreFinNow();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── 3. Placement & Screen Docking ───────────────────────────────
                _buildSectionHeader(tokens, 'PLACEMENT & DOCKING'),
                const SizedBox(height: 8),
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
                  child: FinPlacementSelector(
                    placement: _placement,
                    onPlacementChanged: (mode) =>
                        setState(() => _placement = mode),
                    onResetPosition: () =>
                        _handleResetPosition(provider, tokens),
                  ),
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── 4. Guidance Frequency ───────────────────────────────────────
                _buildSectionHeader(tokens, 'GUIDANCE FREQUENCY'),
                const SizedBox(height: 8),
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
                  child: FinGuidanceStyleCard(
                    frequency: _frequency,
                    onFrequencyChanged: (freq) =>
                        setState(() => _frequency = freq),
                  ),
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── 5. Data Boundaries & Privacy Panel ─────────────────────────
                FinDataBoundaryPanel(),
                const SizedBox(height: HorizonDimensions.spaceLG + 4),

                // ── 6. Save Preferences Action Bar ──────────────────────────────
                FinSavePreferencesBar(
                  onSave: () => _savePreferences(provider, tokens),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(HorizonThemeTokens tokens, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: HorizonTypography.labelCaps.copyWith(
          color: tokens.textMedium,
          letterSpacing: 1.2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
