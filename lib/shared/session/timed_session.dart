import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable timed-session logic shared by the quiz-style games (score, combo,
/// countdown, flash feedback). Hosts implement [sessionSeconds] and call
/// [registerCorrect] / [registerWrong] from their answer handlers.
mixin TimedSessionMixin<T extends StatefulWidget> on State<T> {
  double get sessionSeconds;

  double timeLeft = 0;
  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int hits = 0;
  int misses = 0;
  bool finished = false;
  Color? flash;

  Timer? _ticker;

  double get progress => (timeLeft / sessionSeconds).clamp(0.0, 1.0);

  int get accuracy {
    final total = hits + misses;
    return total == 0 ? 100 : ((hits / total) * 100).round();
  }

  /// Override to react to the countdown reaching zero.
  void onSessionFinished() {}

  void startSession() {
    timeLeft = sessionSeconds;
    score = 0;
    combo = 0;
    bestCombo = 0;
    hits = 0;
    misses = 0;
    finished = false;
    flash = null;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        timeLeft -= 0.05;
        if (timeLeft <= 0) {
          timeLeft = 0;
          _finish();
        }
      });
    });
  }

  void registerCorrect({
    required int Function(int combo) points,
    Color? flashColor,
  }) {
    if (finished) return;
    combo++;
    bestCombo = math.max(bestCombo, combo);
    hits++;
    HapticFeedback.lightImpact();
    setState(() {
      score += points(combo);
      flash = flashColor;
    });
    _clearFlash();
  }

  void registerWrong({double penalty = 0, Color? flashColor}) {
    if (finished) return;
    combo = 0;
    misses++;
    HapticFeedback.heavyImpact();
    setState(() {
      timeLeft = math.max(0, timeLeft - penalty);
      flash = flashColor;
    });
    _clearFlash();
  }

  void _clearFlash() {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => flash = null);
    });
  }

  void _finish() {
    if (finished) return;
    finished = true;
    _ticker?.cancel();
    HapticFeedback.mediumImpact();
    onSessionFinished();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
