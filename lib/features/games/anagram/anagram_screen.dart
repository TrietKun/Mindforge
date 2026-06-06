import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  void _tap(int index) {
    if (finished) return;
    final letter = _letters[index];
    if (letter.used) return;
    final expected = _word.substring(_matched, _matched + 1);
    if (letter.char == expected) {
      setState(() {
        letter.used = true;
        _matched++;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.language, AppPalette.reaction],
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
                    Text(L('Sắp xếp chữ cái thành từ đúng', 'Arrange the letters into the word'),
                        style: TextStyle(
                            color: AppPalette.textSecondary, fontSize: 15)),
                    const SizedBox(height: Insets.lg),
                    // Answer slots
                    Row(
                      key: ValueKey('a$_boardId'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _word.length; i++)
                          Container(
                            width: 48,
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i < _matched
                                  ? _accent.withValues(alpha: 0.18)
                                  : AppPalette.surface,
                              borderRadius: BorderRadius.circular(Radii.md),
                              border: Border.all(
                                  color: i < _matched
                                      ? _accent
                                      : AppPalette.stroke),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              i < _matched
                                  ? _word.substring(i, i + 1)
                                  : '',
                              style: const TextStyle(
                                  color: AppPalette.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Letter chips
                    Wrap(
                      key: ValueKey('c$_boardId'),
                      alignment: WrapAlignment.center,
                      spacing: Insets.sm,
                      runSpacing: Insets.sm,
                      children: [
                        for (var i = 0; i < _letters.length; i++)
                          _LetterChip(
                            letter: _letters[i],
                            accent: _accent,
                            onTap: () => _tap(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: Insets.lg),
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
                icon: Icons.abc_rounded,
                stats: [
                  ResultStat(L('Từ đúng', 'Words'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                ],
                onRetry: () {
                  setState(_newWord);
                  startSession();
                },
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.letter,
    required this.accent,
    required this.onTap,
  });
  final _Letter letter;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: letter.used ? null : onTap,
      child: AnimatedOpacity(
        opacity: letter.used ? 0.25 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppPalette.surfaceHigh,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(letter.char,
              style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
