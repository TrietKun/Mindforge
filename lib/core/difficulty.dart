import 'package:flutter/material.dart';

import 'i18n/app_lang.dart';
import 'theme/app_palette.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => L('Dễ', 'Easy'),
        Difficulty.medium => L('Thường', 'Normal'),
        Difficulty.hard => L('Khó', 'Hard'),
      };

  String get description => switch (this) {
        Difficulty.easy => L('Chậm rãi, nhiều thời gian', 'Slow, plenty of time'),
        Difficulty.medium => L('Cân bằng cho luyện tập', 'Balanced for practice'),
        Difficulty.hard => L('Nhanh, ít khoan nhượng', 'Fast and unforgiving'),
      };

  Color get color => switch (this) {
        Difficulty.easy => AppPalette.success,
        Difficulty.medium => AppPalette.focus,
        Difficulty.hard => AppPalette.danger,
      };

  IconData get icon => switch (this) {
        Difficulty.easy => Icons.spa_rounded,
        Difficulty.medium => Icons.fitness_center_rounded,
        Difficulty.hard => Icons.local_fire_department_rounded,
      };

  /// Multiplier applied to earned points so harder play rewards more.
  double get scoreMultiplier => switch (this) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.25,
        Difficulty.hard => 1.6,
      };
}

/// App-wide selected difficulty. Simple in-memory setting shared across games.
class GameSettings {
  GameSettings._();
  static final ValueNotifier<Difficulty> difficulty =
      ValueNotifier(Difficulty.medium);
}
