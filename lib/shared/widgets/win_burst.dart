import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A clean, shared "correct answer" celebration: a soft glow, ONE expanding
/// ring and a quick burst behind a focal [reveal], with a ring of sparkles
/// orbiting (rotating) around the outside. A higher [combo] adds one spark.
///
/// Deliberately restrained and well-spaced — elements don't pile on top of each
/// other; the orbit lives at the edge so the revealed answer stays the centre
/// of attention.
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

  /// A ring of sparkles placed around the outside, gently rotating as a group
  /// while each one twinkles in — the "orbiting" flourish.
  Widget _orbit() {
    const n = 6;
    return SizedBox(
      width: 244,
      height: 244,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var k = 0; k < n; k++)
            Align(
              alignment: Alignment(
                math.cos(k * 2 * math.pi / n) * 0.98,
                math.sin(k * 2 * math.pi / n) * 0.98,
              ),
              child: Image.asset('$dir/sparkle.png', width: 30)
                  .animate(key: ValueKey('orb$fxId-$k'))
                  .scale(
                      begin: const Offset(0.1, 0.1),
                      end: const Offset(1, 1),
                      delay: (k * 45).ms,
                      duration: 260.ms,
                      curve: Curves.easeOutBack)
                  .then(delay: 80.ms)
                  .fadeOut(duration: 300.ms),
            ),
        ],
      ),
    )
        .animate(key: ValueKey('orbit$fxId'))
        .rotate(begin: 0, end: 0.18, duration: 880.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final strong = combo >= 3;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: 264,
          height: 264,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // soft glow swelling behind everything
              Image.asset('$dir/halo.png', width: 196)
                  .animate(key: ValueKey('halo$fxId'))
                  .fadeIn(duration: 140.ms)
                  .scaleXY(begin: 0.6, end: 1.12, duration: 420.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 340.ms, duration: 320.ms),
              // a single ring rippling outward
              Image.asset('$dir/ring_m.png', width: 128)
                  .animate(key: ValueKey('ring$fxId'))
                  .scaleXY(begin: 0.3, end: 1.7, duration: 560.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 240.ms, duration: 340.ms),
              // quick radial burst that clears before the reveal settles
              Image.asset('$dir/burst.png', width: 150)
                  .animate(key: ValueKey('burst$fxId'))
                  .scaleXY(begin: 0.4, end: 1.0, duration: 260.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 120.ms, duration: 240.ms),
              if (strong)
                Image.asset('$dir/spark.png', width: 214)
                    .animate(key: ValueKey('spark$fxId'))
                    .fadeIn(duration: 120.ms)
                    .scaleXY(begin: 0.5, end: 1.1, duration: 320.ms, curve: Curves.easeOut)
                    .fadeOut(delay: 220.ms, duration: 260.ms),
              // sparkles orbiting the outside
              _orbit(),
              // the focal reveal (carries its own entrance animation)
              reveal,
            ],
          ),
        ),
      ),
    );
  }
}

/// A focal reveal for quiz wins: an optional thematic [riser] sprite floats up
/// above a [check] that pops in. Clean — just two elements, well separated.
class WinReveal extends StatelessWidget {
  const WinReveal({
    super.key,
    required this.check,
    required this.id,
    this.riser,
    this.riserWidth = 90,
  });

  final String check;
  final String? riser;
  final double riserWidth;
  final int id;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (riser != null)
            Positioned(
              top: 0,
              child: Image.asset(riser!, width: riserWidth)
                  .animate(key: ValueKey('rise$id'))
                  .fadeIn(duration: 120.ms)
                  .slideY(begin: 0.7, end: -0.15, duration: 460.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 300.ms, duration: 200.ms),
            ),
          Positioned(
            bottom: 6,
            child: Image.asset(check, width: 74)
                .animate(key: ValueKey('chk$id'))
                .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                    duration: 360.ms,
                    curve: Curves.easeOutBack)
                .then(delay: 220.ms)
                .fadeOut(duration: 240.ms),
          ),
        ],
      ),
    );
  }
}
