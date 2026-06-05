import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import 'option_quiz.dart';

/// Returns the [QuizSpec] for a quiz-based game id, or null if [id] is not one.
QuizSpec? quizSpecFor(String id) => switch (id) {
      'bigger_sum' => _biggerSum,
      'sequence_math' => _sequenceMath,
      'balance_eq' => _balanceEquation,
      'synonym' => _synonym,
      'first_letter' => _firstLetter,
      'arrow_flanker' => _arrowFlanker,
      _ => null,
    };

/// Shuffles [answer] in with [distractors] and reports where it landed.
QuizRound _assemble(String answer, List<String> distractors, {Object? data}) {
  final all = [answer, ...distractors]..shuffle();
  return QuizRound(
    options: all.map(QuizOption.text).toList(),
    answerIndex: all.indexOf(answer),
    data: data,
  );
}

// ── Math: Bigger Sum ────────────────────────────────────────────────────────
final _biggerSum = QuizSpec(
  title: 'Vế Lớn Hơn',
  accent: AppPalette.math,
  iconAsset: 'assets/kit/trophy_cyan.png',
  icon: Icons.balance_rounded,
  instruction: () => L('Vế nào có kết quả LỚN HƠN?', 'Which side is BIGGER?'),
  optionsPerRow: 1,
  sessionSeconds: 40,
  generate: (solved, difficulty, rng) {
    final max = switch (difficulty) {
      _ when difficulty.index == 0 => 20,
      _ when difficulty.index == 1 => 50,
      _ => 99,
    };
    ({String text, int value}) make() {
      final a = 1 + rng.nextInt(max);
      final b = 1 + rng.nextInt(max);
      return (text: '$a + $b', value: a + b);
    }

    var left = make();
    var right = make();
    while (left.value == right.value) {
      right = make();
    }
    final options = [left.text, right.text];
    final answerIndex = left.value > right.value ? 0 : 1;
    return QuizRound(
      options: options.map(QuizOption.text).toList(),
      answerIndex: answerIndex,
    );
  },
  buildPrompt: (context, round) => const Icon(Icons.balance_rounded,
      color: AppPalette.math, size: 52),
);

// ── Math: Sequence Math ─────────────────────────────────────────────────────
final _sequenceMath = QuizSpec(
  title: 'Dãy Số',
  accent: AppPalette.math,
  iconAsset: 'assets/kit/trophy_cyan.png',
  icon: Icons.functions_rounded,
  instruction: () => L('Số tiếp theo của dãy?', 'Next number in the sequence?'),
  generate: (solved, difficulty, rng) {
    final type = rng.nextInt(3);
    List<int> seq;
    switch (type) {
      case 0:
        final start = 1 + rng.nextInt(9);
        final step = 2 + rng.nextInt(8);
        seq = List.generate(5, (i) => start + i * step);
      case 1:
        final start = 1 + rng.nextInt(4);
        final ratio = 2 + rng.nextInt(2);
        seq = List.generate(5, (i) => start * math.pow(ratio, i).toInt());
      default:
        final start = 1 + rng.nextInt(4);
        var step = 1 + rng.nextInt(3);
        seq = [start];
        for (var i = 1; i < 5; i++) {
          seq.add(seq[i - 1] + step);
          step++;
        }
    }
    final answer = seq.last;
    final shown = seq.take(4).join(',  ');
    final distractors = <int>{};
    final spread = math.max(2, answer ~/ 6 + 2);
    while (distractors.length < 3) {
      final d = answer + (rng.nextBool() ? 1 : -1) * (1 + rng.nextInt(spread));
      if (d != answer && d >= 0) distractors.add(d);
    }
    return _assemble('$answer', distractors.map((e) => '$e').toList(),
        data: '$shown,  ?');
  },
  buildPrompt: (context, round) => Text(
    round.data as String,
    textAlign: TextAlign.center,
    style: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w900),
  ),
);

