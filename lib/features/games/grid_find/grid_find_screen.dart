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

enum GridFindMode { symbol, hue }

const _glyphs = ['◆', '●', '▲', '★', '✦', '❤', '♠', '♣', '✚', '⬟'];

/// Asset paths for the Grid Find FX overhaul, grouped for tidiness.
class _Gf {
  static const dir = 'assets/games/grid_find';
  static const reveal = '$dir/reveal_ring.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const sparkle = '$dir/sparkle.png';
  static const spark = '$dir/spark.png';
  static const shockwave = '$dir/shockwave.png';
  static const shimmer = '$dir/shimmer.png';
  static const cross = '$dir/cross.png';
  static const levelUp = '$dir/level_up.png';
  static const trophy = '$dir/trophy.png';
  static const orbs = '$dir/glow_orbs.png';
  static const gridGlow = '$dir/grid_glow.png';
  static const stars = '$dir/stars.png';
  static const rays = '$dir/light_rays.png';
  static const owl = '$dir/owl_mascot.png';
  static const eye = '$dir/eye.png';
  static const target = '$dir/target.png';
}

/// Maps each logical glyph to its glossy sprite (symbol mode).
const _glyphSprite = <String, String>{
  '◆': '${_Gf.dir}/glyph_diamond.png',
  '●': '${_Gf.dir}/glyph_circle.png',
  '▲': '${_Gf.dir}/glyph_triangle.png',
  '★': '${_Gf.dir}/glyph_star.png',
  '✦': '${_Gf.dir}/glyph_sparkle.png',
  '❤': '${_Gf.dir}/glyph_heart.png',
  '♠': '${_Gf.dir}/glyph_spade.png',
  '♣': '${_Gf.dir}/glyph_club.png',
  '✚': '${_Gf.dir}/glyph_plus.png',
  '⬟': '${_Gf.dir}/glyph_pentagon.png',
};

class GridFindScreen extends StatefulWidget {
  const GridFindScreen({
    super.key,
    required this.mode,
    this.difficulty = Difficulty.medium,
  });

  final GridFindMode mode;
  final Difficulty difficulty;

  @override
  State<GridFindScreen> createState() => _GridFindScreenState();
}

