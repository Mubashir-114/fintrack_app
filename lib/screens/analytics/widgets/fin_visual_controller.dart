import 'package:flutter/material.dart';

import '../../../models/companion_model.dart';

/// FinTrack 2.0 - Phase 5F Centralized FIN Visual-State Controller
///
/// Coordinates FIN's living companion expressions and 2.5D visual states
/// based on genuine UI and assistant lifecycle events.
///
/// Covered behavioral states:
/// - [FinCharacterState.idle]: Restrained upper-body breathing, planted feet
/// - [FinCharacterState.greeting]: Joyful welcoming posture with arm wave
/// - [FinCharacterState.attentive]: Focused leaning posture when composer is active
/// - [FinCharacterState.thinking]: Upward inquisitive gaze while query is processing
/// - [FinCharacterState.explaining]: Communicative open gesture presenting numbers
/// - [FinCharacterState.encouraging]: Confirmed progress and savings gestures
/// - [FinCharacterState.caution]: Protective caring posture when limits/anomalies found
/// - [FinCharacterState.emptyData]: Inquisitive searching posture when records are sparse
/// - [FinCharacterState.error]: Empathetic calming posture on connection or input failure
class FinVisualController extends ChangeNotifier {
  FinCharacterState _state;
  bool _animationsEnabled;
  String? _speechBubbleText;
  bool _isDisposed = false;
  bool _isPeekExpanded = false;
  bool _isFloatingDismissed = false;
  bool get isFloatingDismissed => _isFloatingDismissed;

  void dismissFloating() {
    if (_isDisposed) return;
    _isFloatingDismissed = true;
    _isPeekExpanded = false;
    notifyListeners();
  }

  void resetPresence() {
    if (_isDisposed) return;
    _isFloatingDismissed = false;
    _isPeekExpanded = false;
    _speechBubbleText = null;
    _state = FinCharacterState.idle;
    notifyListeners();
  }

  FinVisualController({
    FinCharacterState initialState = FinCharacterState.idle,
    this._animationsEnabled = true,
    this._speechBubbleText,
  }) : _state = initialState;

  FinCharacterState get state => _state;
  bool get animationsEnabled => _animationsEnabled;
  String? get speechBubbleText => _speechBubbleText;
  bool get isPeekExpanded => _isPeekExpanded;
  bool get isFullCompanionOpen => _isFullCompanionOpen;
  bool _isFullCompanionOpen = false;

  /// Update peeking panel expansion.
  void setPeekExpanded(bool expanded) {
    if (_isPeekExpanded == expanded || _isDisposed) return;
    _isPeekExpanded = expanded;
    notifyListeners();
  }

  /// Mark whether the full companion conversation screen is open.
  void setFullCompanionOpen(bool isOpen) {
    if (_isFullCompanionOpen == isOpen || _isDisposed) return;
    _isFullCompanionOpen = isOpen;
    notifyListeners();
  }

  /// Toggle peeking panel expansion.
  void togglePeekExpanded() {
    setPeekExpanded(!_isPeekExpanded);
  }

  /// Update speech bubble text.
  void setSpeechBubbleText(String? text) {
    if (_speechBubbleText == text || _isDisposed) return;
    _speechBubbleText = text;
    notifyListeners();
  }

  /// Clears any active speech bubble text.
  void clearSpeechBubble() {
    setSpeechBubbleText(null);
  }

  /// Update the current character visual state.
  void setState(FinCharacterState newState) {
    if (_state == newState || _isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  /// Update animation enablement (e.g. from user preferences or reduced motion).
  void setAnimationsEnabled(bool enabled) {
    if (_animationsEnabled == enabled || _isDisposed) return;
    _animationsEnabled = enabled;
    notifyListeners();
  }

  // ── Genuine UI / Assistant Lifecycle Triggers ─────────────────────────────

  /// Triggered on initial entry or greeting event.
  void onGreeting([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.greeting);
  }

  /// Triggered when the user focuses the text composer or starts typing.
  void onComposerFocused() {
    if (_state != FinCharacterState.thinking) {
      setState(FinCharacterState.attentive);
    }
  }

  /// Triggered when composer loses focus and no active work is pending.
  void onComposerUnfocused() {
    if (_state == FinCharacterState.attentive) {
      setState(FinCharacterState.idle);
    }
  }

  /// Triggered immediately upon query submission (genuine query in flight).
  void onQuerySubmitted([String? query]) =>
      setState(FinCharacterState.thinking);

  /// Triggered when financial results or breakdowns are delivered.
  void onExplaining([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.explaining);
  }

  /// Triggered when a goal is reached, saved, or savings win is confirmed.
  void onEncouraging([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.encouraging);
  }

  /// Triggered when a budget warning, overrun, or unusual spike is detected.
  void onCaution([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.caution);
  }

  /// Triggered when the user has no transactions or empty history for a query.
  void onEmptyData([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.emptyData);
  }

  /// Triggered on network failure, rate limit, or unexpected error.
  void onError([String? speech]) {
    _speechBubbleText = speech;
    setState(FinCharacterState.error);
  }

  /// Triggered on navigation between major app screens.
  void onNavigation(String route) {
    if (_isDisposed) return;
    setPeekExpanded(false);
    if (_state != FinCharacterState.thinking) onIdle();
  }

  /// Triggered after a transaction is successfully recorded.
  void onTransactionSaved([String? speech]) {
    if (_isDisposed) return;
    _speechBubbleText = speech ?? 'Transaction recorded!';
    setState(FinCharacterState.encouraging);
  }

  /// Triggered when a budget warning or overspending limit is detected.
  void onBudgetAlert({bool isExceeded = false, String? speech}) {
    if (_isDisposed) return;
    _speechBubbleText = speech;
    setState(FinCharacterState.caution);
  }

  /// Restores default relaxed companion presence.
  void onIdle() {
    _speechBubbleText = null;
    setState(FinCharacterState.idle);
  }

  /// Map assistant query response or state string into appropriate visual state.
  void mapAssistantResult({
    required bool isRefusal,
    required bool hasError,
    String? backendState,
    bool hasBudgetExceeded = false,
    bool hasUnusualSpike = false,
    bool hasGoalWin = false,
    bool isHistoryEmpty = false,
  }) {
    if (hasError) {
      onError();
    } else if (hasGoalWin) {
      onEncouraging();
    } else if (hasBudgetExceeded || hasUnusualSpike) {
      onCaution();
    } else if (isHistoryEmpty) {
      onEmptyData();
    } else if (isRefusal) {
      onEmptyData();
    } else if (backendState != null && backendState.isNotEmpty) {
      setState(FinCharacterState.fromString(backendState));
    } else {
      onExplaining();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
