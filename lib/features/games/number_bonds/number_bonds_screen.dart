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

/// Asset paths for the Number Bonds sprite + FX pack.
class _Nb {
  static const dir = 'assets/games/number_bonds';
  static const targetBadge = '$dir/target_badge.png';
  static const tile = '$dir/tile.png';
  static const tileSelected = '$dir/tile_selected.png';
  static const boardFrame = '$dir/board_frame.png';
  static const plusLink = '$dir/plus_link.png';
  static const owl = '$dir/owl_mascot.png';
  static const halo = '$dir/halo.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const spark = '$dir/spark.png';
  static const ring = '$dir/ring.png';
  static const popRing = '$dir/pop_ring.png';
  static const shimmer = '$dir/shimmer.png';
  static const sparkle = '$dir/sparkle.png';
  static const pairBeam = '$dir/pair_beam.png';
  static const check = '$dir/check.png';
  static const cross = '$dir/cross.png';
  static const trophy = '$dir/trophy.png';
}

class NumberBondsScreen extends StatefulWidget {
  const NumberBondsScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<NumberBondsScreen> createState() => _NumberBondsScreenState();
}

class _NumberBondsScreenState extends State<NumberBondsScreen>
    with TimedSessionMixin, TickerProviderStateMixin {
  static const Color _accent = AppPalette.math;

  final _rng = math.Random();
  int _target = 10;
  List<int> _numbers = [];
  int _selected = -1;
  int _boardId = 0;

  // ── FX state (additive — never changes the bond / scoring logic) ──────────
  int _correctFxId = 0;
  int _wrongFxId = 0;
  int _tapFxId = 0;
  int _comboFxId = 0;
  Offset _tapPos = Offset.zero;

  late final AnimationController _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 340));

  @override
  double get sessionSeconds => 50;

  int get _targetBase => switch (widget.difficulty) {
        Difficulty.easy => 10,
        Difficulty.medium => 15,
        Difficulty.hard => 20,
      };

  @override
  void initState() {
    super.initState();
    _newBoard();
    startSession();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _newBoard() {
    _target = _targetBase + _rng.nextInt(6);
    // Guarantee at least one valid pair.
    final x = 1 + _rng.nextInt(_target - 1);
    _numbers = [x, _target - x];
    while (_numbers.length < 6) {
      _numbers.add(1 + _rng.nextInt(_target - 1));
    }
    _numbers.shuffle(_rng);
    _selected = -1;
    _boardId++;
  }

  void _onPointerDown(Offset pos) {
    if (finished) return;
    setState(() {
      _tapPos = pos;
      _tapFxId++; // ripple at every tap
    });
  }

  void _tap(int index) {
    if (finished) return;
    if (_selected == -1) {
      setState(() => _selected = index);
      return;
    }
    if (_selected == index) {
      setState(() => _selected = -1);
      return;
    }
    final sum = _numbers[_selected] + _numbers[index];
    if (sum == _target) {
      registerCorrect(
        points: (c) =>
            (14 * (1 + c ~/ 3) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      setState(() {
        _correctFxId++;
        if (combo > 0 && combo % 4 == 0) _comboFxId++;
        _newBoard();
      });
    } else {
      registerWrong(
        penalty: 1.5,
        flashColor: AppPalette.danger.withValues(alpha: 0.18),
      );
      _shakeCtrl.forward(from: 0);
      setState(() {
        _wrongFxId++;
        _selected = -1;
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
          blobs: const [AppPalette.math, AppPalette.logic],
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: flash ?? Colors.transparent,
              ),
              SafeArea(
                child: AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final t = _shakeCtrl.value;
                    final dx = math.sin(t * math.pi * 5) * 6 * (1 - t);
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
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
                        _Header(),
                        const SizedBox(height: Insets.sm),
                        _Target(boardId: _boardId, target: _target),
                        const SizedBox(height: Insets.xs),
                        Image.asset(_Nb.plusLink, width: 92)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.7, end: 1, duration: 1300.ms),
                        const Spacer(),
                        _board(),
                        const SizedBox(height: Insets.lg),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: _fxLayer()),
                ),
              ),
              if (finished)
                ResultOverlay(
                  title: L('Hết giờ!', 'Time up!'),
                  score: score,
                  scoreSuffix: L('điểm', 'pts'),
                  accent: _accent,
                  iconAsset: _Nb.trophy,
                  icon: Icons.join_full_rounded,
                  stats: [
                    ResultStat(L('Đúng', 'Correct'), '$hits'),
                    ResultStat('Combo', 'x$bestCombo'),
                  ],
                  onRetry: () {
                    setState(() {
                      _correctFxId = 0;
                      _wrongFxId = 0;
                      _tapFxId = 0;
                      _comboFxId = 0;
                      _newBoard();
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

  Widget _board() {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(_Nb.boardFrame, fit: BoxFit.fill)),
        Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: GridView.builder(
            key: ValueKey('g$_boardId'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: Insets.md,
              crossAxisSpacing: Insets.md,
              childAspectRatio: 1.0,
            ),
            itemCount: _numbers.length,
            itemBuilder: (context, i) => _Chip(
              key: ValueKey('$_boardId-$i'),
              value: _numbers[i],
              selected: _selected == i,
              delayMs: i * 45,
              onTap: () => _tap(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fxLayer() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_tapFxId > 0)
          _Spot(
            center: _tapPos,
            child: Image.asset(_Nb.popRing, width: 90)
                .animate(key: ValueKey('pr$_tapFxId'))
                .scaleXY(begin: 0.3, end: 1.3, duration: 420.ms, curve: Curves.easeOut)
                .fadeOut(delay: 140.ms, duration: 280.ms),
          ),
        if (_correctFxId > 0) ...[
          Align(
            alignment: const Alignment(0, -0.05),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(_Nb.pairBeam, width: 320)
                    .animate(key: ValueKey('pb$_correctFxId'))
                    .fadeIn(duration: 120.ms)
                    .scaleX(begin: 0.4, end: 1.0, duration: 320.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 220.ms, duration: 300.ms),
                Image.asset(_Nb.confetti, width: 280)
                    .animate(key: ValueKey('cf$_correctFxId'))
                    .scaleXY(begin: 0.5, end: 1.1, duration: 520.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 320.ms, duration: 420.ms),
                Image.asset(_Nb.burst, width: 200)
                    .animate(key: ValueKey('bu$_correctFxId'))
                    .scaleXY(begin: 0.4, end: 1.1, duration: 340.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 200.ms, duration: 300.ms),
                if (combo >= 3)
                  Image.asset(_Nb.spark, width: 230)
                      .animate(key: ValueKey('sk$_correctFxId'))
                      .fadeIn(duration: 110.ms)
                      .scaleXY(begin: 0.6, end: 1.1, duration: 320.ms)
                      .fadeOut(delay: 200.ms, duration: 260.ms),
                Image.asset(_Nb.sparkle, width: 70)
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
                Image.asset(_Nb.ring, width: 120)
                    .animate(key: ValueKey('rg$_correctFxId'))
                    .scaleXY(begin: 0.4, end: 1.3, duration: 440.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 180.ms, duration: 300.ms),
                Image.asset(_Nb.check, width: 54)
                    .animate(key: ValueKey('ck$_correctFxId'))
                    .scaleXY(begin: 0.3, end: 1, duration: 320.ms, curve: Curves.easeOutBack)
                    .then(delay: 240.ms)
                    .fadeOut(duration: 240.ms),
              ],
            ),
          ),
        ],
        if (_wrongFxId > 0)
          _Spot(
            center: _tapPos,
            child: Image.asset(_Nb.cross, width: 52)
                .animate(key: ValueKey('x$_wrongFxId'))
                .fadeIn(duration: 90.ms)
                .scaleXY(begin: 1.5, end: 1, duration: 240.ms, curve: Curves.easeOutBack)
                .then(delay: 220.ms)
                .fadeOut(duration: 240.ms),
          ),
        if (_comboFxId > 0)
          Align(
            alignment: Alignment.center,
            child: Image.asset(_Nb.shimmer,
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

/// Owl mascot beside the instruction.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(_Nb.owl, width: 44, height: 44, fit: BoxFit.contain)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -2, end: 2, duration: 2200.ms, curve: Curves.easeInOut),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            L('Chọn 2 số cộng lại bằng', 'Pick two numbers that sum to'),
            style: const TextStyle(color: AppPalette.textSecondary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// The target sum shown inside the glowing badge ring over a pulsing halo.
class _Target extends StatelessWidget {
  const _Target({required this.boardId, required this.target});
  final int boardId;
  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset(_Nb.halo, width: 168)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 0.75, duration: 1300.ms)
              .scaleXY(begin: 0.92, end: 1.1, duration: 1300.ms),
          Image.asset(_Nb.targetBadge, width: 128, height: 128),
          Text(
            '$target',
            style: const TextStyle(
              color: AppPalette.math,
              fontSize: 50,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('t$boardId'))
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }
}

class _Chip extends StatefulWidget {
  const _Chip({
    super.key,
    required this.value,
    required this.selected,
    required this.delayMs,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final int delayMs;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 340));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: widget.selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.logic.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              )
            : const BoxDecoration(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                widget.selected ? _Nb.tileSelected : _Nb.tile,
                fit: BoxFit.fill,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '${widget.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final e = Curves.easeOutBack.transform(_enter.value.clamp(0, 1));
        return Opacity(
          opacity: _enter.value.clamp(0, 1),
          child: Transform.scale(scale: 0.4 + 0.6 * e, child: child),
        );
      },
      child: face,
    );
  }
}