// ── Math: Balance Equation ──────────────────────────────────────────────────
final _balanceEquation = QuizSpec(
  title: 'Cân Bằng',
  accent: AppPalette.math,
  iconAsset: 'assets/kit/trophy_cyan.png',
  icon: Icons.calculate_rounded,
  instruction: () => L('Chọn dấu cho đúng phép tính', 'Pick the operator that fits'),
  optionsPerRow: 3,
  generate: (solved, difficulty, rng) {
    const ops = ['+', '−', '×'];
    int compute(int a, int b, String op) => switch (op) {
          '+' => a + b,
          '−' => a - b,
          _ => a * b,
        };
    final maxN = difficulty.index == 2 ? 12 : 9;
    while (true) {
      final a = 2 + rng.nextInt(maxN);
      final b = 1 + rng.nextInt(a); // keep subtraction non-negative
      final op = ops[rng.nextInt(ops.length)];
      final result = compute(a, b, op);
      // Ensure the answer is unambiguous among the three operators.
      final matches = ops.where((o) => compute(a, b, o) == result).length;
      if (matches != 1) continue;
      return QuizRound(
        options: ops.map(QuizOption.text).toList(),
        answerIndex: ops.indexOf(op),
        data: '$a  ?  $b  =  $result',
      );
    }
  },
  buildPrompt: (context, round) => Text(
    round.data as String,
    style: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w900),
  ),
);

// ── Language: Synonym Match ─────────────────────────────────────────────────
const _synonyms = {
  'Vui': 'Hạnh phúc',
  'Buồn': 'Sầu',
  'Nhanh': 'Mau',
  'To': 'Lớn',
  'Nhỏ': 'Bé',
  'Đẹp': 'Xinh',
  'Thông minh': 'Khôn',
  'Mạnh': 'Khỏe',
  'Sợ': 'Hãi',
  'Giàu': 'Sung túc',
  'Yên tĩnh': 'Tĩnh lặng',
  'Khó': 'Gian nan',
};

final _synonym = QuizSpec(
  title: 'Đồng Nghĩa',
  accent: AppPalette.language,
  iconAsset: 'assets/kit/trophy_amber.png',
  icon: Icons.compare_arrows_rounded,
  instruction: () => L('Từ nào ĐỒNG NGHĨA?', 'Which word is a SYNONYM?'),
  generate: (solved, difficulty, rng) {
    final keys = _synonyms.keys.toList();
    final key = keys[rng.nextInt(keys.length)];
    final answer = _synonyms[key]!;
    final pool = _synonyms.values.where((v) => v != answer).toList()
      ..shuffle(rng);
    return _assemble(answer, pool.take(3).toList(), data: key);
  },
  buildPrompt: (context, round) => Text(
    round.data as String,
    style: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 40,
        fontWeight: FontWeight.w900),
  ),
);

// ── Language: First Letter (Chữ Đầu) ────────────────────────────────────────
const _wordPool = [
  'Bàn', 'Cây', 'Đèn', 'Gà', 'Hoa', 'Lá', 'Mèo', 'Nhà', 'Cá', 'Sách',
  'Trâu', 'Voi', 'Xe', 'Bút', 'Dao', 'Gối', 'Hổ', 'Kẹo', 'Mây', 'Núi',
  'Phở', 'Quạt', 'Rổ', 'Sữa', 'Tre', 'Vịt', 'Bánh', 'Chó', 'Đào', 'Gạo',
  'Heo', 'Kính', 'Lửa', 'Mưa', 'Nón', 'Cam', 'Ổi', 'Táo', 'Lê', 'Khế',
];

final _firstLetter = QuizSpec(
  title: 'Chữ Đầu',
  accent: AppPalette.language,
  iconAsset: 'assets/kit/trophy_amber.png',
  icon: Icons.text_fields_rounded,
  instruction: () =>
      L('Từ nào bắt đầu bằng chữ đã cho?', 'Which word starts with the letter?'),
  generate: (solved, difficulty, rng) {
    final answer = _wordPool[rng.nextInt(_wordPool.length)];
    final letter = answer.characters.first;
    final distractors = (_wordPool
        .where((w) => w.characters.first != letter)
        .toList()
      ..shuffle(rng));
    return _assemble(answer, distractors.take(3).toList(), data: letter);
  },
  buildPrompt: (context, round) => Text(
    round.data as String,
    style: const TextStyle(
        color: AppPalette.language,
        fontSize: 56,
        fontWeight: FontWeight.w900),
  ),
);


// ── Flexibility: Arrow Flanker ──────────────────────────────────────────────
const _flankerDir = 'assets/games/arrow_flanker';

