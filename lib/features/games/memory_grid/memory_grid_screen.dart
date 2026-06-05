import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/result_overlay.dart';
import 'memory_grid_game.dart';

class MemoryGridScreen extends StatefulWidget {
  const MemoryGridScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<MemoryGridScreen> createState() => _MemoryGridScreenState();
}

class _MemoryGridScreenState extends State<MemoryGridScreen> {
  late MemoryGridGame _game;
  MemoryStats? _result;

  @override
  void initState() {
    super.initState();
    _game = _build();
  }

  MemoryGridGame _build() => MemoryGridGame(
        difficulty: widget.difficulty,
        onFinished: (stats) => setState(() => _result = stats),
      );

  int get _maxLives => switch (widget.difficulty) {
        Difficulty.easy => 4,
        Difficulty.medium => 3,
        Difficulty.hard => 2,
      };

  void _restart() => setState(() {
        _result = null;
        _game = _build();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.memory, AppPalette.focus],
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            SafeArea(
              child: ValueListenableBuilder<MemoryStats>(
                valueListenable: _game.stats,
                builder: (context, stats, _) => Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          _Pill(
                            label: L('Vòng', 'Round'),
                            value: '${stats.round}',
                            color: AppPalette.memory,
                          ),
                          const SizedBox(width: Insets.sm),
                          _Pill(
                            label: L('Điểm', 'Score'),
                            value: '${stats.score}',
                            color: AppPalette.focus,
                          ),
                          const Spacer(),
                          _Lives(lives: stats.lives, maxLives: _maxLives),
                        ],
                      ),
                      const SizedBox(height: Insets.md),
                      _StatusBanner(status: stats.status),
                    ],
                  ),
                ),
              ),
            ),
            if (_result != null)
              ResultOverlay(
                title: L('Hết lượt!', 'Game over!'),
                score: _result!.score,
                scoreSuffix: L('điểm', 'pts'),
                accent: AppPalette.memory,
                iconAsset: 'assets/games/memory_grid/trophy.png',
                icon: Icons.psychology_rounded,
                stats: [
                  ResultStat(L('Vòng đạt', 'Rounds'), '${_result!.round - 1}'),
                  ResultStat(L('Điểm', 'Score'), '${_result!.score}'),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final MemoryStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (status) {
      MemoryStatus.watch => (
          L('Ghi nhớ thứ tự...', 'Memorize the order...'),
          AppPalette.memory,
          Icons.visibility_rounded
        ),
      MemoryStatus.repeat => (
          L('Lặp lại đi!', 'Repeat it!'),
          AppPalette.success,
          Icons.touch_app_rounded
        ),
      MemoryStatus.over => (L('Kết thúc', 'Finished'), AppPalette.danger, Icons.flag_rounded),
      MemoryStatus.intro => (L('Sẵn sàng', 'Ready'), AppPalette.textMuted, Icons.bolt),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(status),
        padding:
            const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: Insets.sm),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ).animate(key: ValueKey(status)).fadeIn().slideY(begin: -0.3),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Row(
        children: [
          Text('$label ',
              style: const TextStyle(
                  color: AppPalette.textMuted, fontSize: 12)),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Lives extends StatelessWidget {
  const _Lives({required this.lives, required this.maxLives});
  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final active = i < lives;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: active ? AppPalette.danger : AppPalette.textMuted,
            size: 20,
          ),
        );
      }),
    );
  }
}
