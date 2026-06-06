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

/// Asset paths for the Trail Maker FX overhaul.
class _Tm {
  static const dir = 'assets/games/trail_maker';
  static const orb = '$dir/node_orb.png';
  static const nextGlow = '$dir/next_glow.png';
  static const comet = '$dir/comet.png';
  static const owl = '$dir/owl_mascot.png';
  static const streaks = '$dir/streaks.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const popRing = '$dir/pop_ring.png';
  static const spark = '$dir/spark.png';
  static const sparkle = '$dir/sparkle.png';
  static const check = '$dir/check.png';
  static const cross = '$dir/cross.png';
  static const levelUp = '$dir/level_up.png';
  static const trophy = '$dir/trophy.png';
  static const orbs = '$dir/orbs.png';
  static const stars = '$dir/stars.png';
  static const rays = '$dir/rays.png';
}

class TrailMakerScreen extends StatefulWidget {
  const TrailMakerScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<TrailMakerScreen> createState() => _TrailMakerScreenState();
}

class _TrailMakerScreenState extends State<TrailMakerScreen>
    with TimedSessionMixin, TickerProviderStateMixin {
  static const Color _accent = AppPalette.focus;

  final _rng = math.Random();
  int _n = 6;
  int _next = 1;
  List<Offset> _positions = [];
  int _boardId = 0;

  // ── FX state (additive — never changes scoring / ramp) ────────────────────
  int _correctFxId = 0;
  int _wrongFxId = 0;
  int _completeFxId = 0;
  int _levelUpId = 0;
  Offset _correctPos = Offset.zero;
  Offset _wrongPos = Offset.zero;
  Offset _completePos = Offset.zero;

  late final AnimationController _segCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  late final AnimationController _dashCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();
  late final AnimationController _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 340));
  late final AnimationController _flashCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 640));

  @override
  double get sessionSeconds => 60;

  int get _startN => switch (widget.difficulty) {
        Difficulty.easy => 6,
        Difficulty.medium => 9,
        Difficulty.hard => 12,
      };

  @override
  void initState() {
    super.initState();
    _n = _startN;
    _newBoard();
    startSession();
  }

  @override
  void dispose() {
    _segCtrl.dispose();
    _dashCtrl.dispose();
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _newBoard() {
    final cols = math.sqrt(_n).ceil();
    final rows = (_n / cols).ceil();
    final cells = [for (var i = 0; i < cols * rows; i++) i]..shuffle(_rng);
    _positions = List.generate(_n, (i) {
      final cell = cells[i];
      final c = cell % cols;
      final r = cell ~/ cols;
      final jx = (_rng.nextDouble() - 0.5) * 0.5;
      final jy = (_rng.nextDouble() - 0.5) * 0.5;
      return Offset(
        ((c + 0.5 + jx) / cols).clamp(0.08, 0.92),
        ((r + 0.5 + jy) / rows).clamp(0.08, 0.92),
      );
    });
    _next = 1;
    _boardId++;
    _segCtrl.value = 1;
  }

  void _tap(int number) {
    if (finished) return;
    if (number == _next) {
      _correctPos = _positions[number - 1];
      registerCorrect(
        points: (c) =>
            (6 * (1 + c ~/ 5) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.10),
      );
      setState(() {
        _correctFxId++;
        _next++;
      });
      _segCtrl.forward(from: 0); // "draw" the new segment + run the comet
      if (_next > _n) {
        _completePos = _positions[_n - 1];
        setState(() {
          _completeFxId++;
          _levelUpId++;
        });
        _flashCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted || finished) return;
          setState(() {
            _n = math.min(16, _n + 1);
            _newBoard();
          });
        });
      }
    } else {
      _wrongPos = _positions[number - 1];
      registerWrong(
        penalty: 1.0,
        flashColor: AppPalette.danger.withValues(alpha: 0.16),
      );
      _shakeCtrl.forward(from: 0);
      setState(() => _wrongFxId++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.focus, AppPalette.logic],
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
                      const SizedBox(height: Insets.sm),
                      _Header(next: _next),
                      const SizedBox(height: Insets.md),
                      Expanded(child: _board()),
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
                iconAsset: _Tm.trophy,
                icon: Icons.timeline_rounded,
                stats: [
                  ResultStat(L('Chạm đúng', 'Hits'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                ],
                onRetry: () {
                  setState(() {
                    _n = _startN;
                    _correctFxId = 0;
                    _wrongFxId = 0;
                    _completeFxId = 0;
                    _levelUpId = 0;
                    _newBoard();
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

  Widget _board() {
    return Container(
      key: ValueKey(_boardId),
      decoration: BoxDecoration(
        color: AppPalette.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppPalette.stroke),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
          final pts = [for (final p in _positions) px(p)];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // glowing trail (below the nodes)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_segCtrl, _dashCtrl, _flashCtrl]),
                    builder: (context, _) => CustomPaint(
                      painter: _TrailPainter(
                        points: pts,
                        connected: _next - 1,
                        segProgress: _segCtrl.value,
                        dashPhase: _dashCtrl.value,
                        flash: _flashCtrl.value,
                        color: _accent,
                      ),
                    ),
                  ),
                ),
              ),
              // nodes
              for (var i = 0; i < _n; i++)
                Positioned(
                  left: pts[i].dx - 26,
                  top: pts[i].dy - 26,
                  child: _Node(
                    key: ValueKey('$_boardId-${i + 1}'),
                    number: i + 1,
                    done: (i + 1) < _next,
                    isNext: (i + 1) == _next,
                    delayMs: i * 40,
                    onTap: () => _tap(i + 1),
                  ),
                ),
              // FX overlay (comet, pop ring, sparkle, burst, confetti, cross)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: _fx(size)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fx(Size size) {
    Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    final correct = px(_correctPos);
    final wrong = px(_wrongPos);
    final complete = px(_completePos);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // comet running along the segment currently being drawn
        AnimatedBuilder(
          animation: _segCtrl,
          builder: (context, child) {
            final connected = _next - 1;
            final v = _segCtrl.value;
            if (connected < 2 || v <= 0 || v >= 1) {
              return const SizedBox.shrink();
            }
            final a = px(_positions[_next - 3]);
            final b = px(_positions[_next - 2]);
            final p = Offset.lerp(a, b, v)!;
            return Positioned(
              left: p.dx - 17,
              top: p.dy - 17,
              child: Image.asset(_Tm.comet, width: 34),
            );
          },
        ),
        if (_correctFxId > 0)
          _Spot(
            id: _correctFxId,
            center: correct,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(_Tm.popRing, width: 96)
                    .animate(key: ValueKey('pr$_correctFxId'))
                    .scaleXY(begin: 0.4, end: 1.4, duration: 460.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 160.ms, duration: 300.ms),
                if (combo >= 5)
                  Image.asset(_Tm.spark, width: 120)
                      .animate(key: ValueKey('sk$_correctFxId'))
                      .fadeIn(duration: 100.ms)
                      .scaleXY(begin: 0.6, end: 1.1, duration: 320.ms)
                      .fadeOut(delay: 180.ms, duration: 240.ms),
                Image.asset(_Tm.sparkle, width: 54)
                    .animate(key: ValueKey('sp$_correctFxId'))
                    .scaleXY(begin: 0.2, end: 1, duration: 320.ms, curve: Curves.easeOutBack)
                    .then(delay: 110.ms)
                    .fadeOut(duration: 220.ms),
              ],
            ),
          ),
        if (_wrongFxId > 0)
          _Spot(
            id: _wrongFxId,
            center: wrong,
            child: Image.asset(_Tm.cross, width: 44)
                .animate(key: ValueKey('x$_wrongFxId'))
                .fadeIn(duration: 90.ms)
                .scaleXY(begin: 1.5, end: 1, duration: 240.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .fadeOut(duration: 240.ms),
          ),
        if (_completeFxId > 0)
          _Spot(
            id: _completeFxId,
            center: complete,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(_Tm.confetti, width: 220)
                    .animate(key: ValueKey('cf$_completeFxId'))
                    .scaleXY(begin: 0.5, end: 1.2, duration: 520.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 320.ms, duration: 420.ms),
                Image.asset(_Tm.burst, width: 180)
                    .animate(key: ValueKey('bu$_completeFxId'))
                    .scaleXY(begin: 0.4, end: 1.1, duration: 360.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 200.ms, duration: 300.ms),
              ],
            ),
          ),
      ],
    );
  }
}

