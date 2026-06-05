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
    setState(() => _swap(index));
    if (_isSolved()) {
      registerCorrect(
        points: (c) =>
            (25 * (1 + c ~/ 2) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || finished) return;
        setState(_newBoard);
      });
    }
  }

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
                    Text(L('Trượt ô để xếp đúng thứ tự', 'Slide tiles into order'),
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
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _n * _n,
                        itemBuilder: (context, i) {
                          final value = _tiles[i];
                          if (value == _blankValue) {
                            return const SizedBox.shrink();
                          }
                          return _Tile(
                            number: value + 1,
                            onTap: () => _tap(i),
                          );
                        },
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
                icon: Icons.grid_4x4_rounded,
                stats: [
                  ResultStat(L('Giải', 'Solved'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                ],
                onRetry: () {
                  setState(_newBoard);
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

class _Tile extends StatelessWidget {
  const _Tile({required this.number, required this.onTap});
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.logic.withValues(alpha: 0.3),
              AppPalette.logic.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppPalette.logic.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text('$number',
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            )),
      ),
    );
  }
}
