import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// A living backdrop: soft accent "aurora" blobs drift and breathe behind a
/// dark gradient. Cheap to render (a handful of blurred circles per frame).
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.blobs});

  final Widget child;

  /// Optional custom blob accent colors; defaults to the brand spread.
  final List<Color>? blobs;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.blobs ??
        const [
          AppPalette.memory,
          AppPalette.focus,
          AppPalette.reaction,
          AppPalette.logic,
        ];
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuroraPainter(_controller.value, colors),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.colors);

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base vertical gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppPalette.bgGradient,
        ).createShader(rect),
    );

    final tau = math.pi * 2;
    for (var i = 0; i < colors.length; i++) {
      final phase = i / colors.length;
      final dx = 0.5 + 0.42 * math.sin(tau * (t + phase));
      final dy = 0.5 + 0.40 * math.cos(tau * (t * 0.8 + phase * 1.3));
      final radius = size.shortestSide * (0.45 + 0.12 * math.sin(tau * (t + phase)));
      final breathe = 0.10 + 0.05 * (0.5 + 0.5 * math.sin(tau * (t * 1.5 + phase)));

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        radius,
        Paint()
          ..color = colors[i].withValues(alpha: breathe)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90),
      );
    }

    // Subtle darkening vignette so foreground content stays readable.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            AppPalette.background.withValues(alpha: 0.55),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
