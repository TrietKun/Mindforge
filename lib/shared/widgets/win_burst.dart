import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A clean, shared "correct answer" celebration: a soft glow, one expanding
/// ring and a quick radial burst behind a focal [reveal], with a few corner
/// sparkles. A higher [combo] adds a single spark accent.
///
/// Deliberately restrained — no streaking comet / confetti / vortex pile-up —
/// so the revealed answer stays the clear centre of attention.
///
/// [dir] is an asset folder that must contain halo/ring_m/burst/spark/sparkle.
class WinBurst extends StatelessWidget {
  const WinBurst({
    super.key,
    required this.dir,
    required this.fxId,
    required this.combo,
    required this.reveal,
    this.alignment = Alignment.center,
  });

  final String dir;
  final int fxId;
  final int combo;
  final Widget reveal;
  final Alignment alignment;

  Widget _twinkle(Alignment at, double size, int delayMs) => Align(
        alignment: at,
        child: Image.asset('$dir/sparkle.png', width: size)
            .animate(key: ValueKey('tw$fxId-$at'))
            .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1, 1),
                delay: delayMs.ms,
                duration: 260.ms,
                curve: Curves.easeOutBack)
            .then()
            .fadeOut(duration: 220.ms),
      );

  @override
  Widget build(BuildContext context) {
    final strong = combo >= 3;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // soft glow swelling behind everything
              Image.asset('$dir/halo.png', width: 210)
                  .animate(key: ValueKey('halo$fxId'))
                  .fadeIn(duration: 140.ms)
                  .scaleXY(begin: 0.6, end: 1.15, duration: 380.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 300.ms, duration: 300.ms),
              // a single ring rippling outward
              Image.asset('$dir/ring_m.png', width: 132)
                  .animate(key: ValueKey('ring$fxId'))
                  .scaleXY(begin: 0.3, end: 1.7, duration: 560.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 220.ms, duration: 360.ms),
              // quick radial burst that clears before the reveal settles
              Image.asset('$dir/burst.png', width: 172)
                  .animate(key: ValueKey('burst$fxId'))
                  .scaleXY(begin: 0.4, end: 1.0, duration: 260.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 120.ms, duration: 240.ms),
              if (strong)
                Image.asset('$dir/spark.png', width: 228)
                    .animate(key: ValueKey('spark$fxId'))
                    .fadeIn(duration: 120.ms)
                    .scaleXY(begin: 0.5, end: 1.15, duration: 340.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 220.ms, duration: 260.ms),
              // the focal reveal (carries its own entrance animation)
              reveal,
              _twinkle(const Alignment(-0.72, -0.55), 46, 60),
              _twinkle(const Alignment(0.74, -0.38), 38, 150),
              _twinkle(const Alignment(0.52, 0.66), 42, 230),
            ],
          ),
        ),
      ),
    );
  }
}
