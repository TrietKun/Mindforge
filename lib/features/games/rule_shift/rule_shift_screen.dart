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

/// Asset paths for the Rule Shift sprite + FX pack.
class _Rs {
  static const dir = 'assets/games/rule_shift';
  static const stimulusCard = '$dir/stimulus_card.png';
  static const choiceBtn = '$dir/choice_btn.png';
  static const badgeColor = '$dir/badge_color.png';
  static const badgeShape = '$dir/badge_shape.png';
  static const ruleBanner = '$dir/rule_banner.png';
  static const swapMotif = '$dir/swap_motif.png';
  static const halo = '$dir/halo.png';
  static const owl = '$dir/owl_mascot.png';
  static const trophy = '$dir/trophy.png';
  static const sparkle = '$dir/sparkle.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const spark = '$dir/spark.png';
  static const ring = '$dir/ring.png';
  static const popRing = '$dir/pop_ring.png';
  static const shimmer = '$dir/shimmer.png';
  static const check = '$dir/check.png';
  static const cross = '$dir/cross.png';
}

const _shapeAssets = [
  '${_Rs.dir}/shape_circle.png',
  '${_Rs.dir}/shape_square.png',
  '${_Rs.dir}/shape_triangle.png',
  '${_Rs.dir}/shape_star.png',
];
const _colors = [
  AppPalette.danger,
  AppPalette.focus,
  AppPalette.logic,
  AppPalette.gold,
];

enum _Rule { color, shape }

class RuleShiftScreen extends StatefulWidget {
  const RuleShiftScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<RuleShiftScreen> createState() => _RuleShiftScreenState();
}