/// Bespoke flanker celebration — uses the full sprite set: a spinning redo
/// flourish, ring + pop-ring ripples, a quick burst, a directional streak,
/// pink/blue stars at the corners, a badge below and the check at the centre.
Widget _flankerWinFx(int id, int combo, int answerIndex) {
  final strong = combo >= 3;
  final leftward = answerIndex == 0; // streak shoots toward the answer
  Widget at(Alignment a, Widget w) => Align(alignment: a, child: w);

  return Center(
    child: SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // spinning flourish behind everything
          Image.asset('$_flankerDir/redo.png', width: 170)
              .animate(key: ValueKey('spin$id'))
              .fadeIn(duration: 120.ms)
              .rotate(begin: 0, end: 0.6, duration: 560.ms, curve: Curves.easeOut)
              .scaleXY(begin: 0.6, end: 1.25, duration: 520.ms)
              .fadeOut(delay: 320.ms, duration: 260.ms),
          // ring + pop-ring ripples
          Image.asset('$_flankerDir/ring.png', width: 130)
              .animate(key: ValueKey('ring$id'))
              .scaleXY(begin: 0.3, end: 1.7, duration: 520.ms, curve: Curves.easeOut)
              .fadeOut(delay: 200.ms, duration: 320.ms),
          Image.asset('$_flankerDir/pop_ring.png', width: 150)
              .animate(key: ValueKey('pop$id'))
              .scaleXY(begin: 0.4, end: 1.9, duration: 620.ms, curve: Curves.easeOut)
              .fadeOut(delay: 260.ms, duration: 340.ms),
          // quick radial burst
          Image.asset('$_flankerDir/burst.png', width: 168)
              .animate(key: ValueKey('burst$id'))
              .scaleXY(begin: 0.4, end: 1.0, duration: 260.ms, curve: Curves.easeOut)
              .fadeOut(delay: 120.ms, duration: 240.ms),
          if (strong)
            Image.asset('$_flankerDir/spark.png', width: 228)
                .animate(key: ValueKey('spark$id'))
                .fadeIn(duration: 120.ms)
                .scaleXY(begin: 0.5, end: 1.15, duration: 340.ms, curve: Curves.easeOut)
                .fadeOut(delay: 220.ms, duration: 260.ms),
          // streak shooting toward the answered side
          Image.asset('$_flankerDir/streak.png', width: 150)
              .animate(key: ValueKey('streak$id'))
              .slideX(
                  begin: leftward ? 1.6 : -1.6,
                  end: leftward ? -1.6 : 1.6,
                  duration: 460.ms,
                  curve: Curves.easeIn)
              .fadeIn(duration: 120.ms)
              .fadeOut(delay: 260.ms, duration: 180.ms),
          // corner stars
          at(
            const Alignment(-0.74, -0.62),
            Image.asset('$_flankerDir/star_pink.png', width: 52)
                .animate(key: ValueKey('s1$id'))
                .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                    delay: 80.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack)
                .then(delay: 120.ms)
                .fadeOut(duration: 220.ms),
          ),
          at(
            const Alignment(0.76, -0.5),
            Image.asset('$_flankerDir/star_blue.png', width: 46)
                .animate(key: ValueKey('s2$id'))
                .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                    delay: 160.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack)
                .then(delay: 80.ms)
                .fadeOut(duration: 220.ms),
          ),
          // badge below
          at(
            const Alignment(0, 0.82),
            Image.asset('$_flankerDir/badge.png', width: 48)
                .animate(key: ValueKey('bdg$id'))
                .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                    delay: 120.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack)
                .then(delay: 120.ms)
                .fadeOut(duration: 220.ms),
          ),
          // the check — focal confirmation
          Image.asset('$_flankerDir/check.png', width: 78)
              .animate(key: ValueKey('chk$id'))
              .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  delay: 80.ms,
                  duration: 360.ms,
                  curve: Curves.easeOutBack)
              .then(delay: 220.ms)
              .fadeOut(duration: 240.ms),
        ],
      ),
    ),
  );
}

