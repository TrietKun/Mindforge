import 'package:flutter/widgets.dart';

import '../data/models/game_info.dart';

/// Tracks each game's best score (in-memory, like the other [GameSettings]) and
/// derives the rotating "Today's Challenge" from it. Bumping [revision] lets the
/// home card rebuild the moment a new best is recorded.
class ChallengeStore {
  ChallengeStore._();

  static final Map<String, int> _best = {};

  /// Increments whenever a best score changes, so listeners can refresh.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static int bestFor(String gameId) => _best[gameId] ?? 0;

  /// Records a finished game's score; keeps the highest seen for that game.
  static void report(String gameId, int score) {
    if (score > (_best[gameId] ?? 0)) {
      _best[gameId] = score;
      revision.value++;
    }
  }

  /// The challenge for the current calendar day — a deterministic pick from the
  /// available games plus a target that rotates through 200…500.
  static DailyChallenge today() {
    final pool = kGames.where((g) => g.available).toList();
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final game = pool[dayOfYear % pool.length];
    final target = 200 + (dayOfYear % 5) * 75; // 200, 275, 350, 425, 500
    return DailyChallenge(game: game, target: target);
  }
}

class DailyChallenge {
  const DailyChallenge({required this.game, required this.target});

  final GameInfo game;
  final int target;

  int get best => ChallengeStore.bestFor(game.id);
  bool get done => best >= target;
  double get progress =>
      target <= 0 ? 0 : (best / target).clamp(0.0, 1.0);
}

/// Carries the launched game's id down the tree so the shared [ResultOverlay]
/// can report the final score to [ChallengeStore] without every game plumbing
/// its own id through. Absent in isolated tests, where reporting is skipped.
class GameScope extends InheritedWidget {
  const GameScope({super.key, required this.gameId, required super.child});

  final String gameId;

  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()?.gameId;

  @override
  bool updateShouldNotify(GameScope oldWidget) => oldWidget.gameId != gameId;
}
