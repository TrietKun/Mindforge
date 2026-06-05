import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Frosted-glass surface — blurs whatever (aurora) sits behind it and adds a
/// faint top sheen plus an optional colored glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.md),
    this.radius = Radii.lg,
    this.glow,
    this.borderColor,
    this.blur = 14,
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? glow;
  final Color? borderColor;
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: -12,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (tint ?? Colors.white).withValues(alpha: 0.10),
                  (tint ?? Colors.white).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
