import 'package:flutter/material.dart';

/// Vibrant Dark design tokens.
///
/// Each cognitive group owns an accent color so every game keeps a distinct
/// identity while sharing one system.
class AppPalette {
  const AppPalette._();

  // Base surfaces
  static const Color background = Color(0xFF0B0E1A);
  static const Color backgroundElevated = Color(0xFF11162A);
  static const Color surface = Color(0xFF151A2E);
  static const Color surfaceHigh = Color(0xFF1E2540);
  static const Color stroke = Color(0xFF2A3354);

  // Text
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFF9BA6C9);
  static const Color textMuted = Color(0xFF606B92);

  // Per-category accents
  static const Color reaction = Color(0xFFFF7A3D); // speed — orange
  static const Color memory = Color(0xFFA855F7); // memory — purple
  static const Color focus = Color(0xFF38BDF8); // attention — sky
  static const Color logic = Color(0xFF34D399); // problem solving — emerald
  static const Color flexibility = Color(0xFFF472B6); // pink
  static const Color math = Color(0xFF22D3EE); // cyan
  static const Color language = Color(0xFFFBBF24); // amber

  // Feedback
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFFB5871);
  static const Color gold = Color(0xFFFFC857);

  static const List<Color> bgGradient = [
    Color(0xFF0B0E1A),
    Color(0xFF0E1330),
    Color(0xFF0B0E1A),
  ];
}
