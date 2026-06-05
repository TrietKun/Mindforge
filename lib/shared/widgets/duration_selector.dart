import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/difficulty.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// Segmented control with a sliding, color-shifting highlight pill bound to the
/// app-wide [GameSettings.duration] (play-time length).
class DurationSelector extends StatelessWidget {
  const DurationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameDuration>(
      valueListenable: GameSettings.duration,
      builder: (context, current, _) {
        final alignment = switch (current) {
          GameDuration.short => Alignment.centerLeft,
          GameDuration.normal => Alignment.center,
          GameDuration.long => Alignment.centerRight,
        };
        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppPalette.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: AppPalette.stroke),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: alignment,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          current.color,
                          Color.lerp(current.color, AppPalette.gold, 0.35)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Radii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: current.color.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final duration in GameDuration.values)
                    Expanded(
                      child: _Segment(
                        duration: duration,
                        selected: duration == current,
                        onTap: () {
                          if (duration == current) return;
                          HapticFeedback.selectionClick();
                          GameSettings.duration.value = duration;
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final GameDuration duration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              duration.icon,
              size: 16,
              color: selected ? Colors.black : AppPalette.textMuted,
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected ? Colors.black : AppPalette.textSecondary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
              child: Text(duration.label),
            ),
          ],
        ),
      ),
    );
  }
}
