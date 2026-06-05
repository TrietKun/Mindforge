import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import 'animated_counter.dart';
import 'app_buttons.dart';

/// Close button + animated score + combo chip + countdown bar — the standard
/// header for the timed quiz games.
class QuizTopBar extends StatelessWidget {
  const QuizTopBar({
    super.key,
    required this.score,
    required this.combo,
    required this.progress,
    required this.accent,
    required this.onClose,
  });

  final int score;
  final int combo;
  final double progress;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            RoundIconButton(icon: Icons.close_rounded, onTap: onClose),
            const Spacer(),
            AnimatedCounter(
              value: score,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: accent),
            ),
            const Spacer(),
            ComboChip(combo: combo, accent: accent),
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
              Color.lerp(AppPalette.danger, accent, progress)!,
            ),
          ),
        ),
      ],
    );
  }
}

class ComboChip extends StatelessWidget {
  const ComboChip({super.key, required this.combo, required this.accent});

  final int combo;
  final Color accent;

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
              ? LinearGradient(colors: [accent, AppPalette.gold])
              : null,
          color: active ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'x$combo',
          style: TextStyle(
            color: active ? Colors.black : AppPalette.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .scaleXY(begin: 1, end: 1.1, duration: 130.ms);
  }
}