/// Positions [child] centred on [center] within the board, replayed when [id]
/// changes (so the keyed entrance animation restarts).
class _Spot extends StatelessWidget {
  const _Spot({required this.id, required this.center, required this.child});
  final int id;
  final Offset center;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - 130,
      top: center.dy - 130,
      width: 260,
      height: 260,
      child: Center(child: child),
    );
  }
}

/// Owl mascot beside the running instruction.
class _Header extends StatelessWidget {
  const _Header({required this.next});
  final int next;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(_Tm.owl, width: 40, height: 40, fit: BoxFit.contain)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -2, end: 2, duration: 2200.ms, curve: Curves.easeInOut),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            L('Chạm theo thứ tự — tiếp theo: $next',
                'Tap in order — next: $next'),
            style: const TextStyle(color: AppPalette.textSecondary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatefulWidget {
  const _Node({
    super.key,
    required this.number,
    required this.done,
    required this.isNext,
    required this.delayMs,
    required this.onTap,
  });
  final int number;
  final bool done;
  final bool isNext;
  final int delayMs;
  final VoidCallback onTap;

  @override
  State<_Node> createState() => _NodeState();
}

class _NodeState extends State<_Node> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _enterTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _enter.forward();
    });
    if (widget.isNext) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Node old) {
    super.didUpdateWidget(old);
    if (widget.isNext && !old.isNext) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isNext && old.isNext) {
      _pulse.stop();
      _pulse.value = 0;
    }
    if (widget.done && !old.done) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enter.dispose();
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orb = SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.isNext)
            Image.asset(_Tm.nextGlow, width: 74, height: 74),
          // glow halo so the node reads clearly over the ambient background
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppPalette.focus
                      .withValues(alpha: widget.done ? 0.2 : 0.45),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Opacity(
            opacity: widget.done ? 0.62 : 1,
            child: Image.asset(_Tm.orb, width: 52, height: 52),
          ),
          Text(
            '${widget.number}',
            style: TextStyle(
              color: widget.done ? AppPalette.textMuted : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
          if (widget.done)
            Positioned(
              right: 2,
              bottom: 2,
              child: Image.asset(_Tm.check, width: 20),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _pulse, _pop]),
        builder: (context, child) {
          final e = Curves.easeOutBack.transform(_enter.value.clamp(0, 1));
          final enterScale = 0.3 + 0.7 * e;
          final pulse = widget.isNext ? 1 + 0.08 * _pulse.value : 1.0;
          final pop = 1 + 0.24 * math.sin(_pop.value * math.pi);
          return Opacity(
            opacity: _enter.value.clamp(0, 1),
            child: Transform.scale(scale: enterScale * pulse * pop, child: child),
          );
        },
        child: orb,
      ),
    );
  }
}

