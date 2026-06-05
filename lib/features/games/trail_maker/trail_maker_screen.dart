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

class TrailMakerScreen extends StatefulWidget {
  const TrailMakerScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<TrailMakerScreen> createState() => _TrailMakerScreenState();
}

class _TrailMakerScreenState extends State<TrailMakerScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.focus;

  final _rng = math.Random();
  int _n = 6;
  int _next = 1;
  List<Offset> _positions = [];
  int _boardId = 0;

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
  }

  void _tap(int number) {
    if (finished) return;
    if (number == _next) {
      registerCorrect(
        points: (c) =>
            (6 * (1 + c ~/ 5) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.10),
      );
      setState(() => _next++);
      if (_next > _n) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted || finished) return;
          setState(() {
            _n = math.min(16, _n + 1);
            _newBoard();
          });
        });
      }
    } else {
      registerWrong(
        penalty: 1.0,
        flashColor: AppPalette.danger.withValues(alpha: 0.16),
      );
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
                    const SizedBox(height: Insets.sm),
                    Text(L('Chạm theo thứ tự — tiếp theo: $_next', 'Tap in order — next: $_next'),
                        style: const TextStyle(
                            color: AppPalette.textSecondary, fontSize: 15)),
                    const SizedBox(height: Insets.md),
                    Expanded(
                      child: Container(
                        key: ValueKey(_boardId),
                        decoration: BoxDecoration(
                          color: AppPalette.surface.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(Radii.lg),
                          border: Border.all(color: AppPalette.stroke),
                        ),
                        child: Stack(
                          children: [
                            for (var i = 0; i < _n; i++)
                              Align(
                                alignment: Alignment(
                                  _positions[i].dx * 2 - 1,
                                  _positions[i].dy * 2 - 1,
                                ),
                                child: _Node(
                                  number: i + 1,
                                  done: (i + 1) < _next,
                                  isNext: (i + 1) == _next,
                                  onTap: () => _tap(i + 1),
                                ),
                              ),
                          ],
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
                iconAsset: 'assets/kit/trophy_blue.png',
                icon: Icons.timeline_rounded,
                stats: [
                  ResultStat(L('Chạm đúng', 'Hits'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                ],
                onRetry: () {
                  setState(() {
                    _n = _startN;
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
}

class _Node extends StatelessWidget {
  const _Node({
    required this.number,
    required this.done,
    required this.isNext,
    required this.onTap,
  });
  final int number;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? AppPalette.focus.withValues(alpha: 0.25)
              : AppPalette.surfaceHigh,
          border: Border.all(
            color: isNext ? AppPalette.focus : AppPalette.stroke,
            width: isNext ? 2 : 1,
          ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: AppPalette.focus.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text('$number',
            style: TextStyle(
              color: done ? AppPalette.textMuted : AppPalette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            )),
      ),
    );
  }
}
