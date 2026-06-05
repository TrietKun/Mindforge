import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/i18n/app_lang.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import 'animated_counter.dart';
import 'app_buttons.dart';

class ResultStat {
  const ResultStat(this.label, this.value);
  final String label;
  final String value;
}

/// Generic end-of-session card shared by every game, with a confetti burst,
/// a glowing icon ring, and a counting-up score.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.title,
    required this.score,
    required this.scoreSuffix,
    required this.stats,
    required this.accent,
    required this.onRetry,
    required this.onClose,
    this.icon = Icons.emoji_events_rounded,
    this.iconAsset,
  });

  final String title;
  final int score;
  final String scoreSuffix;
  final List<ResultStat> stats;
  final Color accent;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final IconData icon;

  /// Optional image (e.g. a trophy sprite) shown instead of [icon].
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Colors.black.withValues(alpha: 0.5))
              .animate()
              .fadeIn(duration: 220.ms),
          Positioned.fill(child: Confetti(colors: [accent, AppPalette.gold])),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(Insets.lg),
                padding: const EdgeInsets.all(Insets.xl),
                decoration: BoxDecoration(
                  color: AppPalette.backgroundElevated.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: AppPalette.stroke),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconRing(icon: icon, accent: accent, iconAsset: iconAsset),
                    const SizedBox(height: Insets.md),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: Insets.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCounter(
                          value: score,
                          duration: const Duration(milliseconds: 900),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .copyWith(color: accent, fontSize: 44),
                        ),
                        const SizedBox(width: 6),
                        Text(scoreSuffix,
                            style: const TextStyle(
                                color: AppPalette.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                    const SizedBox(height: Insets.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < stats.length; i++)
                          _StatCell(stat: stats[i], delayMs: 260 + i * 90),
                      ],
                    ),
                    const SizedBox(height: Insets.xl),
                    Row(
                      children: [
                        Expanded(
                            child: GhostButton(
                                label: L('Thoát', 'Exit'), onTap: onClose)),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: L('Chơi lại', 'Play again'),
                            onTap: onRetry,
                            colors: [accent, AppPalette.gold],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 240.ms)
                  .scale(
                      begin: const Offset(0.86, 0.86),
                      curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({required this.icon, required this.accent, this.iconAsset});
  final IconData icon;
  final Color accent;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            accent,
            AppPalette.gold,
            accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppPalette.backgroundElevated,
        ),
        padding: iconAsset != null ? const EdgeInsets.all(14) : EdgeInsets.zero,
        child: iconAsset != null
            ? Image.asset(iconAsset!, fit: BoxFit.contain)
            : Icon(icon, color: AppPalette.gold, size: 44),
      ),
    )
        .animate()
        .scale(
            begin: const Offset(0.4, 0.4),
            curve: Curves.easeOutBack,
            duration: 500.ms)
        .then()
        .shake(hz: 3, rotation: 0.03);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat, required this.delayMs});
  final ResultStat stat;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(stat.value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppPalette.textPrimary)),
        const SizedBox(height: 2),
        Text(stat.label,
            style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
      ],
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.4, curve: Curves.easeOut);
  }
}

/// One-shot confetti burst from the top of the overlay.
class Confetti extends StatefulWidget {
  const Confetti({super.key, required this.colors});
  final List<Color> colors;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final List<_Confetto> _pieces;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final palette = [...widget.colors, AppPalette.success, AppPalette.memory];
    _pieces = List.generate(46, (i) {
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * 1.7;
      final speed = 0.6 + rng.nextDouble() * 0.9;
      return _Confetto(
        origin: Offset(0.5 + (rng.nextDouble() - 0.5) * 0.3, 0.18),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: palette[rng.nextInt(palette.length)],
        size: 5 + rng.nextDouble() * 6,
        spin: (rng.nextDouble() - 0.5) * 12,
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Confetto {
  _Confetto({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.phase,
  });
  final Offset origin; // normalized
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final double phase;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Confetto> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final px = p.origin.dx * size.width + p.velocity.dx * t * size.width;
      final py = p.origin.dy * size.height +
          p.velocity.dy * t * size.height * 0.5 +
          // gravity
          0.9 * t * t * size.height;
      final opacity = (1 - t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.spin * t + p.phase * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