/// Paints the glowing connection trail through the tapped nodes: a blurred halo
/// + a bright core + flowing dashes, with the latest segment drawn to
/// [segProgress] and a whole-trail brighten on [flash] (board complete).
class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.connected,
    required this.segProgress,
    required this.dashPhase,
    required this.flash,
    required this.color,
  });

  final List<Offset> points;
  final int connected;
  final double segProgress;
  final double dashPhase;
  final double flash;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (connected < 1 || points.length < connected) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < connected - 1; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (connected >= 2) {
      final a = points[connected - 2], b = points[connected - 1];
      final tip = Offset.lerp(a, b, segProgress.clamp(0, 1))!;
      path.lineTo(tip.dx, tip.dy);
    }

    final halo = Paint()
      ..color = color.withValues(alpha: 0.35 + 0.45 * flash)
      ..strokeWidth = 13 + 10 * flash
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..blendMode = BlendMode.screen;
    canvas.drawPath(path, halo);

    final core = Paint()
      ..color = Color.lerp(color, Colors.white, 0.55 + 0.4 * flash)!
      ..strokeWidth = 3.5 + 2 * flash
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.screen;
    canvas.drawPath(path, core);

    // flowing bright dashes
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.screen;
    const dashLen = 9.0, gap = 24.0;
    const period = dashLen + gap;
    for (final metric in path.computeMetrics()) {
      var d = -dashPhase * period;
      while (d < metric.length) {
        final s = math.max(0.0, d);
        final e = math.min(metric.length, d + dashLen);
        if (e > s) canvas.drawPath(metric.extractPath(s, e), dash);
        d += period;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.connected != connected ||
      old.segProgress != segProgress ||
      old.dashPhase != dashPhase ||
      old.flash != flash;
}

/// "LEVEL UP!" banner that slides in, holds, then slides out — once per board.
class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(_Tm.levelUp, width: 280)
          .animate(key: ValueKey('lvl$id'))
          .slideX(begin: -1.6, end: 0, duration: 460.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms)
          .then(delay: 760.ms)
          .slideX(begin: 0, end: 1.6, duration: 420.ms, curve: Curves.easeIn)
          .fadeOut(duration: 300.ms),
    );
  }
}

/// Ambient background: drifting orbs, flowing light streaks, twinkling stars and
/// soft light rays behind the board.
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
                child: Image.asset(_Tm.rays,
                    width: width * 0.9, fit: BoxFit.fitWidth),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(_Tm.streaks, fit: BoxFit.cover)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: -10, end: 12, duration: 6000.ms, curve: Curves.easeInOut),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(_Tm.orbs, fit: BoxFit.cover)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -8, end: 10, duration: 5200.ms, curve: Curves.easeInOut),
              ),
            ),
            Positioned.fill(
              child: Image.asset(_Tm.stars, fit: BoxFit.cover)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.25, end: 0.6, duration: 2400.ms, curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }
}
