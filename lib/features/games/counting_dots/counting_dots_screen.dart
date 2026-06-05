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

const String _cdDir = 'assets/games/counting_dots';
const List<String> _noiseDots = [
  '$_cdDir/dot_pink.png',
  '$_cdDir/dot_amber.png',
  '$_cdDir/dot_purple.png',
  '$_cdDir/dot_green.png',
  '$_cdDir/dot_orange.png',
];

class _Dot {
  const _Dot(this.position, this.asset, this.bobMs, this.rot);
  final Offset position; // normalized within the board, 0..1
  final String asset;
  final int bobMs; // idle bob period
  final double rot; // idle rotation amplitude (radians)
}

class CountingDotsScreen extends StatefulWidget {
  const CountingDotsScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<CountingDotsScreen> createState() => _CountingDotsScreenState();
}

class _CountingDotsScreenState extends State<CountingDotsScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.math;

  final _rng = math.Random();
  List<_Dot> _dots = [];
  List<int> _options = [];
  int _answer = 0;
  int _roundId = 0;
  int? _wrongIndex;

  // Visual feedback state (never touches scoring/logic).
  Timer? _winTimer;
  int _fxId = 0;
  int _wrongId = 0;
  bool _showWin = false;
  int _winCombo = 0;
  int _winAnswer = 0;

  @override
  double get sessionSeconds => 35;

  // On hard the board mixes colors and only blue dots count — the rest distract.
  bool get _colorMode => widget.difficulty == Difficulty.hard;

  ({int lo, int hi, double penalty}) get _tune => switch (widget.difficulty) {
        Difficulty.easy => (lo: 3, hi: 7, penalty: 1.0),
        Difficulty.medium => (lo: 4, hi: 12, penalty: 1.5),
        Difficulty.hard => (lo: 6, hi: 16, penalty: 2.0),
      };

  @override
  void initState() {
    super.initState();
    _newRound();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  @override
  void dispose() {
    _winTimer?.cancel();
    super.dispose();
  }

  void _newRound() {
    final tune = _tune;
    final target = tune.lo + _rng.nextInt(tune.hi - tune.lo + 1);
    final noiseCount = _colorMode ? 2 + _rng.nextInt(5) : 0;
    final positions = _scatter(target + noiseCount);

    final dots = <_Dot>[];
    for (var i = 0; i < target; i++) {
      dots.add(_Dot(positions[i], '$_cdDir/dot.png', _bobMs(), _rotAmp()));
    }
    for (var i = 0; i < noiseCount; i++) {
      dots.add(_Dot(positions[target + i],
          _noiseDots[_rng.nextInt(_noiseDots.length)], _bobMs(), _rotAmp()));
    }
    dots.shuffle(_rng);

    final options = <int>{target};
    while (options.length < 4) {
      final candidate =
          target + (_rng.nextBool() ? 1 : -1) * (1 + _rng.nextInt(3));
      if (candidate >= 1) options.add(candidate);
    }

    _dots = dots;
    _answer = target;
    _options = options.toList()..shuffle(_rng);
    _wrongIndex = null;
    _roundId++;
  }

  int _bobMs() => 1600 + _rng.nextInt(600);
  double _rotAmp() => 0.02 + _rng.nextDouble() * 0.04;

  /// Non-overlapping normalized positions via rejection sampling.
  List<Offset> _scatter(int count) {
    final points = <Offset>[];
    var attempts = 0;
    while (points.length < count && attempts < count * 200) {
      attempts++;
      final candidate = Offset(
          0.08 + _rng.nextDouble() * 0.84, 0.08 + _rng.nextDouble() * 0.84);
      if (points.every((p) => (p - candidate).distance > 0.13)) {
        points.add(candidate);
      }
    }
    while (points.length < count) {
      points.add(
          Offset(0.1 + _rng.nextDouble() * 0.8, 0.1 + _rng.nextDouble() * 0.8));
    }
    return points;
  }

  void _answerTap(int index) {
    if (finished) return;
    if (_options[index] == _answer) {
      final winAnswer = _answer;
      registerCorrect(
        points: (combo) =>
            (12 * (1 + combo ~/ 3) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      final winCombo = combo;
      setState(() {
        _winAnswer = winAnswer;
        _winCombo = winCombo;
        _showWin = true;
        _fxId++;
        _newRound();
      });
      _winTimer?.cancel();
      _winTimer = Timer(const Duration(milliseconds: 820), () {
        if (mounted) setState(() => _showWin = false);
      });
    } else {
      registerWrong(
        penalty: _tune.penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() {
        _wrongIndex = index;
        _wrongId++;
      });
    }
  }

  void _restart() {
    setState(() {
      _showWin = false;
      _newRound();
    });
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    final instruction = _colorMode
        ? L('Chỉ đếm chấm XANH', 'Count only the BLUE dots')
        : L('Đếm số chấm', 'Count the dots');
    final milestone = _winCombo >= 6 && _winCombo % 3 == 0;
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
                      const SizedBox(height: Insets.sm),
                      const _CountHeader(),
                      const SizedBox(height: Insets.xs),
                      Text(instruction,
                          style: const TextStyle(
                              color: AppPalette.textSecondary,
                              fontSize: 15,
                              letterSpacing: 0.5)),
                      const SizedBox(height: Insets.md),
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              key: ValueKey(_roundId),
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Image.asset('$_cdDir/board.png',
                                          fit: BoxFit.fill)
                                      .animate(key: ValueKey('b$_roundId'))
                                      .fadeIn(duration: 220.ms)
                                      .scaleXY(
                                          begin: 0.92,
                                          end: 1,
                                          duration: 380.ms,
                                          curve: Curves.easeOutBack),
                                ),
                                for (var i = 0; i < _dots.length; i++)
                                  Align(
                                    alignment: Alignment(
                                      _dots[i].position.dx * 2 - 1,
                                      _dots[i].position.dy * 2 - 1,
                                    ),
                                    child: _DotSprite(
                                      dot: _dots[i],
                                      index: i,
                                      roundId: _roundId,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Insets.xs),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: Insets.md,
                          crossAxisSpacing: Insets.md,
                          childAspectRatio: 1.9,
                          clipBehavior: Clip.none,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var i = 0; i < _options.length; i++)
                              _AnswerPad(
                                value: _options[i],
                                index: i,
                                roundId: _roundId,
                                isWrong: _wrongIndex == i,
                                onTap: () => _answerTap(i),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showWin) _buildWinFx(),
            if (_showWin && milestone)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Image.asset('$_cdDir/shimmer.png',
                            width: MediaQuery.of(context).size.width * 1.2,
                            fit: BoxFit.fitWidth)
                        .animate(key: ValueKey('shim$_fxId'))
                        .slideX(
                            begin: -1.4,
                            end: 1.4,
                            duration: 720.ms,
                            curve: Curves.easeInOut)
                        .fadeOut(delay: 520.ms, duration: 200.ms),
                  ),
                ),
              ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: '$_cdDir/trophy.png',
                icon: Icons.blur_on_rounded,
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

  /// Clean correct-answer celebration centred on the board (see [WinBurst]).
  Widget _buildWinFx() => WinBurst(
        dir: _cdDir,
        fxId: _fxId,
        combo: _winCombo,
        reveal: _RevealCount(value: _winAnswer, fxId: _fxId),
      );
}

