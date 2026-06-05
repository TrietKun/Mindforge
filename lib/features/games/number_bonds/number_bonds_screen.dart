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

class NumberBondsScreen extends StatefulWidget {
  const NumberBondsScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<NumberBondsScreen> createState() => _NumberBondsScreenState();
}

class _NumberBondsScreenState extends State<NumberBondsScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.math;

  final _rng = math.Random();
  int _target = 10;
  List<int> _numbers = [];
  int _selected = -1;
  int _boardId = 0;

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
      setState(_newBoard);
    } else {
      registerWrong(
        penalty: 1.5,
        flashColor: AppPalette.danger.withValues(alpha: 0.18),
      );
      setState(() => _selected = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.math, AppPalette.logic],
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
                    Text(L('Chọn 2 số cộng lại bằng', 'Pick two numbers that sum to'),
                        style: TextStyle(
                            color: AppPalette.textSecondary, fontSize: 15)),
                    const SizedBox(height: Insets.md),
                    Text('$_target',
                            style: const TextStyle(
                                color: AppPalette.math,
                                fontSize: 64,
                                fontWeight: FontWeight.w900))
                        .animate(key: ValueKey('t$_boardId'))
                        .scale(
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.easeOutBack),
                    const Spacer(),
                    GridView.builder(
                      key: ValueKey('g$_boardId'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: Insets.md,
                        crossAxisSpacing: Insets.md,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _numbers.length,
                      itemBuilder: (context, i) => _Chip(
                        value: _numbers[i],
                        selected: _selected == i,
                        onTap: () => _tap(i),
                      ),
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
                iconAsset: 'assets/kit/trophy_cyan.png',
                icon: Icons.join_full_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.math.withValues(alpha: 0.25)
              : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? AppPalette.math : AppPalette.stroke,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text('$value',
            style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