class _GridFindScreenState extends State<GridFindScreen>
    with TimedSessionMixin, TickerProviderStateMixin {
  static const Color _accent = AppPalette.focus;

  final _rng = math.Random();
  int _grid = 3;
  int _oddIndex = 0;
  int _roundId = 0;
  int? _wrongIndex;

  // symbol mode
  String _baseGlyph = '◆';
  String _oddGlyph = '●';
  // hue mode
  Color _baseColor = AppPalette.focus;
  Color _oddColor = AppPalette.memory;

  // ── FX state (additive — never changes scoring / grid logic) ──────────────
  int _correctFxId = 0;
  int _comboFxId = 0;
  int _levelUpId = 0;
  Alignment _burstAlign = Alignment.center;
  int _burstGrid = 3;
  Timer? _hintTimer;

  late final AnimationController _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _hintCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  double get sessionSeconds => 45;

  String get _instruction => widget.mode == GridFindMode.symbol
      ? L('Tìm ký hiệu KHÁC BIỆT', 'Find the ODD symbol')
      : L('Tìm ô KHÁC MÀU', 'Find the ODD color');

  double get _penalty => switch (widget.difficulty) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.5,
        Difficulty.hard => 2.0,
      };

  @override
  void initState() {
    super.initState();
    _build();
    startSession();
    _armHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _shakeCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  void onSessionFinished() => setState(() {});

  /// Normalised position of [index] within a [grid]×[grid] board.
  Alignment _alignFor(int index, int grid) {
    if (grid <= 1) return Alignment.center;
    final col = index % grid, row = index ~/ grid;
    return Alignment(col * 2 / (grid - 1) - 1, row * 2 / (grid - 1) - 1);
  }

  /// Diagonal-wave entrance stagger for cell [index].
  int _entranceDelay(int index, int grid) {
    final col = index % grid, row = index ~/ grid;
    return (row + col) * 35;
  }

  /// (Re)arm the idle hint: after 6s without a tap the whole board pulses
  /// gently — every cell, so the odd one is never given away.
  void _armHint() {
    _hintTimer?.cancel();
    _hintCtrl.stop();
    _hintCtrl.value = 0;
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || finished) return;
      _hintCtrl.repeat(reverse: true);
    });
  }

  void _build() {
    final prevGrid = _grid;
    _grid = (3 + hits ~/ 5).clamp(3, 5);
    if (_roundId > 0 && _grid > prevGrid) _levelUpId++;
    final count = _grid * _grid;
    _oddIndex = _rng.nextInt(count);

    if (widget.mode == GridFindMode.symbol) {
      _baseGlyph = _glyphs[_rng.nextInt(_glyphs.length)];
      do {
        _oddGlyph = _glyphs[_rng.nextInt(_glyphs.length)];
      } while (_oddGlyph == _baseGlyph);
    } else {
      final hue = _rng.nextDouble() * 360;
      final delta = switch (widget.difficulty) {
            Difficulty.easy => 42.0,
            Difficulty.medium => 24.0,
            Difficulty.hard => 12.0,
          } -
          hits * 0.4;
      _baseColor = HSLColor.fromAHSL(1, hue, 0.65, 0.6).toColor();
      _oddColor =
          HSLColor.fromAHSL(1, (hue + math.max(6, delta)) % 360, 0.65, 0.6)
              .toColor();
    }
    _roundId++;
  }

  void _tap(int index) {
    if (finished) return;
    if (index == _oddIndex) {
      // Capture the tapped cell before the board rebuilds, so the celebration
      // locks onto where the player actually tapped.
      _burstAlign = _alignFor(_oddIndex, _grid);
      _burstGrid = _grid;
      registerCorrect(
        points: (c) =>
            ((6 + _grid) * (1 + c ~/ 4) * widget.difficulty.scoreMultiplier)
                .round(),
        flashColor: _accent.withValues(alpha: 0.12),
      );
      setState(() {
        _correctFxId++;
        if (combo > 0 && combo % 4 == 0) _comboFxId++;
        _wrongIndex = null;
        _build();
      });
      _armHint();
    } else {
      registerWrong(
        penalty: _penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.18),
      );
      _shakeCtrl.forward(from: 0);
      setState(() => _wrongIndex = index);
      _armHint();
    }
  }

  void _restart() {
    setState(() {
      _wrongIndex = null;
      _correctFxId = 0;
      _comboFxId = 0;
      _levelUpId = 0;
      _build();
    });
    startSession();
    _armHint();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.focus, AppPalette.memory],
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            const Positioned.fill(child: _AmbientLayer()),
            SafeArea(
              child: AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (context, child) {
                  final t = _shakeCtrl.value;
                  final dx = math.sin(t * math.pi * 4) * 6 * (1 - t);
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
                      _Header(instruction: _instruction, hint: _hintCtrl),
                      const SizedBox(height: Insets.lg),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            _board(),
                            if (_correctFxId > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: _CorrectFx(
                                      id: _correctFxId,
                                      align: _burstAlign,
                                      grid: _burstGrid,
                                      combo: combo,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: const _ShimmerSweep(),
                                ),
                              ),
                            ),
                            if (_comboFxId > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 0.3,
                                        child: Image.asset(_Gf.shimmer,
                                                height: 560, fit: BoxFit.fitHeight)
                                            .animate(key: ValueKey('combo$_comboFxId'))
                                            .slideX(
                                                begin: -1.8,
                                                end: 1.8,
                                                duration: 720.ms,
                                                curve: Curves.easeOut),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            if (_levelUpId > 0)
              Positioned.fill(
                child: IgnorePointer(child: _LevelUpBanner(id: _levelUpId)),
              ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: _Gf.trophy,
                icon: Icons.center_focus_strong_rounded,
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

  Widget _board() {
    final grid = GridView.builder(
      key: ValueKey(_roundId),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _grid,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _grid * _grid,
      itemBuilder: (context, i) {
        final isOdd = i == _oddIndex;
        return _Cell(
          key: ValueKey('$_roundId-$i'),
          mode: widget.mode,
          glyph: isOdd ? _oddGlyph : _baseGlyph,
          color: isOdd ? _oddColor : _baseColor,
          isWrong: _wrongIndex == i,
          delayMs: _entranceDelay(i, _grid),
          onTap: () => _tap(i),
        );
      },
    );
    // Idle hint: a gentle whole-board pulse driven by a persistent controller,
    // so toggling the hint never remounts (and re-pops) the cells.
    return AnimatedBuilder(
      animation: _hintCtrl,
      builder: (context, child) {
        final s = 1 + 0.014 * Curves.easeInOut.transform(_hintCtrl.value);
        return Transform.scale(scale: s, child: child);
      },
      child: grid,
    );
  }
}

/// Detective-owl mascot framed by a slow focus reticle, above the instruction.
/// A "look closely" eye pulses in only while the idle [hint] runs.
class _Header extends StatelessWidget {
  const _Header({required this.instruction, required this.hint});
  final String instruction;
  final AnimationController hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 86,
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.55,
                child: Image.asset(_Gf.target, width: 82)
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(begin: 0, end: 1, duration: 12000.ms),
              ),
              Image.asset(_Gf.owl, width: 56, height: 56, fit: BoxFit.contain)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: -3,
                      end: 3,
                      duration: 2200.ms,
                      curve: Curves.easeInOut),
              Positioned(
                right: 0,
                top: -2,
                child: AnimatedBuilder(
                  animation: hint,
                  builder: (context, child) =>
                      Opacity(opacity: hint.value * 0.9, child: child),
                  child: Image.asset(_Gf.eye, width: 30),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          instruction,
          style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 15,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    super.key,
    required this.mode,
    required this.glyph,
    required this.color,
    required this.isWrong,
    required this.delayMs,
    required this.onTap,
  });

  final GridFindMode mode;
  final String glyph;
  final Color color;
  final bool isWrong;
  final int delayMs;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  AnimationController? _wrong;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    // Diagonal-wave entrance: each cell pops in after its stagger delay.
    _enterTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void didUpdateWidget(_Cell old) {
    super.didUpdateWidget(old);
    if (widget.isWrong && !old.isWrong) {
      (_wrong ??= AnimationController(
              vsync: this, duration: const Duration(milliseconds: 380)))
          .forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enter.dispose();
    _wrong?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.mode == GridFindMode.hue
        ? widget.color
        : const Color(0xFF18233B);

    final isHue = widget.mode == GridFindMode.hue;
    Widget face = _GlossyCell(
      base: base,
      wrong: widget.isWrong,
      // Hue mode: keep the gloss subtle so the tile colour stays saturated and
      // the "odd colour" signal isn't washed toward white.
      vivid: isHue,
      child: isHue
          ? null
          : Padding(
              padding: const EdgeInsets.all(9),
              child: Image.asset(_glyphSprite[widget.glyph]!,
                  fit: BoxFit.contain),
            ),
    );

    if (widget.isWrong) {
      face = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          face,
          IgnorePointer(
            child: Image.asset(_Gf.cross, width: 40)
                .animate(key: ValueKey('x${_wrong?.hashCode}'))
                .fadeIn(duration: 90.ms)
                .scaleXY(
                    begin: 1.5,
                    end: 1.0,
                    duration: 240.ms,
                    curve: Curves.easeOutBack)
                .then(delay: 180.ms)
                .fadeOut(duration: 240.ms),
          ),
        ],
      );
    }

    Widget out = FadeTransition(
      opacity: _enter,
      child: ScaleTransition(
        scale: Tween(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: _enter, curve: Curves.easeOutBack)),
        child: face,
      ),
    );

    if (_wrong != null) {
      out = AnimatedBuilder(
        animation: _wrong!,
        builder: (context, child) {
          final t = _wrong!.value;
          final dx = math.sin(t * math.pi * 6) * 5 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: out,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: out,
    );
  }
}

