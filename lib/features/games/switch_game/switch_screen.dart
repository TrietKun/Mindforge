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

const String _dir = 'assets/games/switch_game';

enum _Rule { bigger, smaller }

class SwitchScreen extends StatefulWidget {
  const SwitchScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<SwitchScreen> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> with TimedSessionMixin {
  static const Color _accent = AppPalette.flexibility;

  final _rng = math.Random();
  late _Rule _rule;
  late int _left;
  late int _right;
  int _roundId = 0;
  int? _wrongSide; // 0 = left, 1 = right
  bool _showBurst = false;
  bool _showCross = false;
  int _fxId = 0;

  @override
  double get sessionSeconds => 30;

  ({double flip, int gap, double penalty}) get _tune =>
      switch (widget.difficulty) {
        Difficulty.easy => (flip: 0.3, gap: 30, penalty: 1.0),
        Difficulty.medium => (flip: 0.5, gap: 14, penalty: 1.5),
        Difficulty.hard => (flip: 0.65, gap: 5, penalty: 2.0),
      };

  @override
  void initState() {
    super.initState();
    _rule = _rng.nextBool() ? _Rule.bigger : _Rule.smaller;
    _nextRound(first: true);
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _nextRound({bool first = false}) {
    if (!first && _rng.nextDouble() < _tune.flip) {
      _rule = _rule == _Rule.bigger ? _Rule.smaller : _Rule.bigger;
    }
    final gap = 1 + _rng.nextInt(_tune.gap);
    final base = 1 + _rng.nextInt(98 - gap);
    if (_rng.nextBool()) {
      _left = base;
      _right = base + gap;
    } else {
      _left = base + gap;
      _right = base;
    }
    _roundId++;
  }

  int get _correctSide {
    final leftWins = _rule == _Rule.bigger ? _left > _right : _left < _right;
    return leftWins ? 0 : 1;
  }

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
        _showBurst = true;
        _fxId++;
        _nextRound();
      });
      Future.delayed(const Duration(milliseconds: 620), () {
        if (mounted) setState(() => _showBurst = false);
      });
    } else {
      registerWrong(
        penalty: _tune.penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() {
        _wrongSide = side;
        _showCross = true;
        _fxId++;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showCross = false);
      });
    }
  }

  void _restart() {
    setState(() {
      _wrongSide = null;
      _rule = _rng.nextBool() ? _Rule.bigger : _Rule.smaller;
      _nextRound(first: true);
    });
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    final isBigger = _rule == _Rule.bigger;
    final ruleColor = isBigger ? AppPalette.success : AppPalette.reaction;
    // Reveal the right answer on the unselected pad after a wrong tap.
    final revealing = _wrongSide != null;
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.flexibility, AppPalette.memory],
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final compact = c.maxHeight < 640;
                  final mascotSize = compact ? 56.0 : 88.0;
                  final padHeight = compact ? 104.0 : 150.0;
                  final versusSize = compact ? 36.0 : 50.0;
                  final ruleFontSize = compact ? 15.0 : 18.0;
                  final arrowSize = compact ? 22.0 : 30.0;
                  final gtSize = compact ? 20.0 : 26.0;
                  final gapAfterBanner = compact ? Insets.md : Insets.xl;
                  final gapBeforeBanner = compact ? Insets.sm : Insets.md;
                  final outerPad = compact ? Insets.md : Insets.lg;

                  return Padding(
                    padding: EdgeInsets.all(outerPad),
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
                        Image.asset(
                          '$_dir/scale_mascot.png',
                          width: mascotSize,
                          height: mascotSize,
                        ),
                        SizedBox(height: gapBeforeBanner),
                        // Rule banner — re-keyed on every rule change to flag it.
                        Container(
                          key: ValueKey(_rule),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? Insets.md : Insets.lg,
                            vertical: compact ? Insets.sm : Insets.md,
                          ),
                          decoration: BoxDecoration(
                            color: ruleColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(Radii.pill),
                            border: Border.all(
                                color: ruleColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                isBigger
                                    ? '$_dir/arrow_up.png'
                                    : '$_dir/arrow_down.png',
                                width: arrowSize,
                                height: arrowSize,
                              ),
                              const SizedBox(width: Insets.sm),
                              Flexible(
                                child: Text(
                                  isBigger
                                      ? L('Chọn số LỚN HƠN', 'Pick the BIGGER')
                                      : L('Chọn số NHỎ HƠN', 'Pick the SMALLER'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ruleColor,
                                    fontSize: ruleFontSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Insets.sm),
                              Image.asset(
                                isBigger ? '$_dir/gt.png' : '$_dir/lt.png',
                                width: gtSize,
                                height: gtSize,
                              ),
                            ],
                          ),
                        )
                            .animate(key: ValueKey(_rule))
                            .fadeIn(duration: 180.ms)
                            .scale(
                                begin: const Offset(0.85, 0.85),
                                curve: Curves.easeOutBack)
                            .shake(hz: 4, rotation: 0.01),
                        SizedBox(height: gapAfterBanner),
                        Row(
                          key: ValueKey(_roundId),
                          children: [
                            Expanded(
                              child: _NumberPad(
                                value: _left,
                                height: padHeight,
                                isWrong: _wrongSide == 0,
                                revealCorrect: revealing && _correctSide == 0,
                                onTap: () => _answer(0),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Insets.sm),
                              child: Image.asset('$_dir/versus.png',
                                  width: versusSize),
                            ),
                            Expanded(
                              child: _NumberPad(
                                value: _right,
                                height: padHeight,
                                isWrong: _wrongSide == 1,
                                revealCorrect: revealing && _correctSide == 1,
                                onTap: () => _answer(1),
                              ),
                            ),
                          ],
                        )
                            .animate(key: ValueKey(_roundId))
                            .fadeIn(duration: 160.ms),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_showBurst)
              IgnorePointer(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('$_dir/burst.png', width: 220)
                          .animate(key: ValueKey('b$_fxId'))
                          .scale(
                              begin: const Offset(0.4, 0.4),
                              curve: Curves.easeOut,
                              duration: 360.ms)
                          .fadeOut(delay: 180.ms, duration: 300.ms),
                      Image.asset('$_dir/sparkle.png', width: 96)
                          .animate(key: ValueKey('s$_fxId'))
                          .scale(
                              begin: const Offset(0.3, 0.3),
                              curve: Curves.easeOutBack,
                              duration: 300.ms)
                          .then()
                          .fadeOut(duration: 220.ms),
                    ],
                  ),
                ),
              ),
            if (_showCross)
              IgnorePointer(
                child: Center(
                  child: Image.asset('$_dir/cross.png', width: 96)
                      .animate(key: ValueKey('x$_fxId'))
                      .scale(
                          begin: const Offset(0.4, 0.4),
                          curve: Curves.easeOutBack,
                          duration: 220.ms)
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
                icon: Icons.swap_horiz_rounded,
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
}

class _NumberPad extends StatefulWidget {
  const _NumberPad({
    required this.value,
    required this.height,
    required this.isWrong,
    required this.revealCorrect,
    required this.onTap,
  });
  final int value;
  final double height;
  final bool isWrong;
  final bool revealCorrect;
  final VoidCallback onTap;

  @override
  State<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<_NumberPad> {
  bool _pressed = false;

  Color get _neonColor {
    if (widget.isWrong) return AppPalette.danger;
    if (widget.revealCorrect) return AppPalette.success;
    return AppPalette.flexibility;
  }

  @override
  Widget build(BuildContext context) {
    final neon = _neonColor;
    final radius = BorderRadius.circular(28);
    final base = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        child: SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(color: neon, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: neon.withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: neon.withValues(alpha: 0.25),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: neon.withValues(alpha: 0.85), width: 1.5),
                    ),
                  ),
                ),
                Text(
                  '${widget.value}',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: widget.height < 130 ? 40 : 56,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: neon.withValues(alpha: 0.6),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.isWrong) {
      return base.animate().shake(hz: 4, rotation: 0.02, duration: 320.ms);
    }
    return base;
  }
}