class _RuleShiftScreenState extends State<RuleShiftScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.flexibility;

  final _rng = math.Random();
  late _Rule _rule;
  int _shape = 0;
  int _color = 0;
  int _roundId = 0;
  int? _wrongIndex;

  // ── FX state (additive — never changes the rule / scoring logic) ──────────
  int _correctFxId = 0;
  int _wrongFxId = 0;
  int _tapFxId = 0;
  int _comboFxId = 0;
  int _ruleFlipId = 0;
  Offset _tapPos = Offset.zero;

  @override
  double get sessionSeconds => 35;

  ({double flip, double penalty}) get _tune => switch (widget.difficulty) {
        Difficulty.easy => (flip: 0.3, penalty: 1.0),
        Difficulty.medium => (flip: 0.5, penalty: 1.5),
        Difficulty.hard => (flip: 0.7, penalty: 2.0),
      };

  @override
  void initState() {
    super.initState();
    _rule = _rng.nextBool() ? _Rule.color : _Rule.shape;
    _next(first: true);
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _next({bool first = false}) {
    final old = _rule;
    if (!first && _rng.nextDouble() < _tune.flip) {
      _rule = _rule == _Rule.color ? _Rule.shape : _Rule.color;
    }
    if (_rule != old) _ruleFlipId++; // FX: "RULE CHANGED!" banner
    _shape = _rng.nextInt(4);
    _color = _rng.nextInt(4);
    _roundId++;
  }

  int get _answer => _rule == _Rule.color ? _color : _shape;

  void _onPointerDown(Offset pos) {
    if (finished) return;
    setState(() {
      _tapPos = pos;
      _tapFxId++; // pop ripple at every tap
    });
  }

  void _tap(int index) {
    if (finished) return;
    if (index == _answer) {
      registerCorrect(
        points: (c) =>
            (10 * (1 + c ~/ 4) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      setState(() {
        _correctFxId++;
        if (combo > 0 && combo % 4 == 0) _comboFxId++;
        _wrongIndex = null;
        _next();
      });
    } else {
      registerWrong(
        penalty: _tune.penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() {
        _wrongFxId++;
        _wrongIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        child: AuroraBackground(
          blobs: const [AppPalette.flexibility, AppPalette.focus],
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
                      Image.asset(_Rs.owl, width: 46, height: 46, fit: BoxFit.contain)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                              begin: -2,
                              end: 2,
                              duration: 2200.ms,
                              curve: Curves.easeInOut),
                      const SizedBox(height: Insets.sm),
                      _RuleBadge(rule: _rule),
                      const SizedBox(height: Insets.xl),
                      _Stimulus(roundId: _roundId, shape: _shape, color: _color),
                      const Spacer(),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        mainAxisSpacing: Insets.sm,
                        crossAxisSpacing: Insets.sm,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var i = 0; i < 4; i++)
                            _Choice(
                              byColor: _rule == _Rule.color,
                              index: i,
                              isWrong: _wrongIndex == i,
                              onTap: () => _tap(i),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: _fxLayer()),
                ),
              ),
              if (_ruleFlipId > 0)
                Positioned.fill(
                  child: IgnorePointer(child: _RuleChangedBanner(id: _ruleFlipId)),
                ),
              if (finished)
                ResultOverlay(
                  title: L('Hết giờ!', 'Time up!'),
                  score: score,
                  scoreSuffix: L('điểm', 'pts'),
                  accent: _accent,
                  iconAsset: _Rs.trophy,
                  icon: Icons.rule_rounded,
                  stats: [
                    ResultStat(L('Đúng', 'Correct'), '$hits'),
                    ResultStat('Combo', 'x$bestCombo'),
                    ResultStat(L('Chính xác', 'Accuracy'), '$accuracy%'),
                  ],
                  onRetry: () {
                    setState(() {
                      _correctFxId = 0;
                      _wrongFxId = 0;
                      _tapFxId = 0;
                      _comboFxId = 0;
                      _ruleFlipId = 0;
                      _rule = _rng.nextBool() ? _Rule.color : _Rule.shape;
                      _next(first: true);
                    });
                    startSession();
                  },
                  onClose: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fxLayer() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ripple at every tap point
        if (_tapFxId > 0)
          _Spot(
            center: _tapPos,
            child: Image.asset(_Rs.popRing, width: 90)
                .animate(key: ValueKey('pr$_tapFxId'))
                .scaleXY(begin: 0.3, end: 1.3, duration: 420.ms, curve: Curves.easeOut)
                .fadeOut(delay: 140.ms, duration: 280.ms),
          ),
        // correct: burst + confetti + sparkle at centre, ring + check at the tap
        if (_correctFxId > 0) ...[
          Align(
            alignment: const Alignment(0, -0.1),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(_Rs.confetti, width: 280)
                    .animate(key: ValueKey('cf$_correctFxId'))
                    .scaleXY(begin: 0.5, end: 1.1, duration: 520.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 320.ms, duration: 420.ms),
                Image.asset(_Rs.burst, width: 200)
                    .animate(key: ValueKey('bu$_correctFxId'))
                    .scaleXY(begin: 0.4, end: 1.1, duration: 340.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 200.ms, duration: 300.ms),
                if (combo >= 4)
                  Image.asset(_Rs.spark, width: 240)
                      .animate(key: ValueKey('sk$_correctFxId'))
                      .fadeIn(duration: 110.ms)
                      .scaleXY(begin: 0.6, end: 1.1, duration: 320.ms)
                      .fadeOut(delay: 200.ms, duration: 260.ms),
                Image.asset(_Rs.sparkle, width: 70)
                    .animate(key: ValueKey('sp$_correctFxId'))
                    .scaleXY(begin: 0.2, end: 1, duration: 320.ms, curve: Curves.easeOutBack)
                    .then(delay: 120.ms)
                    .fadeOut(duration: 240.ms),
              ],
            ),
          ),
          _Spot(
            center: _tapPos,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(_Rs.ring, width: 120)
                    .animate(key: ValueKey('rg$_correctFxId'))
                    .scaleXY(begin: 0.4, end: 1.3, duration: 440.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 180.ms, duration: 300.ms),
                Image.asset(_Rs.check, width: 56)
                    .animate(key: ValueKey('ck$_correctFxId'))
                    .scaleXY(begin: 0.3, end: 1, duration: 320.ms, curve: Curves.easeOutBack)
                    .then(delay: 260.ms)
                    .fadeOut(duration: 240.ms),
              ],
            ),
          ),
        ],
        // wrong: cross at the tap point
        if (_wrongFxId > 0)
          _Spot(
            center: _tapPos,
            child: Image.asset(_Rs.cross, width: 52)
                .animate(key: ValueKey('x$_wrongFxId'))
                .fadeIn(duration: 90.ms)
                .scaleXY(begin: 1.5, end: 1, duration: 240.ms, curve: Curves.easeOutBack)
                .then(delay: 220.ms)
                .fadeOut(duration: 240.ms),
          ),
        // combo milestone shimmer sweep
        if (_comboFxId > 0)
          Align(
            alignment: Alignment.center,
            child: Image.asset(_Rs.shimmer,
                    width: MediaQuery.of(context).size.width * 1.2,
                    fit: BoxFit.fitWidth)
                .animate(key: ValueKey('shim$_comboFxId'))
                .slideX(begin: -1.4, end: 1.4, duration: 760.ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }
}

/// Positions [child] centred on [center] within the FX layer.
class _Spot extends StatelessWidget {
  const _Spot({required this.center, required this.child});
  final Offset center;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - 140,
      top: center.dy - 140,
      width: 280,
      height: 280,
      child: Center(child: child),
    );
  }
}

