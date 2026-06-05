import 'dart:async';
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
import '../../../shared/widgets/win_burst.dart';

const String _qmDir = 'assets/games/quick_math';

class _Problem {
  const _Problem(this.a, this.b, this.op, this.answer, this.options);
  final int a;
  final int b;
  final String op;
  final int answer;
  final List<int> options;

  String get opAsset => switch (op) {
        '×' => '$_qmDir/op_times.png',
        '-' => '$_qmDir/op_minus.png',
        '÷' => '$_qmDir/op_divide.png',
        _ => '$_qmDir/op_plus.png',
      };
}

class QuickMathScreen extends StatefulWidget {
  const QuickMathScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<QuickMathScreen> createState() => _QuickMathScreenState();
}

class _QuickMathScreenState extends State<QuickMathScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.math;

  final _rng = math.Random();
  late _Problem _problem;
  int _problemId = 0;
  int? _wrongOption;

  // Visual feedback state (never touches scoring/logic).
  Timer? _winTimer;
  Timer? _crossTimer;
  int _fxId = 0;
  int _wrongId = 0;
  bool _showWin = false;
  bool _showCross = false;
  int _winAnswer = 0;
  int _winCombo = 0;

  @override
  double get sessionSeconds => 45;

  double get _penalty => switch (widget.difficulty) {
        Difficulty.easy => 1.5,
        Difficulty.medium => 2.0,
        Difficulty.hard => 2.5,
      };

  @override
  void initState() {
    super.initState();
    _problem = _generate();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  _Problem _generate() {
    final ops = switch (widget.difficulty) {
      Difficulty.easy => ['+', '-'],
      Difficulty.medium => ['+', '-', '×', '÷'],
      Difficulty.hard => ['+', '-', '×', '÷'],
    };
    final op = ops[_rng.nextInt(ops.length)];

    int a, b, answer;
    switch (op) {
      case '×':
        final range = widget.difficulty == Difficulty.hard ? 12 : 9;
        a = 2 + _rng.nextInt(range);
        b = 2 + _rng.nextInt(range);
        answer = a * b;
      case '÷':
        // Build from the quotient so the answer is always a whole number.
        final range = widget.difficulty == Difficulty.hard ? 12 : 9;
        b = 2 + _rng.nextInt(range);
        final quotient = 2 + _rng.nextInt(range);
        a = b * quotient;
        answer = quotient;
      case '-':
        final max = widget.difficulty == Difficulty.hard ? 99 : 40;
        a = 2 + _rng.nextInt(max);
        b = 1 + _rng.nextInt(a); // keep non-negative
        answer = a - b;
      default: // '+'
        final max = widget.difficulty == Difficulty.hard ? 99 : 40;
        a = 1 + _rng.nextInt(max);
        b = 1 + _rng.nextInt(max);
        answer = a + b;
    }

    final options = <int>{answer};
    final spread = math.max(2, answer.abs() ~/ 5 + 2);
    while (options.length < 4) {
      final delta = 1 + _rng.nextInt(spread);
      final candidate = answer + (_rng.nextBool() ? delta : -delta);
      if (candidate >= 0) options.add(candidate);
    }
    return _Problem(a, b, op, answer, options.toList()..shuffle(_rng));
  }

  void _answer(int value) {
    if (finished) return;
    if (value == _problem.answer) {
      final winAnswer = _problem.answer;
      registerCorrect(
        points: (c) =>
            (15 * (1 + c ~/ 3) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      final winCombo = combo;
      setState(() {
        _wrongOption = null;
        _winAnswer = winAnswer;
        _winCombo = winCombo;
        _showWin = true;
        _fxId++;
        _problem = _generate();
        _problemId++;
      });
      _winTimer?.cancel();
      _winTimer = Timer(const Duration(milliseconds: 760), () {
        if (mounted) setState(() => _showWin = false);
      });
    } else {
      registerWrong(
        penalty: _penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() {
        _wrongOption = value;
        _showCross = true;
        _wrongId++;
      });
      _crossTimer?.cancel();
      _crossTimer = Timer(const Duration(milliseconds: 460), () {
        if (mounted) setState(() => _showCross = false);
      });
    }
  }

  void _restart() {
    setState(() {
      _wrongOption = null;
      _showWin = false;
      _showCross = false;
      _problem = _generate();
      _problemId++;
    });
    startSession();
  }

  @override
  void dispose() {
    _winTimer?.cancel();
    _crossTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.math, AppPalette.focus],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            _Shaker(
              trigger: _wrongId,
              child: SafeArea(
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
                      const _CalculatorHeader(),
                      const SizedBox(height: Insets.md),
                      _EquationCard(problem: _problem, problemId: _problemId),
                      const Spacer(),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: Insets.md,
                        crossAxisSpacing: Insets.md,
                        childAspectRatio: 2.6,
                        clipBehavior: Clip.none,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final option in _problem.options)
                            _OptionButton(
                              value: option,
                              isWrong: _wrongOption == option,
                              onTap: () => _answer(option),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showWin) _buildWinFx(),
            if (_showWin && _winCombo > 0 && _winCombo % 3 == 0)
              Positioned(
                top: 56,
                right: 6,
                child: IgnorePointer(
                  child: Image.asset('$_qmDir/spark.png', width: 92)
                      .animate(key: ValueKey('cspark$_fxId'))
                      .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1, 1),
                          duration: 260.ms,
                          curve: Curves.easeOutBack)
                      .fadeOut(delay: 220.ms, duration: 240.ms),
                ),
              ),
            if (_showCross)
              IgnorePointer(
                child: Center(
                  child: Image.asset('$_qmDir/cross.png', width: 108)
                      .animate(key: ValueKey('x$_wrongId'))
                      .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                          duration: 200.ms,
                          curve: Curves.easeOutBack)
                      .then(delay: 120.ms)
                      .fadeOut(duration: 220.ms),
                ),
              ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: '$_qmDir/trophy.png',
                icon: Icons.calculate_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                  ResultStat(L('Chính xác', 'Accuracy'), '$accuracy%'),
                ],
                onRetry: _restart,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }

  /// Clean correct-answer celebration centred on the equation (see [WinBurst]).
  Widget _buildWinFx() => WinBurst(
        dir: _qmDir,
        fxId: _fxId,
        combo: _winCombo,
        alignment: const Alignment(0, -0.18),
        reveal: _RevealAnswer(value: _winAnswer, fxId: _fxId),
      );
}

