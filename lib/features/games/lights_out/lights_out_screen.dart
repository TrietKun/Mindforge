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

class LightsOutScreen extends StatefulWidget {
  const LightsOutScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<LightsOutScreen> createState() => _LightsOutScreenState();
}

class _LightsOutScreenState extends State<LightsOutScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.logic;

  final _rng = math.Random();
  late int _n;
  late List<bool> _grid;
  int _boardId = 0;
  int _moves = 0;

  @override
  double get sessionSeconds => 75;

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
    _grid = List.filled(_n * _n, false);
    final scrambles = 3 + hits ~/ 2 + widget.difficulty.index;
    do {
      for (var i = 0; i < scrambles; i++) {
        _toggle(_rng.nextInt(_n * _n), record: false);
      }
    } while (_grid.every((v) => !v)); // never start already solved
    _moves = 0;
    _boardId++;
  }

  void _toggle(int index, {bool record = true}) {
    final r = index ~/ _n;
    final c = index % _n;
    void flip(int rr, int cc) {
      if (rr < 0 || rr >= _n || cc < 0 || cc >= _n) return;
      _grid[rr * _n + cc] = !_grid[rr * _n + cc];
    }

    flip(r, c);
    flip(r - 1, c);
    flip(r + 1, c);
    flip(r, c - 1);
    flip(r, c + 1);
    if (record) _moves++;
  }

  void _tap(int index) {
    if (finished) return;
    setState(() => _toggle(index));
    if (_grid.every((v) => !v)) {
      registerCorrect(
        points: (c) =>
            (20 * (1 + c ~/ 3) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || finished) return;
        setState(_newBoard);
      });
    }
  }

  void _restart() {
    setState(_newBoard);
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.logic, AppPalette.focus],
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
                    Text(L('Tắt hết đèn — chạm đổi cả ô kề', 'Turn off all lights — a tap flips neighbors'),
                        style: TextStyle(
                            color: AppPalette.textSecondary, fontSize: 15)),
                    const SizedBox(height: Insets.lg),
                    AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        key: ValueKey(_boardId),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _n,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _n * _n,
                        itemBuilder: (context, i) => _Light(
                          on: _grid[i],
                          onTap: () => _tap(i),
                        ),
                      ),
                    ),
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
                iconAsset: 'assets/kit/trophy_green.png',
                icon: Icons.lightbulb_rounded,
                stats: [
                  ResultStat(L('Giải', 'Solved'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
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

class _Light extends StatelessWidget {
  const _Light({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: on ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 160),
        child: Image.asset(
          on ? 'assets/kit/bulb_on.png' : 'assets/kit/bulb_off.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