final _arrowFlanker = QuizSpec(
  title: 'Mũi Tên',
  accent: AppPalette.flexibility,
  iconAsset: '$_flankerDir/trophy.png',
  sparkAsset: '$_flankerDir/sparkle.png',
  fx: QuizFx(
    header: '$_flankerDir/target.png',
    headerHalo: '$_flankerDir/halo.png',
    cross: '$_flankerDir/cross.png',
    shimmer: '$_flankerDir/shimmer.png',
    screenShake: true,
    winBuilder: _flankerWinFx,
  ),
  icon: Icons.compare_arrows_rounded,
  instruction: () => L('Hướng của mũi tên Ở GIỮA?', 'Direction of the MIDDLE arrow?'),
  optionsPerRow: 2,
  sessionSeconds: 35,
  generate: (solved, difficulty, rng) {
    // Hard: flankers more likely to oppose the centre (more interference).
    final conflict = switch (difficulty.index) {
      0 => 0.4,
      1 => 0.6,
      _ => 0.8,
    };
    final centre = rng.nextBool(); // true = right
    final dirs = List.generate(5, (i) {
      if (i == 2) return centre;
      return rng.nextDouble() < conflict ? !centre : centre;
    });
    // The answer buttons reuse the crisp arrow sprites.
    return QuizRound(
      options: const [
        QuizOption.asset('$_flankerDir/arrow_left.png'),
        QuizOption.asset('$_flankerDir/arrow_right.png'),
      ],
      answerIndex: centre ? 1 : 0,
      data: dirs,
    );
  },
  buildPrompt: (context, round) {
    final dirs = round.data as List<bool>;
    String arrow(int i) =>
        dirs[i] ? '$_flankerDir/arrow_right.png' : '$_flankerDir/arrow_left.png';

    // Each arrow flows in with a 50ms stagger. The middle (target) arrow is
    // larger, sits on a pulsing halo and pops on a bounce to pull the eye;
    // the flankers idly nudge toward their own direction as visual noise.
    Widget arrowSprite(int i) {
      final isMiddle = i == 2;
      final side = isMiddle ? 64.0 : 46.0;
      final dirSign = dirs[i] ? 1.0 : -1.0;

      Widget core = SizedBox(
        width: side,
        height: side,
        child: Image.asset(arrow(i), fit: BoxFit.contain),
      );

      if (isMiddle) {
        core = SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Image.asset('$_flankerDir/halo.png', width: 90, height: 90)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.22, end: 0.6, duration: 1100.ms)
                  .scaleXY(begin: 0.92, end: 1.12, duration: 1100.ms),
              core
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                      begin: 0.98,
                      end: 1.06,
                      duration: 1200.ms,
                      curve: Curves.easeInOut),
            ],
          ),
        );
        return core
            .animate()
            .scaleXY(
                begin: 0.8,
                end: 1,
                delay: 100.ms,
                duration: 360.ms,
                curve: Curves.easeOutBack)
            .fadeIn(delay: 100.ms, duration: 220.ms);
      }

      return core
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveX(
              begin: -2 * dirSign,
              end: 2 * dirSign,
              duration: 900.ms,
              curve: Curves.easeInOut)
          .animate()
          .fadeIn(delay: (i * 50).ms, duration: 200.ms)
          .slideX(
              begin: 0.3,
              end: 0,
              delay: (i * 50).ms,
              duration: 260.ms,
              curve: Curves.easeOut);
    }

    // The arrows sit over a faint, slowly rotating "swap" motif (the flanker
    // conflict) and a couple of drifting stars for ambient life.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: 0.10,
          child: Image.asset('$_flankerDir/swap.png', width: 140)
              .animate(onPlay: (c) => c.repeat())
              .rotate(begin: 0, end: 1, duration: 7000.ms),
        ),
        Align(
          alignment: const Alignment(-0.95, -0.8),
          child: Opacity(
            opacity: 0.22,
            child: Image.asset('$_flankerDir/star_pink.png', width: 24)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -4, end: 4, duration: 2600.ms, curve: Curves.easeInOut),
          ),
        ),
        Align(
          alignment: const Alignment(0.96, 0.75),
          child: Opacity(
            opacity: 0.20,
            child: Image.asset('$_flankerDir/star_blue.png', width: 22)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 5, end: -5, duration: 3000.ms, curve: Curves.easeInOut),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < dirs.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: arrowSprite(i),
                ),
            ],
          ),
        ),
      ],
    );
  },
);
