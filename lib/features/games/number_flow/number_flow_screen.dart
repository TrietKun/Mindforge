import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/result_overlay.dart';
import '../../../shared/widgets/win_burst.dart';

const String _nfDir = 'assets/games/number_flow';

class _Puzzle {
  const _Puzzle({
    required this.terms,
    required this.hiddenIndex,
    required this.answer,
    required this.options,
  });

  final List<int> terms;
  final int hiddenIndex;
  final int answer;
  final List<int> options;
}

class NumberFlowScreen extends StatefulWidget {
  const NumberFlowScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<NumberFlowScreen> createState() => _NumberFlowScreenState();
}

class _NumberFlowScreenState extends State<NumberFlowScreen> {
  static const double _sessionSeconds = 45;
  static const Color _accent = AppPalette.logic;

  final _rng = math.Random();
  Timer? _ticker;
  Timer? _winTimer;
  Timer? _crossTimer;

  double get _penalty => switch (widget.difficulty) {
        Difficulty.easy => 1.5,
        Difficulty.medium => 2.0,
        Difficulty.hard => 2.5,
      };

  /// How many of the 5 pattern families are in play, ramping with progress.
  int _maxTypes(int solved) => switch (widget.difficulty) {
        Difficulty.easy => 3,
        Difficulty.medium => solved < 4 ? 3 : 5,
        Difficulty.hard => 5,
      };

  double _timeLeft = _sessionSeconds;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _solved = 0;
  int _misses = 0;
  bool _finished = false;

  late _Puzzle _puzzle;
  int _puzzleId = 0;
  int? _wrongOption;

