import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/session/timed_session.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/quiz_top_bar.dart';
import '../../../shared/widgets/result_overlay.dart';

const _words3 = [
  'SUS', 'CAP', 'MID', 'XAO', 'XIN', 'PHE', 'GHE', 'XUI', 'MET', 'HEN',
  'HET', 'QUO', 'TRA', 'BOC', 'QUA', 'NEM', 'DZO', 'LOL', 'OMG', 'NAH',
  'YAS', 'BET', 'YUP', 'ICK', 'BRO', 'SIS', 'FAM', 'UWU', 'OOF', 'RIP',
];

const _words4 = [
  'GATO', 'SIMP', 'FLEX', 'NOOB', 'COPE', 'RAGE', 'MEME', 'LMAO', 'BRUH', 'YOLO',
  'SWAG', 'DRIP', 'GOAT', 'VIBE', 'RIZZ', 'GYAT', 'OHIO', 'SALT', 'CRAP', 'DERP',
  'PHET', 'DINH', 'GHET', 'BANH', 'CUOI', 'KHOC', 'QUAO', 'PHOT', 'HONG', 'CHAN',
  'DZUI', 'QUAU', 'CHAO', 'NHAU', 'RUOU', 'KEKW', 'POGG', 'COOL', 'DANK', 'STAN',
];

const _words5 = [
  'TOXIC', 'DRAMA', 'TOANG', 'SALTY', 'CHILL', 'CRUSH', 'GHIEN', 'SIMPS', 'NOOBS', 'VIBES',
  'GOATS', 'SUSSY', 'BASED', 'SLAYS', 'YIKES', 'SHOOK', 'DRIPS', 'POGGS', 'COPES', 'RAGES',
  'MEMES', 'NGHEO', 'KHOAI', 'THICH', 'SADGE', 'SWAGG', 'BRUHH', 'RIZZZ', 'STANS', 'DANKS',
];

/// Asset paths for the Anagram sprite + FX pack.
class _A {
  static const dir = 'assets/games/anagram';
  static const letterTile = '$dir/letter_tile.png';
  static const letterLocked = '$dir/letter_locked.png';
  static const slot = '$dir/slot.png';
  static const boardFrame = '$dir/board_frame.png';
  static const undo = '$dir/undo_icon.png';
  static const book = '$dir/book_icon.png';
  static const bgLetters = '$dir/bg_letters.png';
  static const owl = '$dir/owl_mascot.png';
  static const trophy = '$dir/trophy.png';
  static const wordSolved = '$dir/word_solved.png';
  static const halo = '$dir/halo.png';
  static const burst = '$dir/burst.png';
  static const confetti = '$dir/confetti.png';
  static const spark = '$dir/spark.png';
  static const ring = '$dir/ring.png';
  static const popRing = '$dir/pop_ring.png';
  static const shimmer = '$dir/shimmer.png';
  static const sparkle = '$dir/sparkle.png';
  static const check = '$dir/check.png';
  static const cross = '$dir/cross.png';
}

class _Letter {
  _Letter(this.char);
  final String char;
  bool used = false;
}

class AnagramScreen extends StatefulWidget {
  const AnagramScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<AnagramScreen> createState() => _AnagramScreenState();
}

class _AnagramScreenState extends State<AnagramScreen> with TimedSessionMixin {
  static const Color _accent = AppPalette.language;

  final _rng = math.Random();
  String _word = '';
  List<_Letter> _letters = [];
  int _matched = 0;
  int _boardId = 0;

  // ── FX state (additive — never changes the unscramble / scoring logic) ─────
  int _placeFxId = 0;
  int _wrongFxId = 0;
  int _tapFxId = 0;
  int _comboFxId = 0;
  int _solvedFxId = 0;
  Offset _tapPos = Offset.zero;
  final GlobalKey _slotsKey = GlobalKey();

  @override
  double get sessionSeconds => 55;