/// The smiley calculator with a soft pulsing halo and a gentle hover-bob.
class _CalculatorHeader extends StatelessWidget {
  const _CalculatorHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset('$_qmDir/halo.png', width: 124, height: 124)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.18, end: 0.5, duration: 1600.ms)
              .scaleXY(begin: 0.9, end: 1.12, duration: 1600.ms),
          Image.asset('$_qmDir/calculator.png', width: 58, height: 58)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 2000.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _EquationCard extends StatelessWidget {
  const _EquationCard({required this.problem, required this.problemId});
  final _Problem problem;
  final int problemId;

  @override
  Widget build(BuildContext context) {
    // Each part flows in with a light stagger; the operator pops on a bounce.
    // The animated child carries a per-problem key so flutter_animate plays the
    // entrance once per problem instead of restarting on every 50ms tick.
    Widget part(int i, Widget child) => KeyedSubtree(
          key: ValueKey('p$problemId-$i'),
          child: child,
        )
            .animate(key: ValueKey('pa$problemId-$i'))
            .fadeIn(delay: (i * 50).ms, duration: 200.ms)
            .slideY(
                begin: 0.2,
                end: 0,
                delay: (i * 50).ms,
                duration: 240.ms,
                curve: Curves.easeOut);

    return SizedBox(
      key: ValueKey('card$problemId'),
      height: 128,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset('$_qmDir/eq_frame.png', fit: BoxFit.fill),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  part(0, _EqText('${problem.a}')),
                  part(
                    1,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: KeyedSubtree(
                        key: ValueKey('opk$problemId'),
                        child: Image.asset(problem.opAsset,
                            width: 42, height: 42),
                      )
                          .animate(key: ValueKey('opb$problemId'))
                          .scale(
                              begin: const Offset(0.4, 0.4),
                              end: const Offset(1, 1),
                              duration: 360.ms,
                              curve: Curves.easeOutBack),
                    ),
                  ),
                  part(2, _EqText('${problem.b}')),
                  part(3, const _EqText('  = ?')),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('card$problemId'))
        .fadeIn(duration: 160.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut)
        .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack);
  }
}

class _RevealAnswer extends StatelessWidget {
  const _RevealAnswer({required this.value, required this.fxId});
  final int value;
  final int fxId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('$_qmDir/op_equals.png', width: 30, height: 30),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: AppPalette.math, blurRadius: 18),
              Shadow(color: AppPalette.math, blurRadius: 30),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Image.asset('$_qmDir/check.png', width: 34),
      ],
    )
        .animate(key: ValueKey('reveal$fxId'))
        .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 360.ms,
            curve: Curves.easeOutBack)
        .then(delay: 220.ms)
        .fadeOut(duration: 240.ms);
  }
}

class _EqText extends StatelessWidget {
  const _EqText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppPalette.textPrimary,
          fontSize: 46,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      );
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.value,
    required this.isWrong,
    required this.onTap,
  });
  final int value;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset('$_qmDir/option_pad.png', fit: BoxFit.fill),
            ),
            if (widget.isWrong)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    color: AppPalette.danger.withValues(alpha: 0.22),
                  ),
                ),
              ),
            Text(
              '${widget.value}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.isWrong) {
      return base.animate().shake(hz: 4, rotation: 0.02, duration: 320.ms);
    }
    return base;
  }
}

/// Quick decaying horizontal shake on [trigger] change — the wrong-answer nudge.
class _Shaker extends StatefulWidget {
  const _Shaker({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<_Shaker> createState() => _ShakerState();
}

class _ShakerState extends State<_Shaker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(covariant _Shaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 6) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
