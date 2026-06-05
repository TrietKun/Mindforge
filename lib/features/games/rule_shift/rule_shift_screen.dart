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

const _shapes = [
  Icons.circle,
  Icons.square_rounded,
  Icons.change_history_rounded,
  Icons.star_rounded,
];
const _colors = [
  AppPalette.danger,
  AppPalette.focus,
  AppPalette.logic,
  AppPalette.gold,
];

enum _Rule { color, shape }

class RuleShiftScreen extends StatefulWidget {
  const RuleShiftScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<RuleShiftScreen> createState() => _RuleShiftScreenState();
}

class _RuleShiftScreenState extends State<RuleShiftScreen>
    with TimedSessionMixin {
  static const Color _accent = AppPalette.flexibility;

  final _rng = math.Random();
  late _Rule _rule;
  int _shape = 0;
  int _color = 0;
  int _roundId = 0;
  int? _wrongIndex;

  @override
  double get sessionSeconds => 35;

  ({double flip, double penalty}) get _tune => switch (widget.difficulty) {
        Difficulty.easy => (flip: 0.3, penalty: 1.0),
        Difficulty.medium => (flip: 0.5, penalty: 1.5),
        Difficulty.hard => (flip: 0.7, penalty: 2.0),
      };

  @override
  void initState() {
    super.initState();
    _rule = _rng.nextBool() ? _Rule.color : _Rule.shape;
    _next(first: true);
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _next({bool first = false}) {
    if (!first && _rng.nextDouble() < _tune.flip) {
      _rule = _rule == _Rule.color ? _Rule.shape : _Rule.color;
    }
    _shape = _rng.nextInt(4);
    _color = _rng.nextInt(4);
    _roundId++;
  }

  int get _answer => _rule == _Rule.color ? _color : _shape;

  void _tap(int index) {
    if (finished) return;
    if (index == _answer) {
      registerCorrect(
        points: (c) =>
            (10 * (1 + c ~/ 4) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      setState(() {
        _wrongIndex = null;
        _next();
      });
    } else {
      registerWrong(
        penalty: _tune.penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() => _wrongIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byColor = _rule == _Rule.color;
    final ruleColor = byColor ? AppPalette.gold : AppPalette.flexibility;
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.flexibility, AppPalette.focus],
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
                    Container(
                      key: ValueKey(_rule),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.lg, vertical: Insets.md),
                      decoration: BoxDecoration(
                        color: ruleColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border:
                            Border.all(color: ruleColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        byColor ? L('Phân loại theo MÀU', 'Sort by COLOR') : L('Phân loại theo HÌNH', 'Sort by SHAPE'),
                        style: TextStyle(
                          color: ruleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                        .animate(key: ValueKey(_rule))
                        .fadeIn(duration: 180.ms)
                        .scale(
                            begin: const Offset(0.85, 0.85),
                            curve: Curves.easeOutBack)
                        .shake(hz: 4, rotation: 0.01),
                    const SizedBox(height: Insets.xl),
                    Icon(_shapes[_shape], color: _colors[_color], size: 110)
                        .animate(key: ValueKey(_roundId))
                        .fadeIn(duration: 160.ms)
                        .scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOutBack),
                    const Spacer(),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: Insets.sm,
                      crossAxisSpacing: Insets.sm,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < 4; i++)
                          _Choice(
                            byColor: byColor,
                            index: i,
                            isWrong: _wrongIndex == i,
                            onTap: () => _tap(i),
                          ),
                      ],
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
                iconAsset: 'assets/kit/trophy_pink.png',
                icon: Icons.rule_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                  ResultStat(L('Chính xác', 'Accuracy'), '$accuracy%'),
                ],
                onRetry: () {
                  setState(() {
                    _rule = _rng.nextBool() ? _Rule.color : _Rule.shape;
                    _next(first: true);
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

class _Choice extends StatelessWidget {
  const _Choice({
    required this.byColor,
    required this.index,
    required this.isWrong,
    required this.onTap,
  });
  final bool byColor;
  final int index;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cell = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isWrong
                ? AppPalette.danger
                : AppPalette.flexibility.withValues(alpha: 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: byColor
            ? Container(
                width: 30,
                height: 30,
                decoration:
                    BoxDecoration(color: _colors[index], shape: BoxShape.circle),
              )
            : Icon(_shapes[index], color: AppPalette.textSecondary, size: 30),
      ),
    );
    if (isWrong) {
      return cell.animate().shake(hz: 4, rotation: 0.02, duration: 300.ms);
    }
    return cell;
  }
}