/// A glossy rounded cell: vertical gradient on [base], a top sheen, a soft glow
/// and a thin rim (red when [wrong]). Tints perfectly for hue mode.
class _GlossyCell extends StatelessWidget {
  const _GlossyCell({
    required this.base,
    required this.wrong,
    this.vivid = false,
    this.child,
  });
  final Color base;
  final bool wrong;

  /// When true the gloss is kept light so [base]'s hue reads true (hue mode).
  final bool vivid;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Radii.md);
    final glow = wrong ? AppPalette.danger : base;
    final lightenTop = vivid ? 0.05 : 0.16;
    final darkenBottom = vivid ? 0.1 : 0.24;
    final sheenTop = vivid ? 0.14 : 0.32;
    final sheenHeight = vivid ? 0.4 : 0.46;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, Colors.white, lightenTop)!,
            base,
            Color.lerp(base, Colors.black, darkenBottom)!,
          ],
          stops: const [0, 0.5, 1],
        ),
        border: Border.all(
          color: wrong
              ? AppPalette.danger
              : Colors.white.withValues(alpha: 0.22),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: wrong ? 0.5 : 0.3),
            blurRadius: 11,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: sheenHeight,
                child: Container(
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: sheenTop),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (child != null) Center(child: child),
          ],
        ),
      ),
    );
  }
}

