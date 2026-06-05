import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/i18n/app_lang.dart';
import 'package:mindforge/core/theme/app_theme.dart';
import 'package:mindforge/data/models/game_info.dart';
import 'package:mindforge/features/games/anagram/anagram_screen.dart';
import 'package:mindforge/features/games/card_match/card_match_screen.dart';
import 'package:mindforge/features/games/counting_dots/counting_dots_screen.dart';
import 'package:mindforge/features/games/even_odd/even_odd_switch_screen.dart';
import 'package:mindforge/features/games/grid_find/grid_find_screen.dart';
import 'package:mindforge/features/games/lights_out/lights_out_screen.dart';
import 'package:mindforge/features/games/memory_grid/memory_grid_screen.dart';
import 'package:mindforge/features/games/number_bonds/number_bonds_screen.dart';
import 'package:mindforge/features/games/number_flow/number_flow_screen.dart';
import 'package:mindforge/features/games/odd_word/odd_word_screen.dart';
import 'package:mindforge/features/games/quick_math/quick_math_screen.dart';
import 'package:mindforge/features/games/quiz/option_quiz.dart';
import 'package:mindforge/features/games/quiz/quiz_specs.dart';
import 'package:mindforge/features/games/reaction_tap/reaction_tap_screen.dart';
import 'package:mindforge/features/games/rule_shift/rule_shift_screen.dart';
import 'package:mindforge/features/games/sliding_puzzle/sliding_puzzle_screen.dart';
import 'package:mindforge/features/games/switch_game/switch_screen.dart';
import 'package:mindforge/features/games/trail_maker/trail_maker_screen.dart';
import 'package:mindforge/main.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

