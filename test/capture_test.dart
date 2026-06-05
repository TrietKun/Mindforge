import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/games/quiz/option_quiz.dart';
import 'package:mindforge/features/games/quiz/quiz_specs.dart';

const _assets = [
  'arrow_left', 'arrow_right', 'target', 'halo', 'streak', 'redo', 'burst',
  'spark', 'cross', 'pop_ring', 'ring', 'swap', 'check', 'badge', 'star_pink',
  'star_blue', 'trophy', 'sparkle', 'shimmer',
];

void main() {
  testWidgets('capture flanker LEFT win', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: RepaintBoundary(
        key: key,
        child: OptionQuizScreen(spec: quizSpecFor('arrow_flanker')!),
      ),
    ));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(OptionQuizScreen));
      for (final a in _assets) {
        await precacheImage(AssetImage('assets/games/arrow_flanker/$a.png'), ctx);
      }
    });
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    Finder leftButton() => find.ancestor(
          of: find.image(
              const AssetImage('assets/games/arrow_flanker/arrow_left.png')),
          matching: find.byType(GestureDetector),
        );
    final check =
        find.image(const AssetImage('assets/games/arrow_flanker/check.png'));

    // Always tap LEFT; it only wins on a left-answer round, guaranteeing the
    // captured streak is the leftward one.
    for (var i = 0; i < 12; i++) {
      await tester.tap(leftButton().first, warnIfMissed: false);
      await tester.pump();
      for (var f = 0; f < 13; f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      if (check.evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('/Users/truongbinhtriet/Desktop/aff_left.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List() as Uint8List);
        });
        break;
      }
      await tester.pump(const Duration(milliseconds: 820));
    }
    await tester.pump(const Duration(milliseconds: 900));
  });
}
