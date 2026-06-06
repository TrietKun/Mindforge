import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/result_overlay.dart';
import '../../../shared/widgets/tutorial_overlay.dart';
import 'reaction_tap_game.dart';

class ReactionTapScreen extends StatefulWidget {
  const ReactionTapScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<ReactionTapScreen> createState() => _ReactionTapScreenState();
}

class _ReactionTapScreenState extends State<ReactionTapScreen> {
  late ReactionTapGame _game;
  GameStats? _result;

  @override
  void initState() {
    super.initState();
    _game = _build();
  }

  ReactionTapGame _build() => ReactionTapGame(
        difficulty: widget.difficulty,
        onFinished: (stats) => setState(() => _result = stats),
      );

  void _restart() {
    setState(() {
      _result = null;
      _game = _build();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppPalette.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            SafeArea(
              child: ValueListenableBuilder<GameStats>(
                valueListenable: _game.stats,
                builder: (context, stats, _) => _Hud(
                  stats: stats,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            if (_result != null)
              ResultOverlay(
                title: L('Hoàn thành!', 'Complete!'),
                score: _result!.score,
                scoreSuffix: L('điểm', 'pts'),
                accent: AppPalette.reaction,
                iconAsset: 'assets/games/reaction_tap/trophy.png',
                stats: [
                  ResultStat('Combo', 'x${_result!.bestCombo}'),
                  ResultStat(L('Chính xác', 'Accuracy'), '${_result!.accuracy}%'),
                  ResultStat(L('Trúng', 'Hits'), '${_result!.hits}'),
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

class _Hud extends StatelessWidget {
  const _Hud({required this.stats, required this.onClose});

  final GameStats stats;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final progress =
        (stats.timeLeft / GameStats.kSessionSeconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(icon: Icons.close_rounded, onTap: onClose),
              const SizedBox(width: 8),
              const TutorialButton(),
              const Spacer(),
              _ScorePill(score: stats.score),
              const Spacer(),
              _ComboBadge(combo: stats.combo),
            ],
          ),
          const SizedBox(height: Insets.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppPalette.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(
                Color.lerp(AppPalette.danger, AppPalette.reaction, progress)!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: AnimatedCounter(
        value: score,
        duration: const Duration(milliseconds: 280),
        style: Theme.of(context)
            .textTheme
            .headlineSmall!
            .copyWith(color: AppPalette.textPrimary),
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    final active = combo >= 2;
    return AnimatedOpacity(
      opacity: active ? 1 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppPalette.reaction, AppPalette.gold])
              : null,
          color: active ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'x$combo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: active ? Colors.black : AppPalette.textMuted,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .scaleXY(begin: 1, end: 1.12, duration: 140.ms)
        .then()
        .scaleXY(begin: 1.12, end: 1, duration: 140.ms);
  }
}
