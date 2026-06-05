import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/win_burst.dart';
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
const _bsDir = 'assets/games/bigger_sum';

/// Clean correct-answer burst (shared [WinBurst]): soft glow + one ring + a
/// quick burst, the up-arrow rising over a check, sparkles orbiting the outside.
Widget _biggerSumWinFx(int id, int combo, int answerIndex, String? answerText) =>
    WinBurst(
      dir: _bsDir,
      fxId: id,
      combo: combo,
      reveal: WinReveal(
          check: '$_bsDir/check.png', riser: '$_bsDir/up_arrow.png', id: id),
    );

final _biggerSum = QuizSpec(
  title: 'Vế Lớn Hơn',
  accent: AppPalette.math,
  iconAsset: '$_bsDir/trophy.png',
  sparkAsset: '$_bsDir/sparkle.png',
  fx: QuizFx(
    header: '$_bsDir/owl_mascot.png',
    headerHalo: '$_bsDir/halo.png',
    cross: '$_bsDir/cross.png',
    shimmer: '$_bsDir/shimmer.png',
    optionFrame: '$_bsDir/eq_frame.png',
    optionAspect: 4.7,
    screenShake: true,
    winBuilder: _biggerSumWinFx,
  ),
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
  // A gently swaying balance scale sets the "which weighs more" mood.
  buildPrompt: (context, round) => Image.asset('$_bsDir/scale.png',
          width: 116, height: 88, fit: BoxFit.contain)
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .rotate(begin: -0.02, end: 0.02, duration: 1600.ms, curve: Curves.easeInOut),
);

// ── Math: Sequence Math ─────────────────────────────────────────────────────
const _sqDir = 'assets/games/sequence_math';

final _sequenceMath = QuizSpec(
  title: 'Dãy Số',
  accent: AppPalette.math,
  iconAsset: '$_sqDir/trophy.png',
  sparkAsset: '$_sqDir/sparkle.png',
  fx: QuizFx(
    header: '$_sqDir/robot_mascot.png',
    headerHalo: '$_sqDir/halo.png',
    cross: '$_sqDir/cross.png',
    shimmer: '$_sqDir/shooting_star.png',
    optionFrame: '$_sqDir/option_pad.png',
    optionAspect: 1.72,
    screenShake: true,
    // Clean, focused celebration: glow + ring + burst behind the revealed
    // answer node (matches the other number games — no streak/confetti pile-up).
    winBuilder: (id, combo, idx, answer) => WinBurst(
      dir: _sqDir,
      fxId: id,
      combo: combo,
      alignment: const Alignment(0, -0.12),
      reveal: _SeqRevealNode(value: answer ?? '', id: id),
    ),
  ),
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
  // The four shown terms + "?" render as a flowing row of sprite nodes.
  buildPrompt: (context, round) {
    final parts = (round.data as String)
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    Widget node(int i, String part) {
      final isQ = part == '?';
      final Widget tile = isQ
          ? SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Image.asset('$_sqDir/halo.png', width: 80, height: 80)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.2, end: 0.62, duration: 1100.ms),
                  Image.asset('$_sqDir/question_node.png', width: 56, height: 56)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.08, duration: 1100.ms),
                ],
              ),
            )
          : SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('$_sqDir/node.png', width: 54, height: 54),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(part,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            );
      // Each node pops in with a stagger.
      return tile
          .animate()
          .fadeIn(delay: (i * 60).ms, duration: 200.ms)
          .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              delay: (i * 60).ms,
              duration: 340.ms,
              curve: Curves.easeOutBack);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset('$_sqDir/connector.png', width: 18)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1500.ms, color: const Color(0xFF8FE9FF)),
                ),
              ),
            node(i, parts[i]),
          ],
        ],
      ),
    );
  },
);

class _SeqRevealNode extends StatelessWidget {
  const _SeqRevealNode({required this.value, required this.id});
  final String value;
  final int id;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset('$_sqDir/node.png', width: 66, height: 66),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Image.asset('$_sqDir/check.png', width: 32),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('rev$id'))
        .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 380.ms,
            curve: Curves.easeOutBack)
        .then(delay: 220.ms)
        .fadeOut(duration: 240.ms);
  }
}

// ── Math: Balance Equation ──────────────────────────────────────────────────
const _balanceDir = 'assets/games/balance_eq';

/// Clean balance-achieved burst (shared [WinBurst]): glow + ring + a quick
/// burst, a glowing equals rising over a check, sparkles orbiting the outside.
Widget _balanceWinFx(int id, int combo, int answerIndex, String? answer) =>
    WinBurst(
      dir: _balanceDir,
      fxId: id,
      combo: combo,
      reveal: WinReveal(
          check: '$_balanceDir/check.png',
          riser: '$_balanceDir/equals_glow.png',
          id: id),
    );

