import 'package:flutter/material.dart';
import '../../../../models/companion_model.dart';

/// Reusable living motion states for FIN.
///
/// Designed to provide subtle, premium character motion and expressions:
/// - [idle]: Gentle breathing, periodic blink, soft body sway.
/// - [listening]: Slight lean, attentive posture, open gaze.
/// - [thinking]: Gentle head tilt, hand to chin, contemplative tempo.
/// - [supportive]: Positive gesture, warm crescent eyes, encouraging pulse.
/// - [alert]: Attentive cue, wide eyes, watchful without harsh red alarm.
/// - [docked]: Compact resting appearance, relaxed crescent eyes, low pulse.
enum FinMotionState {
  idle,
  listening,
  thinking,
  supportive,
  alert,
  docked;

  String get label => switch (this) {
    FinMotionState.idle => 'Idle',
    FinMotionState.listening => 'Listening',
    FinMotionState.thinking => 'Thinking',
    FinMotionState.supportive => 'Supportive',
    FinMotionState.alert => 'Alert',
    FinMotionState.docked => 'Docked',
  };

  String get description => switch (this) {
    FinMotionState.idle => 'Attentive resting presence',
    FinMotionState.listening => 'Observing spending patterns',
    FinMotionState.thinking => 'Analyzing authorized records',
    FinMotionState.supportive => 'Positive pacing encouragement',
    FinMotionState.alert => 'Threshold awareness cue',
    FinMotionState.docked => 'Compact resting appearance',
  };

  IconData get icon => switch (this) {
    FinMotionState.idle => Icons.spa_outlined,
    FinMotionState.listening => Icons.hearing_outlined,
    FinMotionState.thinking => Icons.psychology_outlined,
    FinMotionState.supportive => Icons.volunteer_activism_outlined,
    FinMotionState.alert => Icons.notifications_active_outlined,
    FinMotionState.docked => Icons.nightlight_outlined,
  };

  FinCharacterState toCharacterState() => switch (this) {
    FinMotionState.idle => FinCharacterState.idle,
    FinMotionState.listening => FinCharacterState.listening,
    FinMotionState.thinking => FinCharacterState.thinking,
    FinMotionState.supportive => FinCharacterState.encouraging,
    FinMotionState.alert => FinCharacterState.caution,
    FinMotionState.docked => FinCharacterState.docked,
  };

  static FinMotionState fromCharacterState(FinCharacterState state) =>
      switch (state) {
        FinCharacterState.listening ||
        FinCharacterState.attentive => FinMotionState.listening,
        FinCharacterState.thinking => FinMotionState.thinking,
        FinCharacterState.happy ||
        FinCharacterState.celebrating ||
        FinCharacterState.encouraging => FinMotionState.supportive,
        FinCharacterState.concerned ||
        FinCharacterState.caution ||
        FinCharacterState.error => FinMotionState.alert,
        FinCharacterState.docked => FinMotionState.docked,
        FinCharacterState.idle ||
        FinCharacterState.greeting ||
        FinCharacterState.explaining ||
        FinCharacterState.confused ||
        FinCharacterState.emptyData => FinMotionState.idle,
      };
}