void main() {
  testWidgets('Home renders title, cards and difficulty selector',
      (tester) async {
    await tester.pumpWidget(const MindForgeApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MindForge'), findsOneWidget);
    expect(find.text('Chạm Nhanh'), findsWidgets);
    expect(find.text('Độ khó'), findsOneWidget);

    // Drain entrance/delay timers; ambient animations loop forever so we never
    // pumpAndSettle.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Language switches from the settings sheet', (tester) async {
    appLang.value = AppLang.vi;
    addTearDown(() => appLang.value = AppLang.vi);
    await tester.pumpWidget(const MindForgeApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Chạm Nhanh'), findsWidgets);

    // The only top-right control is the "..." menu — open it, then switch lang.
    await tester.tap(find.image(const AssetImage('assets/kit/menu.png')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('EN'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(appLang.value, AppLang.en);
    expect(find.text('Quick Tap'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Difficulty selector updates the global setting', (tester) async {
    GameSettings.difficulty.value = Difficulty.medium;
    await tester.pumpWidget(const MindForgeApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Khó'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(GameSettings.difficulty.value, Difficulty.hard);

    await tester.tap(find.text('Dễ'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(GameSettings.difficulty.value, Difficulty.easy);

    GameSettings.difficulty.value = Difficulty.medium;
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Play-time selector updates the global setting and scales seconds',
      (tester) async {
    GameSettings.difficulty.value = Difficulty.medium;
    GameSettings.duration.value = GameDuration.normal;
    addTearDown(() => GameSettings.duration.value = GameDuration.normal);
    await tester.pumpWidget(const MindForgeApp());
    await tester.pump(const Duration(seconds: 1));

    // The Vietnamese labels for the three play-time presets.
    await tester.tap(find.text('Dài'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(GameSettings.duration.value, GameDuration.long);

    await tester.tap(find.text('Ngắn'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(GameSettings.duration.value, GameDuration.short);

    // Scaling preserves order: short < normal < long for the same base length.
    expect(GameDuration.short.apply(60), lessThan(GameDuration.normal.apply(60)));
    expect(GameDuration.normal.apply(60), lessThan(GameDuration.long.apply(60)));
    expect(GameDuration.normal.apply(60), 60);

    GameSettings.duration.value = GameDuration.normal;
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('New game screens build and run', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const QuickMathScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('= ?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(_host(const SwitchScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('HƠN'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(_host(const OddWordScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Từ nào không cùng nhóm?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('Every quiz spec generates valid rounds across difficulties', () {
    final rng = math.Random(7);
    final quizIds =
        kGames.map((g) => g.id).where((id) => quizSpecFor(id) != null);
    expect(quizIds, isNotEmpty);
    for (final id in quizIds) {
      final spec = quizSpecFor(id)!;
      for (final d in Difficulty.values) {
        for (var i = 0; i < 60; i++) {
          final round = spec.generate(i, d, rng);
          expect(round.options.length, greaterThanOrEqualTo(2), reason: id);
          expect(round.answerIndex, inInclusiveRange(0, round.options.length - 1),
              reason: id);
        }
      }
    }
  });

  testWidgets('A quiz screen builds and runs', (tester) async {
    await tester.pumpWidget(_host(OptionQuizScreen(spec: quizSpecFor('balance_eq')!)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('='), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Flanker quiz (sprite arrows + image buttons) builds',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester
        .pumpWidget(_host(OptionQuizScreen(spec: quizSpecFor('arrow_flanker')!)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Reaction Tap (sprite assets) builds without error',
      (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const ReactionTapScreen()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_host(const MemoryGridScreen()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom game screens build and run', (tester) async {
    tester.view.physicalSize = const Size(400, 880); // portrait phone
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final screens = <Widget>[
      const GridFindScreen(mode: GridFindMode.symbol),
      const GridFindScreen(mode: GridFindMode.hue),
      const CardMatchScreen(),
      const LightsOutScreen(),
      const TrailMakerScreen(),
      const SlidingPuzzleScreen(),
      const RuleShiftScreen(),
      const NumberBondsScreen(),
      const AnagramScreen(),
      const EvenOddSwitchScreen(),
      const CountingDotsScreen(),
      const NumberFlowScreen(),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(_host(screen));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('Number Flow answer taps fire FX without error', (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const NumberFlowScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    // Tapping the answer pads drives either the win burst (comet/rings/confetti
    // + reveal tile) or the wrong-answer cross + screen shake. Cycle a few so
    // both feedback overlays get built at least once.
    final pads = find.image(
        const AssetImage('assets/games/number_flow/option_pad.png'));
    expect(pads, findsNWidgets(4));
    for (var i = 0; i < 5; i++) {
      await tester.tap(pads.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 820)); // let FX timers clear
    }
  });

  testWidgets('Quick Math answer taps fire FX without error', (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const QuickMathScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    final pads = find
        .image(const AssetImage('assets/games/quick_math/option_pad.png'));
    expect(pads, findsNWidgets(4));
    for (var i = 0; i < 5; i++) {
      await tester.tap(pads.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 820));
    }
  });

  testWidgets('Odd Word answer taps fire FX without error', (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const OddWordScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    final buttons =
        find.image(const AssetImage('assets/games/odd_word/word_btn.png'));
    expect(buttons, findsNWidgets(4));
    for (var i = 0; i < 5; i++) {
      await tester.tap(buttons.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 820));
    }
  });

  testWidgets('Counting Dots answer taps fire FX without error',
      (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_host(const CountingDotsScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    final pads =
        find.image(const AssetImage('assets/games/counting_dots/pad.png'));
    expect(pads, findsNWidgets(4));
    for (var i = 0; i < 5; i++) {
      await tester.tap(pads.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 900));
    }
  });

  testWidgets('Flanker rich FX (burst/cross/shake) fire without error',
      (tester) async {
    tester.view.physicalSize = const Size(400, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester
        .pumpWidget(_host(OptionQuizScreen(spec: quizSpecFor('arrow_flanker')!)));
    await tester.pump(const Duration(milliseconds: 120));

    // The answer buttons reuse the arrow sprites (also shown as prompt
    // flankers), so target the option buttons by their GestureDetector ancestor.
    Finder optionButton(String side) => find.ancestor(
          of: find.image(
              AssetImage('assets/games/arrow_flanker/arrow_$side.png')),
          matching: find.byType(GestureDetector),
        );
    for (var i = 0; i < 6; i++) {
      await tester.tap(optionButton(i.isEven ? 'left' : 'right').first,
          warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 820));
    }
  });
}