  // Feedback FX state (purely visual — never touches scoring/logic).
  int _fxId = 0;
  int _wrongId = 0;
  bool _showWin = false;
  bool _showCross = false;
  int _winValue = 0;
  int _winCombo = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = _generate();
    _start();
  }

  void _start() {
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finish();
        }
      });
    });
  }

  _Puzzle _generate() {
    final terms = _buildSequence(_solved);
    // Hide the last term most of the time, sometimes a middle one.
    final hiddenIndex =
        _rng.nextDouble() < 0.7 ? terms.length - 1 : 1 + _rng.nextInt(terms.length - 2);
    final answer = terms[hiddenIndex];

    final options = <int>{answer};
    while (options.length < 4) {
      final delta = (1 + _rng.nextInt(math.max(2, answer.abs() ~/ 6 + 3)));
      final candidate = answer + (_rng.nextBool() ? delta : -delta);
      if (candidate != answer) options.add(candidate);
    }
    final shuffled = options.toList()..shuffle(_rng);

    return _Puzzle(
      terms: terms,
      hiddenIndex: hiddenIndex,
      answer: answer,
      options: shuffled,
    );
  }

  List<int> _buildSequence(int solved) {
    final type = _rng.nextInt(_maxTypes(solved));
    switch (type) {
      case 0: // arithmetic
        final start = 1 + _rng.nextInt(9);
        final step = 2 + _rng.nextInt(7);
        return List.generate(5, (i) => start + i * step);
      case 1: // geometric
        final start = 1 + _rng.nextInt(4);
        final ratio = 2 + _rng.nextInt(2);
        return List.generate(5, (i) => start * math.pow(ratio, i).toInt());
      case 2: // squares offset
        final offset = _rng.nextInt(4);
        return List.generate(5, (i) => (i + 1 + offset) * (i + 1 + offset));
      case 3: // fibonacci-like
        final a = 1 + _rng.nextInt(4);
        final b = a + _rng.nextInt(4);
        final seq = [a, b];
        for (var i = 2; i < 5; i++) {
          seq.add(seq[i - 1] + seq[i - 2]);
        }
        return seq;
      default: // increasing step (1,3,6,10,15)
        final start = 1 + _rng.nextInt(3);
        var step = 1 + _rng.nextInt(3);
        final seq = [start];
        for (var i = 1; i < 5; i++) {
          seq.add(seq[i - 1] + step);
          step++;
        }
        return seq;
    }
  }

  void _answer(int value) {
    if (_finished) return;
    if (value == _puzzle.answer) {
      HapticFeedback.lightImpact();
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      _solved++;
      final winCombo = _combo;
      setState(() {
        _score += (15 * (1 + _combo ~/ 3) * widget.difficulty.scoreMultiplier)
            .round();
        _wrongOption = null;
        _winValue = value;
        _winCombo = winCombo;
        _showWin = true;
        _fxId++;
        _puzzle = _generate();
        _puzzleId++;
      });
      _winTimer?.cancel();
      _winTimer = Timer(const Duration(milliseconds: 760), () {
        if (mounted) setState(() => _showWin = false);
      });
    } else {
      HapticFeedback.heavyImpact();
      _combo = 0;
      _misses++;
      setState(() {
        _timeLeft = math.max(0, _timeLeft - _penalty);
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

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    HapticFeedback.mediumImpact();
  }

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _timeLeft = _sessionSeconds;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _solved = 0;
      _misses = 0;
      _finished = false;
      _wrongOption = null;
      _showWin = false;
      _showCross = false;
      _puzzle = _generate();
      _puzzleId++;
    });
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _winTimer?.cancel();
    _crossTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_timeLeft / _sessionSeconds).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.logic, AppPalette.focus],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Wrong answers nudge the whole field — a light, decaying shake.
            _Shaker(
              trigger: _wrongId,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          Text('$_score',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: _accent)),
                          const Spacer(),
                          _ComboChip(combo: _combo),
                        ],
                      ),
                      const SizedBox(height: Insets.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppPalette.surfaceHigh,
                          valueColor: AlwaysStoppedAnimation(
                            Color.lerp(AppPalette.danger, _accent, progress)!,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const _FlowHeader(),
                      const SizedBox(height: Insets.md),
                      _SequenceRow(
                        puzzle: _puzzle,
                        roundId: _puzzleId,
                        key: ValueKey(_puzzleId),
                      ),
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
                          for (final option in _puzzle.options)
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
                top: 64,
                right: 6,
                child: IgnorePointer(
                  child: Image.asset('$_nfDir/spark.png', width: 92)
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
                  child: Image.asset('$_nfDir/cross.png', width: 108)
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
            if (_finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: _score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: '$_nfDir/trophy.png',
                icon: Icons.timeline_rounded,
                stats: [
                  ResultStat(L('Giải được', 'Solved'), '$_solved'),
                  ResultStat('Combo', 'x$_bestCombo'),
                  ResultStat(L('Sai', 'Wrong'), '$_misses'),
                ],
                onRetry: _restart,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }

  /// Clean correct-answer celebration centred on the gap (see [WinBurst]).
  Widget _buildWinFx() => WinBurst(
        dir: _nfDir,
        fxId: _fxId,
        combo: _winCombo,
        alignment: const Alignment(0, -0.16),
        reveal: _RevealTile(value: _winValue, fxId: _fxId),
      );
}

/// Faint flowing "stream" ribbon behind the puzzle title — sets the
/// number-flow mood without stealing attention.
class _FlowHeader extends StatelessWidget {
  const _FlowHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.42,
            child: Image.asset('$_nfDir/stream.png', width: 320, fit: BoxFit.contain)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: -14, end: 14, duration: 2800.ms, curve: Curves.easeInOut),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('$_nfDir/puzzle.png', width: 46, height: 46),
              const SizedBox(height: 6),
              Text(
                L('Tìm số còn thiếu', 'Find the missing number'),
                style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 14,
                    letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SequenceRow extends StatelessWidget {
  const _SequenceRow({required this.puzzle, required this.roundId, super.key});
  final _Puzzle puzzle;
  final int roundId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // The connector reads as the "flow" the numbers ride along; a looping
          // shimmer sweeps light across its dots.
          FractionallySizedBox(
            widthFactor: 0.96,
            child: Image.asset('$_nfDir/connector.png', fit: BoxFit.fitWidth)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: 1600.ms,
                    delay: 200.ms,
                    color: const Color(0xFF7DF9FF)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < puzzle.terms.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
                    child: _TermCell(
                      text: i == puzzle.hiddenIndex
                          ? '?'
                          : '${puzzle.terms[i]}',
                      hidden: i == puzzle.hiddenIndex,
                      index: i,
                      roundId: roundId,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermCell extends StatelessWidget {
  const _TermCell({
    required this.text,
    required this.hidden,
    required this.index,
    required this.roundId,
  });
  final String text;
  final bool hidden;
  final int index;
  final int roundId;

  @override
  Widget build(BuildContext context) {
    final Widget inner;
    if (hidden) {
      // The gap pulses and glows so the eye is drawn to what's missing.
      inner = SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Image.asset('$_nfDir/halo.png', width: 96, height: 96)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.25, end: 0.75, duration: 1100.ms),
            Image.asset('$_nfDir/question_tile.png', width: 62, height: 62)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.08, duration: 1100.ms),
          ],
        ),
      );
    } else {
      inner = SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('$_nfDir/num_tile.png', width: 60, height: 60),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    // Each cell flows in with a staggered pop.
    return inner
        .animate(key: ValueKey('c$roundId-$index'))
        .fadeIn(delay: (index * 60).ms, duration: 240.ms)
        .slideX(
            begin: 0.3,
            end: 0,
            delay: (index * 60).ms,
            duration: 300.ms,
            curve: Curves.easeOutBack)
        .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
            delay: (index * 60).ms,
            duration: 300.ms,
            curve: Curves.easeOutBack);
  }
}

class _RevealTile extends StatelessWidget {
  const _RevealTile({required this.value, required this.fxId});
  final int value;
  final int fxId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset('$_nfDir/num_tile.png', width: 72, height: 72),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Image.asset('$_nfDir/check.png', width: 34),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('reveal$fxId'))
        .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 360.ms,
            curve: Curves.easeOutBack)
        .then(delay: 200.ms)
        .fadeOut(duration: 240.ms);
  }
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
              child: Image.asset('$_nfDir/option_pad.png', fit: BoxFit.fill),
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
                fontSize: 24,
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

class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    final active = combo >= 2;
    return AnimatedOpacity(
      opacity: active ? 1 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppPalette.logic, AppPalette.gold])
              : null,
          color: active ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'x$combo',
          style: TextStyle(
            color: active ? Colors.black : AppPalette.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ).animate(target: active ? 1 : 0).scaleXY(begin: 1, end: 1.1, duration: 130.ms);
  }
}

/// Briefly translates [child] with a quick decaying horizontal shake whenever
/// [trigger] changes — used for the "wrong answer" screen nudge.
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