final _balanceEquation = QuizSpec(
  title: 'Cân Bằng',
  accent: AppPalette.math,
  iconAsset: '$_balanceDir/trophy.png',
  sparkAsset: '$_balanceDir/sparkle.png',
  fx: QuizFx(
    header: '$_balanceDir/owl_mascot.png',
    headerHalo: '$_balanceDir/halo.png',
    cross: '$_balanceDir/cross.png',
    shimmer: '$_balanceDir/shimmer.png',
    optionFrame: '$_balanceDir/eq_frame.png',
    optionAspect: 1.05,
    screenShake: true,
    winBuilder: _balanceWinFx,
  ),
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
// Synonym banks kept parallel per language; each round reads the active one.
const _synonymsVi = {
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
  'Bắt đầu': 'Khởi đầu',
  'Kết thúc': 'Chấm dứt',
  'Lười': 'Biếng',
  'Chăm chỉ': 'Siêng năng',
  'Dũng cảm': 'Can đảm',
  'Hiền': 'Lành',
  'Ác': 'Dữ',
  'Cũ': 'Xưa',
  'Mới': 'Tân',
  'Rộng': 'Bao la',
  'Hẹp': 'Chật',
  'Sạch': 'Tinh tươm',
  'Bẩn': 'Dơ',
  'Lạnh': 'Giá',
  'Nóng': 'Oi bức',
  'Tức giận': 'Phẫn nộ',
  'Lo lắng': 'Bồn chồn',
  'Mệt': 'Kiệt sức',
  'Vắng': 'Hoang vắng',
  'Đông đúc': 'Tấp nập',
};

const _synonymsEn = {
  'Happy': 'Joyful',
  'Sad': 'Unhappy',
  'Fast': 'Quick',
  'Big': 'Large',
  'Small': 'Tiny',
  'Beautiful': 'Pretty',
  'Smart': 'Clever',
  'Strong': 'Powerful',
  'Scared': 'Afraid',
  'Rich': 'Wealthy',
  'Quiet': 'Silent',
  'Hard': 'Difficult',
  'Begin': 'Start',
  'End': 'Finish',
  'Angry': 'Mad',
  'Lazy': 'Idle',
  'Diligent': 'Hardworking',
  'Brave': 'Courageous',
  'Kind': 'Nice',
  'Evil': 'Wicked',
  'Old': 'Ancient',
  'New': 'Fresh',
  'Empty': 'Vacant',
  'Crowded': 'Packed',
  'Wide': 'Broad',
  'Narrow': 'Tight',
  'Clean': 'Spotless',
  'Dirty': 'Filthy',
  'Cold': 'Chilly',
  'Hot': 'Boiling',
  'Calm': 'Peaceful',
  'Tired': 'Exhausted',
};

/// The synonym bank for the active language.
Map<String, String> get _synonyms =>
    appLang.value == AppLang.vi ? _synonymsVi : _synonymsEn;

const _synDir = 'assets/games/synonym';

/// Clean synonym-match burst (shared [WinBurst]): glow + ring + a quick burst,
/// a glowing "two words linked" rising over a check, sparkles orbiting outside.
Widget _synonymWinFx(int id, int combo, int answerIndex, String? answer) =>
    WinBurst(
      dir: _synDir,
      fxId: id,
      combo: combo,
      reveal: WinReveal(
          check: '$_synDir/check.png',
          riser: '$_synDir/link_glow.png',
          riserWidth: 120,
          id: id),
    );

final _synonym = QuizSpec(
  title: 'Đồng Nghĩa',
  accent: AppPalette.language,
  iconAsset: '$_synDir/trophy.png',
  sparkAsset: '$_synDir/sparkle.png',
  fx: QuizFx(
    header: '$_synDir/owl_mascot.png',
    headerHalo: '$_synDir/halo.png',
    cross: '$_synDir/cross.png',
    shimmer: '$_synDir/shimmer.png',
    optionFrame: '$_synDir/word_btn.png',
    optionAspect: 1.9,
    screenShake: true,
    winBuilder: _synonymWinFx,
  ),
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
  buildPrompt: (context, round) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      round.data as String,
      style: const TextStyle(
          color: AppPalette.textPrimary,
          fontSize: 40,
          fontWeight: FontWeight.w900),
    ),
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

/// Clean flanker celebration (shared [WinBurst]): glow + ring + a quick burst,
/// a streak rising over a check, sparkles orbiting the outside.
Widget _flankerWinFx(int id, int combo, int answerIndex, String? answerText) =>
    WinBurst(
      dir: _flankerDir,
      fxId: id,
      combo: combo,
      reveal: WinReveal(
          check: '$_flankerDir/check.png',
          riser: '$_flankerDir/streak.png',
          riserWidth: 110,
          id: id),
    );

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
