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

enum GridFindMode { symbol, hue }

const _glyphs = ['◆', '●', '▲', '★', '✦', '❤', '♠', '♣', '✚', '⬟'];

class GridFindScreen extends StatefulWidget {
  const GridFindScreen({
    super.key,
    required this.mode,
    this.difficulty = Difficulty.medium,
  });

  final GridFindMode mode;
  final Difficulty difficulty;

  @override
  State<GridFindScreen> createState() => _GridFindScreenState();
}

class _GridFindScreenState extends State<GridFindScreen> with TimedSessionMixin {
  static const Color _accent = AppPalette.focus;

  final _rng = math.Random();
  int _grid = 3;
  int _oddIndex = 0;
  int _roundId = 0;
  int? _wrongIndex;

  // symbol mode
  String _baseGlyph = '◆';
  String _oddGlyph = '●';
  // hue mode
  Color _baseColor = AppPalette.focus;
  Color _oddColor = AppPalette.memory;

  @override
  double get sessionSeconds => 45;

  String get _instruction => widget.mode == GridFindMode.symbol
      ? L('Tìm ký hiệu KHÁC BIỆT', 'Find the ODD symbol')
      : L('Tìm ô KHÁC MÀU', 'Find the ODD color');

  double get _penalty => switch (widget.difficulty) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.5,
        Difficulty.hard => 2.0,
      };

  @override
  void initState() {
    super.initState();
    _build();
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _build() {
    _grid = (3 + hits ~/ 5).clamp(3, 5);
    final count = _grid * _grid;
    _oddIndex = _rng.nextInt(count);

    if (widget.mode == GridFindMode.symbol) {
      _baseGlyph = _glyphs[_rng.nextInt(_glyphs.length)];
      do {
        _oddGlyph = _glyphs[_rng.nextInt(_glyphs.length)];
      } while (_oddGlyph == _baseGlyph);
    } else {
      final hue = _rng.nextDouble() * 360;
      final delta = switch (widget.difficulty) {
            Difficulty.easy => 42.0,
            Difficulty.medium => 24.0,
            Difficulty.hard => 12.0,
          } -
          hits * 0.4;
      _baseColor =
          HSLColor.fromAHSL(1, hue, 0.65, 0.6).toColor();
      _oddColor = HSLColor.fromAHSL(
              1, (hue + math.max(6, delta)) % 360, 0.65, 0.6)
          .toColor();
    }
    _roundId++;
  }

  void _tap(int index) {
    if (finished) return;
    if (index == _oddIndex) {
      registerCorrect(
        points: (c) =>
            ((6 + _grid) * (1 + c ~/ 4) * widget.difficulty.scoreMultiplier)
                .round(),
        flashColor: _accent.withValues(alpha: 0.12),
      );
      setState(() {
        _wrongIndex = null;
        _build();
      });
    } else {
      registerWrong(
        penalty: _penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.18),
      );
      setState(() => _wrongIndex = index);
    }
  }

  void _restart() {
    setState(() {
      _wrongIndex = null;
      _build();
    });
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.focus, AppPalette.memory],
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
                    Text(_instruction,
                        style: const TextStyle(
                            color: AppPalette.textSecondary,
                            fontSize: 15,
                            letterSpacing: 0.5)),
                    const SizedBox(height: Insets.lg),
                    AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        key: ValueKey(_roundId),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _grid,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _grid * _grid,
                        itemBuilder: (context, i) {
                          final isOdd = i == _oddIndex;
                          return _Cell(
                            mode: widget.mode,
                            glyph: isOdd ? _oddGlyph : _baseGlyph,
                            color: isOdd ? _oddColor : _baseColor,
                            isWrong: _wrongIndex == i,
                            onTap: () => _tap(i),
                          );
                        },
                      ).animate(key: ValueKey(_roundId)).fadeIn(duration: 220.ms),
                    ),
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
                iconAsset: 'assets/kit/trophy_blue.png',
                icon: Icons.center_focus_strong_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
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

class _Cell extends StatelessWidget {
  const _Cell({
    required this.mode,
    required this.glyph,
    required this.color,
    required this.isWrong,
    required this.onTap,
  });

  final GridFindMode mode;
  final String glyph;
  final Color color;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cell = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: mode == GridFindMode.hue ? color : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isWrong ? AppPalette.danger : AppPalette.stroke,
          ),
        ),
        alignment: Alignment.center,
        child: mode == GridFindMode.symbol
            ? Text(glyph,
                style: const TextStyle(
                    color: AppPalette.focus, fontSize: 26))
            : null,
      ),
    );
    if (isWrong) {
      return cell.animate().shake(hz: 4, rotation: 0.02, duration: 300.ms);
    }
    return cell;
  }
}