/// The current rule shown as a glowing sprite badge ("by COLOR" gold / "by
/// SHAPE" pink) over a pulsing halo, with the localized label kept beneath it.
class _RuleBadge extends StatelessWidget {
  const _RuleBadge({required this.rule});
  final _Rule rule;

  @override
  Widget build(BuildContext context) {
    final byColor = rule == _Rule.color;
    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset(_Rs.halo, width: 200)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.35, end: 0.7, duration: 1200.ms)
              .scaleXY(begin: 0.9, end: 1.12, duration: 1200.ms),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(byColor ? _Rs.badgeColor : _Rs.badgeShape, height: 56),
              const SizedBox(height: 2),
              Text(
                byColor
                    ? L('Phân loại theo MÀU', 'Sort by COLOR')
                    : L('Phân loại theo HÌNH', 'Sort by SHAPE'),
                style: TextStyle(
                  color: byColor ? AppPalette.gold : AppPalette.flexibility,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(key: ValueKey(rule))
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }
}

/// The stimulus: a shape sprite tinted by its colour on a glossy card, over a
/// slowly rotating swap motif.
class _Stimulus extends StatelessWidget {
  const _Stimulus({
    required this.roundId,
    required this.shape,
    required this.color,
  });
  final int roundId;
  final int shape;
  final int color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.1,
            child: Image.asset(_Rs.swapMotif, width: 150)
                .animate(onPlay: (c) => c.repeat())
                .rotate(begin: 0, end: 1, duration: 7000.ms),
          ),
          Positioned.fill(child: Image.asset(_Rs.stimulusCard, fit: BoxFit.fill)),
          ColorFiltered(
            colorFilter: ColorFilter.mode(_colors[color], BlendMode.modulate),
            child: Image.asset(_shapeAssets[shape], width: 76),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(roundId))
        .fadeIn(duration: 160.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.byColor,
    required this.index,
    required this.isWrong,
    required this.onTap,
  });
  final bool byColor;
  final int index;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glyph = byColor
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(_colors[index], BlendMode.modulate),
            child: Image.asset(_shapeAssets[0], width: 34), // tinted circle = colour
          )
        : Image.asset(_shapeAssets[index], width: 34); // white shape

    final cell = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Image.asset(_Rs.choiceBtn, fit: BoxFit.fill)),
          if (isWrong)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  color: AppPalette.danger.withValues(alpha: 0.28),
                ),
              ),
            ),
          glyph,
        ],
      ),
    );
    if (isWrong) {
      return cell.animate().shake(hz: 4, rotation: 0.02, duration: 300.ms);
    }
    return cell;
  }
}

/// "RULE CHANGED!" banner that slides across whenever the rule flips.
class _RuleChangedBanner extends StatelessWidget {
  const _RuleChangedBanner({required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.35),
      child: Image.asset(_Rs.ruleBanner, width: 250)
          .animate(key: ValueKey('rc$id'))
          .slideX(begin: -1.8, end: 0, duration: 420.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 180.ms)
          .then(delay: 620.ms)
          .slideX(begin: 0, end: 1.8, duration: 380.ms, curve: Curves.easeIn)
          .fadeOut(duration: 260.ms),
    );
  }
}