  List<String> get _pool => switch (widget.difficulty) {
        Difficulty.easy => _words3,
        Difficulty.medium => _words4,
        Difficulty.hard => _words5,
      };

  @override
  void initState() {
    super.initState();
    _newWord();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _newWord() {
    final pool = _pool;
    _word = pool[_rng.nextInt(pool.length)];
    final chars = _word.split('');
    do {
      chars.shuffle(_rng);
    } while (chars.join() == _word && _word.length > 1);
    _letters = chars.map(_Letter.new).toList();
    _matched = 0;
    _boardId++;
  }

  /// Centre of the answer-slots row in the FX layer's coordinate space.
  Offset _slotsCenter() {
    final box = _slotsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final s = MediaQuery.of(context).size;
      return Offset(s.width / 2, s.height * 0.36);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _onPointerDown(Offset pos) {
    if (finished) return;
    setState(() {
      _tapPos = pos;
      _tapFxId++; // ripple at every tap
    });
  }

  /// Undo the last placed letter (additive — does not touch the match logic).
  void _undo() {
    if (finished || _matched == 0) return;
    setState(() {
      _matched--;
      final ch = _word.substring(_matched, _matched + 1);
      for (final l in _letters) {
        if (l.used && l.char == ch) {
          l.used = false;
          break;
        }
      }
    });
  }

  void _tap(int index) {
    if (finished) return;
    final letter = _letters[index];
    if (letter.used) return;
    final expected = _word.substring(_matched, _matched + 1);
    if (letter.char == expected) {
      setState(() {
        letter.used = true;
        _matched++;
        _placeFxId++; // FX: letter snapped into a slot
      });
      if (_matched == _word.length) {
        registerCorrect(
          points: (c) => (10 *
                  _word.length *
                  (1 + c ~/ 3) *
                  widget.difficulty.scoreMultiplier)
              .round(),
          flashColor: _accent.withValues(alpha: 0.14),
        );
        setState(() {
          _solvedFxId++; // FX: burst + check + WORD SOLVED banner
          if (combo > 0 && combo % 3 == 0) _comboFxId++;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted || finished) return;
          setState(_newWord);
        });
      }
    } else {
      registerWrong(
        penalty: 1.5,
        flashColor: AppPalette.danger.withValues(alpha: 0.18),
      );
      setState(() => _wrongFxId++); // FX: cross at the tap
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        child: AuroraBackground(
          blobs: const [AppPalette.language, AppPalette.reaction],
          child: Stack(
            children: [
              // ambient floating letters
              Positioned.fill(
                child: IgnorePointer(
                  child: _Glow(
                    child: Opacity(
                      opacity: 0.07,
                      child: Image.asset(_A.bgLetters,
                              fit: BoxFit.cover, alignment: Alignment.center)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: -10, end: 10, duration: 6000.ms, curve: Curves.easeInOut),
                    ),
                  ),
                ),
              ),
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
                      _Header(),
                      const SizedBox(height: Insets.lg),
                      // answer slots
                      Row(
                        key: _slotsKey,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _word.length; i++)
                            _Slot(
                              key: ValueKey('s$_boardId-$i'),
                              filled: i < _matched,
                              char: i < _matched ? _word.substring(i, i + 1) : '',
                            ),
                        ],
                      ),
                      const SizedBox(height: Insets.sm),
                      // undo
                      GestureDetector(
                        onTap: _undo,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedOpacity(
                          opacity: _matched > 0 ? 1 : 0.3,
                          duration: const Duration(milliseconds: 160),
                          child: Image.asset(_A.undo, width: 40, height: 40),
                        ),
                      ),
                      const Spacer(),
                      // letter chips inside the framed board
                      Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              _A.boardFrame,
                              fit: BoxFit.fill,
                              centerSlice: const Rect.fromLTRB(40, 36, 192, 98),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(Insets.lg),
                            child: Wrap(
                              key: ValueKey('c$_boardId'),
                              alignment: WrapAlignment.center,
                              spacing: Insets.sm,
                              runSpacing: Insets.sm,
                              children: [
                                for (var i = 0; i < _letters.length; i++)
                                  _LetterChip(
                                    key: ValueKey('$_boardId-$i'),
                                    letter: _letters[i],
                                    delayMs: i * 50,
                                    onTap: () => _tap(i),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: _fxLayer()),
                ),
              ),
              if (finished) ...[
                ResultOverlay(
                  title: L('Hết giờ!', 'Time up!'),
                  score: score,
                  scoreSuffix: L('điểm', 'pts'),
                  accent: _accent,
                  iconAsset: _A.trophy,
                  icon: Icons.abc_rounded,
                  stats: [
                    ResultStat(L('Từ đúng', 'Words'), '$hits'),
                    ResultStat('Combo', 'x$bestCombo'),
                  ],
                  onRetry: () {
                    setState(() {
                      _placeFxId = 0;
                      _wrongFxId = 0;
                      _tapFxId = 0;
                      _comboFxId = 0;
                      _solvedFxId = 0;
                      _newWord();
                    });
                    startSession();
                  },
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                // owl mascot presiding over the result card
                Align(
                  alignment: const Alignment(0, -0.62),
                  child: IgnorePointer(
                    child: Image.asset(_A.owl, width: 88)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: -4, end: 4, duration: 2200.ms, curve: Curves.easeInOut),
                  ),
                ),
              ],
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
        if (_tapFxId > 0)
          _Spot(
            center: _tapPos,
            child: _Glow(
              child: Image.asset(_A.popRing, width: 84)
                  .animate(key: ValueKey('pr$_tapFxId'))
                  .scaleXY(begin: 0.3, end: 1.3, duration: 400.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 130.ms, duration: 260.ms),
            ),
          ),
        if (_placeFxId > 0)
          _Spot(
            center: _tapPos,
            child: _Glow(
              child: Image.asset(_A.sparkle, width: 58)
                  .animate(key: ValueKey('pl$_placeFxId'))
                  .scaleXY(begin: 0.2, end: 1, duration: 300.ms, curve: Curves.easeOutBack)
                  .then(delay: 100.ms)
                  .fadeOut(duration: 220.ms),
            ),
          ),
        if (_wrongFxId > 0)
          _Spot(
            center: _tapPos,
            child: Image.asset(_A.cross, width: 50)
                .animate(key: ValueKey('x$_wrongFxId'))
                .fadeIn(duration: 90.ms)
                .scaleXY(begin: 1.5, end: 1, duration: 240.ms, curve: Curves.easeOutBack)
                .then(delay: 220.ms)
                .fadeOut(duration: 240.ms),
          ),
        if (_solvedFxId > 0) ...[
          _Spot(
            center: _slotsCenter(),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _Glow(
                  child: Image.asset(_A.confetti, width: 240)
                      .animate(key: ValueKey('cf$_solvedFxId'))
                      .scaleXY(begin: 0.5, end: 1.1, duration: 520.ms, curve: Curves.easeOut)
                      .fadeOut(delay: 320.ms, duration: 420.ms),
                ),
                _Glow(
                  child: Image.asset(_A.burst, width: 180)
                      .animate(key: ValueKey('bu$_solvedFxId'))
                      .scaleXY(begin: 0.4, end: 1.1, duration: 340.ms, curve: Curves.easeOut)
                      .fadeOut(delay: 200.ms, duration: 300.ms),
                ),
                _Glow(
                  child: Image.asset(_A.ring, width: 150)
                      .animate(key: ValueKey('rg$_solvedFxId'))
                      .scaleXY(begin: 0.4, end: 1.3, duration: 440.ms, curve: Curves.easeOut)
                      .fadeOut(delay: 180.ms, duration: 300.ms),
                ),
                Image.asset(_A.check, width: 56)
                    .animate(key: ValueKey('ck$_solvedFxId'))
                    .scaleXY(begin: 0.3, end: 1, duration: 320.ms, curve: Curves.easeOutBack)
                    .then(delay: 220.ms)
                    .fadeOut(duration: 240.ms),
              ],
            ),
          ),
          // WORD SOLVED banner slides down over the slots
          Align(
            alignment: const Alignment(0, -0.18),
            child: Image.asset(_A.wordSolved, width: 220)
                .animate(key: ValueKey('ws$_solvedFxId'))
                .slideY(begin: -0.6, end: 0, duration: 320.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 200.ms)
                .then(delay: 360.ms)
                .fadeOut(duration: 300.ms)
                .slideY(begin: 0, end: -0.3, duration: 300.ms),
          ),
        ],
        if (_comboFxId > 0) ...[
          Align(
            alignment: Alignment.center,
            child: _Glow(
              child: Image.asset(_A.shimmer,
                      width: MediaQuery.of(context).size.width * 1.2,
                      fit: BoxFit.fitWidth)
                  .animate(key: ValueKey('sh$_comboFxId'))
                  .slideX(begin: -1.4, end: 1.4, duration: 760.ms, curve: Curves.easeInOut),
            ),
          ),
          _Spot(
            center: _slotsCenter(),
            child: _Glow(
              child: Image.asset(_A.spark, width: 200)
                  .animate(key: ValueKey('sp$_comboFxId'))
                  .fadeIn(duration: 110.ms)
                  .scaleXY(begin: 0.6, end: 1.15, duration: 340.ms)
                  .fadeOut(delay: 200.ms, duration: 280.ms),
            ),
          ),
        ],
      ],
    );
  }
}

