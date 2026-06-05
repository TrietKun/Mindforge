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

/// Play-time length. Scales each game's tuned base duration so the relative
/// balance between games is preserved (a puzzle stays longer than a reflex
/// game) while letting the player pick shorter or longer sessions.
enum GameDuration { short, normal, long }

extension GameDurationX on GameDuration {
  String get label => switch (this) {
        GameDuration.short => L('Ngắn', 'Short'),
        GameDuration.normal => L('Vừa', 'Medium'),
        GameDuration.long => L('Dài', 'Long'),
      };

  String get description => switch (this) {
        GameDuration.short => L('Ván nhanh gọn', 'Quick rounds'),
        GameDuration.normal => L('Độ dài tiêu chuẩn', 'Standard length'),
        GameDuration.long => L('Chơi lâu hơn', 'Longer sessions'),
      };

  Color get color => switch (this) {
        GameDuration.short => AppPalette.math,
        GameDuration.normal => AppPalette.focus,
        GameDuration.long => AppPalette.memory,
      };

  IconData get icon => switch (this) {
        GameDuration.short => Icons.bolt_rounded,
        GameDuration.normal => Icons.timer_rounded,
        GameDuration.long => Icons.hourglass_bottom_rounded,
      };

  /// Multiplier applied to a game's base session length.
  double get factor => switch (this) {
        GameDuration.short => 0.6,
        GameDuration.normal => 1.0,
        GameDuration.long => 1.5,
      };

  /// Resolves a game's base seconds into the player-selected length.
  double apply(double baseSeconds) => (baseSeconds * factor).roundToDouble();
}

/// App-wide settings shared across games (in-memory).
class GameSettings {
  GameSettings._();
  static final ValueNotifier<Difficulty> difficulty =
      ValueNotifier(Difficulty.medium);
  static final ValueNotifier<GameDuration> duration =
      ValueNotifier(GameDuration.normal);
}