/// The "123" count badge with a soft pulsing halo and a gentle bob.
class _CountHeader extends StatelessWidget {
  const _CountHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset('$_cdDir/halo.png', width: 96, height: 96)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.16, end: 0.45, duration: 1600.ms)
              .scaleXY(begin: 0.9, end: 1.12, duration: 1600.ms),
          Image.asset('$_cdDir/badge_count.png', width: 64)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                  begin: -4, end: 4, duration: 1800.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

/// A single dot: staggered pop-in, then a perpetual float-bob + glow pulse +
/// tiny phase-offset wobble so the board feels alive.
class _DotSprite extends StatelessWidget {
  const _DotSprite({
    required this.dot,
    required this.index,
    required this.roundId,
  });
  final _Dot dot;
  final int index;
  final int roundId;

  @override
  Widget build(BuildContext context) {
    return Image.asset(dot.asset, width: 34, height: 34)
        // idle loop
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
            begin: -3,
            end: 3,
            duration: dot.bobMs.ms,
            curve: Curves.easeInOut)
        .scaleXY(
            begin: 0.97,
            end: 1.05,
            duration: dot.bobMs.ms,
            curve: Curves.easeInOut)
        .rotate(
            begin: -dot.rot,
            end: dot.rot,
            duration: dot.bobMs.ms,
            curve: Curves.easeInOut)
        // staggered entrance pop
        .animate(key: ValueKey('dot$roundId-$index'))
        .scaleXY(
            begin: 0,
            end: 1,
            delay: (index * 45).ms,
            duration: 380.ms,
            curve: Curves.easeOutBack)
        .fadeIn(delay: (index * 45).ms, duration: 200.ms);
  }
}

class _AnswerPad extends StatelessWidget {
  const _AnswerPad({
    required this.value,
    required this.index,
    required this.roundId,
    required this.isWrong,
    required this.onTap,
  });

  final int value;
  final int index;
  final int roundId;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget pad = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset('$_cdDir/pad.png', fit: BoxFit.fill),
            ),
            if (isWrong)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    color: AppPalette.danger.withValues(alpha: 0.24),
                  ),
                ),
              ),
            Text('$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                )),
            if (isWrong)
              Positioned(
                right: 14,
                child: Image.asset('$_cdDir/cross.png', width: 30)
                    .animate(key: ValueKey('x$roundId-$index'))
                    .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1),
                        duration: 240.ms,
                        curve: Curves.easeOutBack),
              ),
          ],
        ),
      ),
    );
    if (isWrong) {
      pad = pad.animate().shake(hz: 4, rotation: 0.02, duration: 320.ms);
    }
    return pad
        .animate(key: ValueKey('pad$roundId-$index'))
        .fadeIn(delay: (index * 60).ms, duration: 240.ms)
        .slideY(
            begin: 0.4,
            end: 0,
            delay: (index * 60).ms,
            duration: 300.ms,
            curve: Curves.easeOut);
  }
}

class _RevealCount extends StatelessWidget {
  const _RevealCount({required this.value, required this.fxId});
  final int value;
  final int fxId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: AppPalette.math, blurRadius: 22),
              Shadow(color: AppPalette.math, blurRadius: 36),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Image.asset('$_cdDir/check.png', width: 40),
      ],
    )
        .animate(key: ValueKey('reveal$fxId'))
        .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 360.ms,
            curve: Curves.easeOutBack)
        .then(delay: 240.ms)
        .fadeOut(duration: 240.ms);
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
    duration: const Duration(milliseconds: 300),
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
        final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 6) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
