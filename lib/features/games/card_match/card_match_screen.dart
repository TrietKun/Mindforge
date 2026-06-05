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

const _faces = <(IconData, Color)>[
  (Icons.star_rounded, AppPalette.gold),
  (Icons.favorite_rounded, AppPalette.danger),
  (Icons.bolt_rounded, AppPalette.reaction),
  (Icons.pets_rounded, AppPalette.logic),
  (Icons.music_note_rounded, AppPalette.focus),
  (Icons.rocket_launch_rounded, AppPalette.memory),
  (Icons.local_florist_rounded, AppPalette.flexibility),
  (Icons.ac_unit_rounded, AppPalette.math),
];

// Card-face sprites (null → fall back to the icon above).
const _faceSprites = <String?>[
  'assets/kit/card_star.png',
  'assets/kit/card_heart.png',
  'assets/kit/card_bolt.png',
  'assets/kit/card_paw.png',
  'assets/kit/card_music.png',
  'assets/kit/card_rocket.png',
  null,
  null,
];
const _cardBack = 'assets/kit/card_back.png';

class _Card {
  _Card(this.faceId);
  final int faceId;
  bool up = false;
  bool matched = false;
}

class CardMatchScreen extends StatefulWidget {
  const CardMatchScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<CardMatchScreen> createState() => _CardMatchScreenState();
}

class _CardMatchScreenState extends State<CardMatchScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.memory;

  final _rng = math.Random();
  List<_Card> _cards = [];
  int _firstUp = -1;
  bool _busy = false;
  int _pairs = 6;
  int _boardId = 0;

  @override
  double get sessionSeconds => 70;

  int get _startPairs => switch (widget.difficulty) {
        Difficulty.easy => 4,
        Difficulty.medium => 6,
        Difficulty.hard => 8,
      };

  @override
  void initState() {
    super.initState();
    _pairs = _startPairs;
    _newBoard();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _newBoard() {
    final faceIds = List.generate(_pairs, (i) => i % _faces.length);
    _cards = [...faceIds, ...faceIds].map(_Card.new).toList()..shuffle(_rng);
    _firstUp = -1;
    _busy = false;
    _boardId++;
  }

  void _tap(int i) {
    if (finished || _busy) return;
    final card = _cards[i];
    if (card.up || card.matched) return;

    setState(() => card.up = true);
    if (_firstUp == -1) {
      _firstUp = i;
      return;
    }

    final a = _firstUp;
    _firstUp = -1;
    if (_cards[a].faceId == card.faceId) {
      setState(() {
        _cards[a].matched = true;
        card.matched = true;
      });
      registerCorrect(
        points: (c) => (14 * (1 + c ~/ 3) * widget.difficulty.scoreMultiplier)
            .round(),
        flashColor: _accent.withValues(alpha: 0.12),
      );
      if (_cards.every((c) => c.matched)) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted || finished) return;
          setState(() {
            _pairs = math.min(8, _pairs + 1);
            _newBoard();
          });
        });
      }
    } else {
      _busy = true;
      registerWrong(flashColor: AppPalette.danger.withValues(alpha: 0.12));
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _cards[a].up = false;
          card.up = false;
          _busy = false;
        });
      });
    }
  }

  void _restart() {
    setState(() {
      _pairs = _startPairs;
      _newBoard();
    });
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    final cols = _cards.length <= 12 ? 4 : 4;
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.memory, AppPalette.flexibility],
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
                    const SizedBox(height: Insets.lg),
                    Text(L('Lật tìm các cặp giống nhau', 'Flip to find matching pairs'),
                        style: TextStyle(
                            color: AppPalette.textSecondary, fontSize: 15)),
                    const SizedBox(height: Insets.md),
                    Expanded(
                      child: Center(
                        child: GridView.builder(
                          key: ValueKey(_boardId),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: Insets.sm,
                            crossAxisSpacing: Insets.sm,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _cards.length,
                          itemBuilder: (context, i) => _CardTile(
                            card: _cards[i],
                            onTap: () => _tap(i),
                          ),
                        ),
                      ),
                    ),
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
                iconAsset: 'assets/kit/trophy_purple.png',
                icon: Icons.style_rounded,
                stats: [
                  ResultStat(L('Cặp', 'Pairs'), '$hits'),
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

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onTap});
  final _Card card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = _faces[card.faceId];
    final sprite = _faceSprites[card.faceId];
    final revealed = card.up || card.matched;

    final Widget child;
    if (!revealed) {
      // Face-down → card-back sprite.
      child = Padding(
        padding: const EdgeInsets.all(3),
        child: Image.asset(_cardBack, fit: BoxFit.contain),
      );
    } else if (sprite != null) {
      // Revealed with a card sprite.
      child = Opacity(
        opacity: card.matched ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Image.asset(sprite, fit: BoxFit.contain),
        ),
      );
    } else {
      // Fallback for faces without a sprite.
      child = DecoratedBox(
        decoration: BoxDecoration(
          color: face.$2.withValues(alpha: card.matched ? 0.10 : 0.18),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: face.$2.withValues(alpha: 0.6)),
        ),
        child: Center(
          child: Icon(face.$1,
              color: face.$2.withValues(alpha: card.matched ? 0.6 : 1),
              size: 30),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: child,
    ).animate(target: revealed ? 1 : 0).scaleXY(
        begin: 1, end: 1.04, duration: 120.ms, curve: Curves.easeOut);
  }
}
