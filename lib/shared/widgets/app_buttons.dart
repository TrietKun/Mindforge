import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.colors = const [AppPalette.reaction, AppPalette.gold],
  });

  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(Radii.md),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surfaceHigh,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppPalette.textSecondary, size: 22),
        ),
      ),
    );
  }
}
