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

/// Asset paths for the Sliding Puzzle sprite + FX pack.
class _Sp {
  static const dir = 'assets/games/sliding_puzzle';
  static const tile = '$dir/tile.png';
  static const tileCorrect = '$dir/tile_correct.png';
  static const emptySlot = '$dir/empty_slot.png';
  static const frame = '$dir/board_frame.png';
  static const icon = '$dir/puzzle_icon.png';
  static const owl = '$dir/owl_mascot.png';
  static const trophy = '$dir/trophy.png';
  static const slideStreak = '$dir/slide_streak.png';
  static const snapRing = '$dir/snap_ring.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const solvedGlow = '$dir/solved_glow.png';
  static const sparkle = '$dir/sparkle.png';
  static const orbs = '$dir/orbs.png';
  static const gridGlow = '$dir/grid_glow.png';
  static const stars = '$dir/stars.png';
  static const rays = '$dir/rays.png';
}

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.logic;

  final _rng = math.Random();
  late int _n; // grid dimension
  late List<int> _tiles; // values 0..n*n-1, last value is the blank
  int _blank = 0;
  int _moves = 0;
  int _boardId = 0;

  // ── FX state (additive — never changes shuffle / move / scoring) ──────────
  int _solvedFxId = 0;
  int _slideFxId = 0;
  Offset _slidePos = Offset.zero; // normalised cell centre of the moved tile
  bool _slideVertical = false;

  @override
  double get sessionSeconds => 90;

  int get _blankValue => _n * _n - 1;

  @override
  void initState() {
    super.initState();
    _n = widget.difficulty == Difficulty.hard ? 4 : 3;
    _newBoard();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _newBoard() {
    _tiles = [for (var i = 0; i < _n * _n; i++) i];
    _blank = _tiles.indexOf(_blankValue);
    // Scramble with valid moves to guarantee solvability.
    final shuffles = 60 + widget.difficulty.index * 30;
    for (var i = 0; i < shuffles; i++) {
      final moves = _movableIndices();
      _swap(moves[_rng.nextInt(moves.length)], record: false);
    }
    if (_isSolved()) _swap(_movableIndices().first, record: false);
    _moves = 0;
    _boardId++;
  }

  List<int> _movableIndices() {
    final r = _blank ~/ _n;
    final c = _blank % _n;
    final result = <int>[];
    if (r > 0) result.add(_blank - _n);
    if (r < _n - 1) result.add(_blank + _n);
    if (c > 0) result.add(_blank - 1);
    if (c < _n - 1) result.add(_blank + 1);
    return result;
  }

  void _swap(int index, {bool record = true}) {
    _tiles[_blank] = _tiles[index];
    _tiles[index] = _blankValue;
    _blank = index;
    if (record) _moves++;
  }

  bool _isSolved() {
    for (var i = 0; i < _tiles.length; i++) {
      if (_tiles[i] != i) return false;
    }
    return true;
  }

  void _tap(int index) {
    if (finished) return;
    if (!_movableIndices().contains(index)) return;
    final dest = _blank; // tile slides into the current blank cell
    setState(() {
      _slideVertical = (index - dest).abs() == _n;
      _slidePos = Offset(
        (dest % _n + 0.5) / _n,
        (dest ~/ _n + 0.5) / _n,
      );
      _slideFxId++;
      _swap(index);
    });
    if (_isSolved()) {
      registerCorrect(
        points: (c) =>
            (25 * (1 + c ~/ 2) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      setState(() => _solvedFxId++);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || finished) return;
        setState(_newBoard);
      });
    }
  }

  int _entranceDelay(int idx) => ((idx ~/ _n) + (idx % _n)) * 35;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.logic, AppPalette.memory],
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            const Positioned.fill(child: _AmbientLayer()),
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
                    const _Header(),
                    const SizedBox(height: Insets.lg),
                    _board(),
                    const SizedBox(height: Insets.md),
                    Text(L('Nước đi: $_moves', 'Moves: $_moves'),
                        style: const TextStyle(color: AppPalette.textMuted)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: _Sp.trophy,
                icon: Icons.grid_4x4_rounded,
                stats: [
                  ResultStat(L('Giải', 'Solved'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                ],
                onRetry: () {
                  setState(() {
                    _solvedFxId = 0;
                    _slideFxId = 0;
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
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, cons) {
          final boardSize = cons.maxWidth;
          final inset = boardSize * 0.055;
          final size = boardSize - 2 * inset;
          const gap = 6.0;
          final cell = (size - gap * (_n - 1)) / _n;
          Offset cellOf(int idx) => Offset(
                (idx % _n) * (cell + gap),
                (idx ~/ _n) * (cell + gap),
              );
          final pos = List.filled(_n * _n, 0);
          for (var i = 0; i < _tiles.length; i++) {
            pos[_tiles[i]] = i;
          }
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(_Sp.frame, fit: BoxFit.fill)
                    .animate(key: ValueKey('frame$_boardId'))
                    .fadeIn(duration: 320.ms),
              ),
              Positioned(
                left: inset,
                top: inset,
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var idx = 0; idx < _n * _n; idx++)
                      Positioned(
                        left: cellOf(idx).dx,
                        top: cellOf(idx).dy,
                        width: cell,
                        height: cell,
                        child: Image.asset(_Sp.emptySlot, fit: BoxFit.fill),
                      ),
                    for (var v = 0; v < _blankValue; v++)
                      AnimatedPositioned(
                        key: ValueKey('$_boardId-$v'),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        left: cellOf(pos[v]).dx,
                        top: cellOf(pos[v]).dy,
                        width: cell,
                        height: cell,
                        child: _Tile(
                          number: v + 1,
                          correct: pos[v] == v,
                          delayMs: _entranceDelay(pos[v]),
                          onTap: () => _tap(pos[v]),
                        ),
                      ),
                    // slide motion-streak along the move direction
                    if (_slideFxId > 0)
                      Positioned(
                        left: _slidePos.dx * size - cell * 0.75,
                        top: _slidePos.dy * size - cell * 0.75,
                        width: cell * 1.5,
                        height: cell * 1.5,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: _slideVertical ? math.pi / 2 : 0,
                            child: Image.asset(_Sp.slideStreak, fit: BoxFit.contain)
                                .animate(key: ValueKey('sl$_slideFxId'))
                                .fadeIn(duration: 60.ms)
                                .fadeOut(delay: 90.ms, duration: 200.ms),
                          ),
                        ),
                      ),
                    // board-solved celebration
                    if (_solvedFxId > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(_Sp.solvedGlow, fit: BoxFit.contain)
                                    .animate(key: ValueKey('sg$_solvedFxId'))
                                    .fadeIn(duration: 160.ms)
                                    .scaleXY(begin: 0.9, end: 1.05, duration: 420.ms)
                                    .fadeOut(delay: 260.ms, duration: 340.ms),
                                Image.asset(_Sp.confetti, width: size * 0.9)
                                    .animate(key: ValueKey('scf$_solvedFxId'))
                                    .scaleXY(begin: 0.5, end: 1.1, duration: 520.ms, curve: Curves.easeOut)
                                    .fadeOut(delay: 320.ms, duration: 420.ms),
                                Image.asset(_Sp.burst, width: size * 0.7)
                                    .animate(key: ValueKey('sb$_solvedFxId'))
                                    .scaleXY(begin: 0.4, end: 1.1, duration: 360.ms, curve: Curves.easeOut)
                                    .fadeOut(delay: 220.ms, duration: 300.ms),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Puzzle icon + owl beside the running instruction.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(_Sp.icon, width: 38, height: 38, fit: BoxFit.contain)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.96, end: 1.06, duration: 1400.ms, curve: Curves.easeInOut)
            .moveY(begin: -2, end: 2, duration: 2200.ms, curve: Curves.easeInOut),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            L('Trượt ô để xếp đúng thứ tự', 'Slide tiles into order'),
            style: const TextStyle(color: AppPalette.textSecondary, fontSize: 15),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(_Sp.owl, width: 40, height: 40, fit: BoxFit.contain)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -2, end: 2, duration: 2400.ms, curve: Curves.easeInOut),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.number,
    required this.correct,
    required this.delayMs,
    required this.onTap,
  });
  final int number;
  final bool correct;
  final int delayMs;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));
  late final AnimationController _snap = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _enterTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void didUpdateWidget(_Tile old) {
    super.didUpdateWidget(old);
    if (widget.correct && !old.correct) _snap.forward(from: 0);
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enter.dispose();
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            widget.correct ? _Sp.tileCorrect : _Sp.tile,
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${widget.number}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
        // snap "lock in place" flash when the tile reaches its solved cell
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _snap,
              builder: (context, _) {
                final v = _snap.value;
                if (v <= 0 || v >= 1) return const SizedBox.shrink();
                final fade = (1 - v).clamp(0.0, 1.0);
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: fade,
                      child: Transform.scale(
                        scale: 1.5 - 0.5 * Curves.easeOut.transform(v),
                        child: Image.asset(_Sp.snapRing, fit: BoxFit.contain),
                      ),
                    ),
                    Opacity(
                      opacity: fade,
                      child: Transform.scale(
                        scale: 0.4 + 0.8 * v,
                        child: Image.asset(_Sp.sparkle, width: 26),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, child) {
          final e = Curves.easeOutBack.transform(_enter.value.clamp(0, 1));
          return Opacity(
            opacity: _enter.value.clamp(0, 1),
            child: Transform.scale(scale: 0.3 + 0.7 * e, child: child),
          );
        },
        child: face,
      ),
    );
  }
}

/// Ambient background: drifting orbs, a faint moving grid glow, twinkling stars
/// and soft light rays behind the board.
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
                child: Image.asset(_Sp.rays,
                    width: width * 0.9, fit: BoxFit.fitWidth),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(_Sp.gridGlow, width: width),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(_Sp.orbs, fit: BoxFit.cover)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -8, end: 10, duration: 5200.ms, curve: Curves.easeInOut),
              ),
            ),
            Positioned.fill(
              child: Image.asset(_Sp.stars, fit: BoxFit.cover)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.25, end: 0.6, duration: 2400.ms, curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }
}