/// Correct-answer celebration locked onto the tapped cell: a reveal ring snaps
/// in, a burst + confetti fire and a sparkle pops, with a stronger spark at
/// higher combos.
class _CorrectFx extends StatelessWidget {
  const _CorrectFx({
    required this.id,
    required this.align,
    required this.grid,
    required this.combo,
  });

  final int id;
  final Alignment align;
  final int grid;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cell = c.maxWidth / grid;
        return Align(
          alignment: align,
          child: SizedBox(
            width: cell,
            height: cell,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // shockwave rippling outward from the solved cell
                Image.asset(_Gf.shockwave, width: cell * 2.2)
                    .animate(key: ValueKey('sw$id'))
                    .scaleXY(
                        begin: 0.4,
                        end: 1.5,
                        duration: 520.ms,
                        curve: Curves.easeOut)
                    .fadeOut(delay: 200.ms, duration: 320.ms),
                Image.asset(_Gf.confetti, width: cell * 2.6)
                    .animate(key: ValueKey('cf$id'))
                    .scaleXY(
                        begin: 0.5,
                        end: 1.1,
                        duration: 440.ms,
                        curve: Curves.easeOut)
                    .fadeOut(delay: 280.ms, duration: 360.ms),
                Image.asset(_Gf.burst, width: cell * 2.0)
                    .animate(key: ValueKey('bu$id'))
                    .scaleXY(
                        begin: 0.4,
                        end: 1.0,
                        duration: 300.ms,
                        curve: Curves.easeOut)
                    .fadeOut(delay: 150.ms, duration: 260.ms),
                if (combo >= 4)
                  Image.asset(_Gf.spark, width: cell * 2.4)
                      .animate(key: ValueKey('sk$id'))
                      .fadeIn(duration: 110.ms)
                      .scaleXY(
                          begin: 0.6,
                          end: 1.1,
                          duration: 320.ms,
                          curve: Curves.easeOut)
                      .fadeOut(delay: 200.ms, duration: 260.ms),
                Image.asset(_Gf.reveal, width: cell * 1.12)
                    .animate(key: ValueKey('rv$id'))
                    .scaleXY(
                        begin: 1.6,
                        end: 1.0,
                        duration: 320.ms,
                        curve: Curves.easeOutBack)
                    .fadeIn(duration: 120.ms)
                    .then(delay: 220.ms)
                    .fadeOut(duration: 300.ms),
                Image.asset(_Gf.sparkle, width: cell * 0.95)
                    .animate(key: ValueKey('sp$id'))
                    .scaleXY(
                        begin: 0.2,
                        end: 1.0,
                        duration: 320.ms,
                        curve: Curves.easeOutBack)
                    .then(delay: 120.ms)
                    .fadeOut(duration: 240.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A diagonal shimmer that sweeps across the board roughly every 3.5s, hidden
/// between sweeps.
class _ShimmerSweep extends StatefulWidget {
  const _ShimmerSweep();

  @override
  State<_ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<_ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3500))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        if (v >= 0.36) return const SizedBox.shrink();
        final p = v / 0.36; // 0..1 across the board
        return Align(
          alignment: Alignment(p * 3.0 - 1.5, 0),
          child: Opacity(
            opacity: math.sin(p * math.pi) * 0.45,
            child: Transform.rotate(
              angle: 0.3,
              child: Image.asset(_Gf.shimmer, height: 520, fit: BoxFit.fitHeight),
            ),
          ),
        );
      },
    );
  }
}

/// "LEVEL UP!" banner that slides in, holds, then slides out — once per level.
class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(_Gf.levelUp, width: 280)
          .animate(key: ValueKey('lvl$id'))
          .slideX(
              begin: -1.6, end: 0, duration: 460.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms)
          .then(delay: 760.ms)
          .slideX(begin: 0, end: 1.6, duration: 420.ms, curve: Curves.easeIn)
          .fadeOut(duration: 300.ms),
    );
  }
}

/// Ambient background: soft light rays, a faint grid-line glow, drifting orbs
/// and twinkling stars. Sits behind the board, never intercepts taps.
class _AmbientLayer extends StatelessWidget {
  const _AmbientLayer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(_Gf.rays,
                    width: width * 0.9, fit: BoxFit.fitWidth),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(_Gf.gridGlow, width: width),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(_Gf.orbs, fit: BoxFit.cover)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                        begin: -8,
                        end: 10,
                        duration: 5200.ms,
                        curve: Curves.easeInOut),
              ),
            ),
            Positioned.fill(
              child: Image.asset(_Gf.stars, fit: BoxFit.cover)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(
                      begin: 0.25,
                      end: 0.6,
                      duration: 2400.ms,
                      curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }
}
