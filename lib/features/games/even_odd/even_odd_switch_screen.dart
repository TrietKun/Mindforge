import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/session/timed_session.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/quiz_top_bar.dart';
import '../../../shared/widgets/result_overlay.dart';

enum _Rule { even, odd, high, low }

extension on _Rule {
  String get label => switch (this) {
        _Rule.even => L('Chọn số CHẴN', 'Pick the EVEN'),
        _Rule.odd => L('Chọn số LẺ', 'Pick the ODD'),
        _Rule.high => L('Chọn số > 5', 'Pick number > 5'),
        _Rule.low => L('Chọn số < 5', 'Pick number < 5'),
      };
}

class EvenOddSwitchScreen extends StatefulWidget {
  const EvenOddSwitchScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<EvenOddSwitchScreen> createState() => _EvenOddSwitchScreenState();
}

class _EvenOddSwitchScreenState extends State<EvenOddSwitchScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.flexibility;

  final _rng = math.Random();
  late _Rule _rule;
  late int _left;
  late int _right;
  int _roundId = 0;
  int? _wrongSide;
  int _sparkId = 0;
  bool _showSpark = false;

  static const _dir = 'assets/games/even_odd';
  String _ruleBadge(_Rule r) => switch (r) {
        _Rule.even => '$_dir/even.png',
        _Rule.odd => '$_dir/odd.png',
        _Rule.high => '$_dir/arrow_up.png',
        _Rule.low => '$_dir/arrow_down.png',
      };
  bool get _showsFive => _rule == _Rule.high || _rule == _Rule.low;

  @override
  double get sessionSeconds => 32;

  ({double flip, double penalty}) get _tune => switch (widget.difficulty) {
        Difficulty.easy => (flip: 0.35, penalty: 1.0),
        Difficulty.medium => (flip: 0.55, penalty: 1.5),
        Difficulty.hard => (flip: 0.75, penalty: 2.0),
      };

  @override
  void initState() {
    super.initState();
    _rule = _Rule.values[_rng.nextInt(4)];
    _next(first: true);
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _next({bool first = false}) {
    if (!first && _rng.nextDouble() < _tune.flip) {
      _Rule r;
      do {
        r = _Rule.values[_rng.nextInt(4)];
      } while (r == _rule);
      _rule = r;
    }
    // One number < 5, one > 5, with opposite parity → every rule has a unique
    // answer.
    final low = [1, 2, 3, 4][_rng.nextInt(4)];
    final highs = [6, 7, 8, 9].where((h) => h.isEven != low.isEven).toList();
    final high = highs[_rng.nextInt(highs.length)];
    if (_rng.nextBool()) {
      _left = low;
      _right = high;
    } else {
      _left = high;
      _right = low;
    }
    _roundId++;
  }

  bool _satisfies(int n) => switch (_rule) {
        _Rule.even => n.isEven,
        _Rule.odd => n.isOdd,
        _Rule.high => n > 5,
        _Rule.low => n < 5,
      };

  int get _correctSide => _satisfies(_left) ? 0 : 1;

  void _answer(int side) {
    if (finished) return;
    if (side == _correctSide) {
      registerCorrect(
        points: (c) =>
            (10 * (1 + c ~/ 4) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      setState(() {
        _wrongSide = null;
        _showSpark = true;
        _sparkId++;
        _next();
      });
      Future.delayed(const Duration(milliseconds: 520), () {
        if (mounted) setState(() => _showSpark = false);
      });
    } else {
      registerWrong(
        penalty: _tune.penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() => _wrongSide = side);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.flexibility, AppPalette.math],
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  children: [
                    QuizTopBar(
                      score: score,
                      combo: combo,
                      progress: progress,
                      accent: _accent,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Image.asset('$_dir/rules.png', height: 38),
                    const SizedBox(height: Insets.md),
                    Container(
                      key: ValueKey(_rule),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppPalette.flexibility.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(
                            color: AppPalette.flexibility
                                .withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(_ruleBadge(_rule), width: 40, height: 40),
                          if (_showsFive) ...[
                            const SizedBox(width: 4),
                            Image.asset('$_dir/five.png', width: 34, height: 34),
                          ],
                          const SizedBox(width: 10),
                          Text(_rule.label,
                              style: const TextStyle(
                                  color: AppPalette.flexibility,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                        ],
                      ),
                    )
                        .animate(key: ValueKey(_rule))
                        .fadeIn(duration: 180.ms)
                        .scale(
                            begin: const Offset(0.85, 0.85),
                            curve: Curves.easeOutBack)
                        .shake(hz: 4, rotation: 0.01),
                    const SizedBox(height: Insets.xl),
                    Row(
                      key: ValueKey(_roundId),
                      children: [
                        Expanded(
                          child: _Pad(
                            value: _left,
                            isWrong: _wrongSide == 0,
                            onTap: () => _answer(0),
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: _Pad(
                            value: _right,
                            isWrong: _wrongSide == 1,
                            onTap: () => _answer(1),
                          ),
                        ),
                      ],
                    ).animate(key: ValueKey(_roundId)).fadeIn(duration: 160.ms),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            if (_showSpark)
              IgnorePointer(
                child: Center(
                  child: Image.asset('$_dir/sparkle.png', width: 110)
                      .animate(key: ValueKey(_sparkId))
                      .scale(
                          begin: const Offset(0.3, 0.3),
                          curve: Curves.easeOutBack,
                          duration: 260.ms)
                      .then()
                      .fadeOut(delay: 120.ms, duration: 240.ms),
                ),
              ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: '$_dir/trophy.png',
                icon: Icons.swap_vert_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                  ResultStat(L('Chính xác', 'Accuracy'), '$accuracy%'),
                ],
                onRetry: () {
                  setState(() {
                    _rule = _Rule.values[_rng.nextInt(4)];
                    _next(first: true);
                  });
                  startSession();
                },
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({
    required this.value,
    required this.isWrong,
    required this.onTap,
  });
  final int value;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The neon pad frame sprite as the button background.
            Positioned.fill(
              child: Image.asset('assets/games/even_odd/pad.png',
                  fit: BoxFit.fill),
            ),
            Text('$value',
                style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w900)),
            if (isWrong)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: AppPalette.danger, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (isWrong) {
      return base.animate().shake(hz: 4, rotation: 0.02, duration: 320.ms);
    }
    return base;
  }
}