/// Additively composites a glow sprite (screen blend) so its black backdrop
/// only adds light and never darkens what's behind it. No clip → scaled FX kept.
class _Glow extends SingleChildRenderObjectWidget {
  const _Glow({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _GlowBox();
}

class _GlowBox extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.canvas.saveLayer(null, Paint()..blendMode = BlendMode.screen);
    context.paintChild(child, offset);
    context.canvas.restore();
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

/// Book icon + pulsing halo beside the instruction.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _Glow(
                child: Image.asset(_A.halo, width: 58)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.85, end: 1.12, duration: 1400.ms)
                    .fade(begin: 0.45, end: 0.85, duration: 1400.ms),
              ),
              Image.asset(_A.book, width: 42, height: 42, fit: BoxFit.contain)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -2, end: 2, duration: 2200.ms, curve: Curves.easeInOut),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            L('Sắp xếp chữ cái thành từ đúng', 'Arrange the letters into the word'),
            style: const TextStyle(color: AppPalette.textSecondary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// An answer slot — empty (dashed) or filled (amber locked tile + letter).
class _Slot extends StatelessWidget {
  const _Slot({super.key, required this.filled, required this.char});
  final bool filled;
  final String char;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              filled ? _A.letterLocked : _A.slot,
              fit: filled ? BoxFit.fill : BoxFit.contain,
            ),
          ),
          if (filled)
            Text(
              char,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ).animate(key: ValueKey('sc$char$filled')).scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 240.ms,
                curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

/// A draggable source letter rendered on the dark glassy tile.
class _LetterChip extends StatefulWidget {
  const _LetterChip({
    super.key,
    required this.letter,
    required this.delayMs,
    required this.onTap,
  });
  final _Letter letter;
  final int delayMs;
  final VoidCallback onTap;

  @override
  State<_LetterChip> createState() => _LetterChipState();
}

class _LetterChipState extends State<_LetterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));

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
      onTap: widget.letter.used ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: widget.letter.used ? 0.22 : 1,
        duration: const Duration(milliseconds: 160),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(_A.letterTile, fit: BoxFit.fill),
              ),
              Text(
                widget.letter.char,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final e = Curves.easeOutBack.transform(_enter.value.clamp(0, 1));
        return Opacity(
          opacity: _enter.value.clamp(0, 1),
          child: Transform.scale(scale: 0.5 + 0.5 * e, child: child),
        );
      },
      child: face,
    );
  }
}
