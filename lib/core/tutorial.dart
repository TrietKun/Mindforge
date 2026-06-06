import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One page of a per-game tutorial.
class TutorialStep {
  const TutorialStep({
    required this.titleVi,
    required this.titleEn,
    required this.bodyVi,
    required this.bodyEn,
    required this.icon,
  });

  final String titleVi;
  final String titleEn;
  final String bodyVi;
  final String bodyEn;
  final IconData icon;
}

/// Tracks which games the player has already seen the tutorial for. Backed by
/// [SharedPreferences] so the walkthrough is truly first-time-only — once a
/// player has seen it, they only get it again from the in-game replay button.
class TutorialStore {
  TutorialStore._();

  static const _prefsKey = 'tutorial.seen';

  static final Set<String> _seen = {};
  static SharedPreferences? _prefs;

  /// Hydrates the in-memory set from disk. Call once at app boot before
  /// presenting the home screen so the very first tap reads the right state.
  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _seen
      ..clear()
      ..addAll(_prefs!.getStringList(_prefsKey) ?? const []);
  }

  static bool hasSeen(String gameId) => _seen.contains(gameId);

  static void markSeen(String gameId) {
    if (!_seen.add(gameId)) return;
    _prefs?.setStringList(_prefsKey, _seen.toList());
  }

  /// Lets the menu offer "play tutorial again" without restarting the app.
  static void reset() {
    _seen.clear();
    _prefs?.remove(_prefsKey);
  }
}

/// Returns the tutorial pages for a game, or an empty list if none is defined.
List<TutorialStep> tutorialFor(String gameId) =>
    _tutorials[gameId] ?? const [];

bool hasTutorial(String gameId) => _tutorials.containsKey(gameId);

const _goalIcon = Icons.flag_rounded;
const _playIcon = Icons.touch_app_rounded;
const _tipIcon = Icons.tips_and_updates_rounded;

final Map<String, List<TutorialStep>> _tutorials = {
  'reaction_tap': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Chạm mục tiêu xuất hiện trên màn hình trước khi nó biến mất.',
      bodyEn: 'Tap each target the moment it appears, before it disappears.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Mục tiêu chỉ hiện trong tích tắc. Chạm trúng được điểm, chậm hoặc trật sẽ mất chuỗi.',
      bodyEn:
          'Targets flash for a split second. Hit them for points; missing or being late breaks your combo.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Giữ ngón tay thả lỏng gần giữa màn hình để phản ứng nhanh hơn.',
      bodyEn: 'Rest your finger near the center of the screen to react faster.',
      icon: _tipIcon,
    ),
  ],
  'memory_grid': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Ghi nhớ những ô sáng rồi chạm lại đúng chúng.',
      bodyEn: 'Memorise the lit tiles, then tap them back in any order.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Lưới sẽ nháy vài ô. Khi đèn tắt, chạm đúng các ô vừa sáng. Mỗi vòng thêm khó hơn.',
      bodyEn:
          'A few tiles flash. After the lights go out, tap exactly the tiles that were lit. Each round adds more.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Hãy ghi nhớ theo hình dáng (đường, hình vuông) thay vì từng ô.',
      bodyEn: 'Chunk tiles into shapes (lines, squares) instead of memorising one by one.',
      icon: _tipIcon,
    ),
  ],
  'stroop': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Chọn MÀU MỰC của chữ — đừng đọc nội dung.',
      bodyEn: 'Pick the INK colour of the word — do not read its meaning.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Ví dụ chữ "XANH" tô màu đỏ → chọn ĐỎ. Chọn đúng được điểm, sai mất chuỗi.',
      bodyEn:
          'Example: the word "BLUE" written in red ink → tap RED. Correct picks score; wrong picks break the streak.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Nheo mắt cho mờ chữ — bạn sẽ nhìn ra màu nhanh hơn.',
      bodyEn: 'Squint a little so the letters blur — colour pops out faster.',
      icon: _tipIcon,
    ),
  ],
  'switch': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Theo luật hiện tại — luật đổi liên tục giữa hình và màu.',
      bodyEn: 'Follow the active rule — it keeps flipping between shape and colour.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Tiêu đề báo "Theo HÌNH" hoặc "Theo MÀU". Chọn ô khớp đúng tiêu chí đó.',
      bodyEn:
          'The header says "Match SHAPE" or "Match COLOUR". Pick the option that fits that rule.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Trước mỗi vòng, đọc tiêu đề một lần thật rõ rồi mới nhìn xuống.',
      bodyEn: 'Read the header out loud once each round before you look at the options.',
      icon: _tipIcon,
    ),
  ],
  'sequence': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm quy luật của dãy số rồi chọn số tiếp theo.',
      bodyEn: 'Spot the pattern in the number sequence and pick the next value.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Mỗi dãy ẩn một luật (+/-, ×, bình phương…). Chọn đáp án đúng để tăng điểm.',
      bodyEn:
          'Each row hides a rule (+/-, ×, squares…). Pick the matching answer to score.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Tính hiệu giữa hai số kế tiếp trước — đó thường là gợi ý đầu tiên.',
      bodyEn: 'Take the difference between adjacent numbers first — that is usually the first clue.',
      icon: _tipIcon,
    ),
  ],
  'quick_math': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tính nhẩm thật nhanh trước khi thời gian hết.',
      bodyEn: 'Solve the arithmetic mentally before the timer runs out.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Chọn đáp án đúng trong 4 lựa chọn. Đúng liên tiếp tăng combo.',
      bodyEn: 'Pick the right answer from four choices. Consecutive hits raise your combo.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Ước lượng độ lớn trước, rồi loại đáp án sai để tiết kiệm thời gian.',
      bodyEn: 'Estimate the magnitude first, then eliminate wrong options to save time.',
      icon: _tipIcon,
    ),
  ],
  'odd_word': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm từ KHÔNG cùng nhóm với những từ còn lại.',
      bodyEn: 'Find the word that does NOT belong with the others.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Bốn từ hiện ra: ba từ cùng chủ đề, một từ lạc. Chạm vào từ lạc đó.',
      bodyEn:
          'Four words appear: three share a theme, one does not. Tap the odd one.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Tìm chủ đề chung của ba từ trước, từ lạc sẽ tự lộ ra.',
      bodyEn: 'Identify the shared theme of three first — the odd one out then jumps out.',
      icon: _tipIcon,
    ),
  ],
  'counting_dots': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Đếm số chấm xuất hiện trên sân càng nhanh càng tốt.',
      bodyEn: 'Count the dots on the board as quickly as you can.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Chọn con số đúng với số chấm bạn thấy.',
      bodyEn: 'Pick the number that matches the dots you see.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Nhóm chấm thành cụm 2–3 thay vì đếm lần lượt từng cái.',
      bodyEn: 'Group dots into clusters of 2 or 3 instead of counting one by one.',
      icon: _tipIcon,
    ),
  ],
  'arrow_flanker': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Theo MŨI TÊN Ở GIỮA — bỏ qua mọi mũi tên bên cạnh.',
      bodyEn: 'Follow the MIDDLE arrow — ignore the ones on the sides.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Hàng mũi tên hiện ra. Chọn hướng của mũi tên ở giữa, dù nhiễu xung quanh chỉ hướng khác.',
      bodyEn:
          'A row of arrows appears. Pick the direction of the centre arrow, even when its neighbours disagree.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Tập trung mắt vào trung tâm — đừng để mắt lướt sang hai bên.',
      bodyEn: 'Lock your eyes onto the centre and resist scanning sideways.',
      icon: _tipIcon,
    ),
  ],
  'bigger_sum': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Chọn vế có kết quả LỚN HƠN giữa hai phép tính.',
      bodyEn: 'Pick the side whose result is LARGER of the two expressions.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Hai phép tính hiện song song. Chạm vào vế bạn nghĩ là lớn hơn.',
      bodyEn: 'Two expressions sit side by side. Tap the one you think is bigger.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Không cần tính chính xác — chỉ cần so sánh tương đối là đủ.',
      bodyEn: 'You do not need the exact answer — a rough comparison is enough.',
      icon: _tipIcon,
    ),
  ],
  'sequence_math': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm số tiếp theo của dãy số đang chạy.',
      bodyEn: 'Find the next number in the running sequence.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Đọc dãy số, tìm quy luật rồi chọn số kế tiếp trong 4 đáp án.',
      bodyEn: 'Read the sequence, infer the rule, then pick the next term from four options.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Thử cộng/trừ trước, rồi nhân/chia, cuối cùng mới đến luật xen kẽ.',
      bodyEn: 'Try add/subtract first, then multiply/divide, and only then alternating rules.',
      icon: _tipIcon,
    ),
  ],
  'balance_eq': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Điền dấu (+, −, ×, ÷) để phép tính cân bằng.',
      bodyEn: 'Fill in the operator (+, −, ×, ÷) that makes the equation true.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Một dấu bị thiếu trong phép tính. Chọn dấu đúng trong các đáp án.',
      bodyEn: 'One operator is missing. Pick the symbol that balances both sides.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Nhìn kết quả: lớn hơn nhiều → nhân, nhỏ → cộng/trừ.',
      bodyEn: 'Inspect the result: much larger → multiply, modest → add/subtract.',
      icon: _tipIcon,
    ),
  ],
  'synonym': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm từ ĐỒNG NGHĨA với từ cho trước.',
      bodyEn: 'Pick the word that means the SAME as the prompt.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Đọc từ gốc, chọn 1 trong 4 từ có nghĩa gần nhất với nó.',
      bodyEn: 'Read the prompt and choose the option closest in meaning.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Loại trước các từ trái nghĩa hoặc khác loại từ rồi mới chọn.',
      bodyEn: 'Eliminate antonyms or wrong word classes first, then choose.',
      icon: _tipIcon,
    ),
  ],
  'first_letter': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Chọn từ bắt đầu bằng chữ cái cho trước.',
      bodyEn: 'Pick the word that starts with the given letter.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Một chữ cái hiện ở trên. Trong 4 từ bên dưới, chỉ 1 từ bắt đầu bằng chữ đó.',
      bodyEn:
          'A letter is shown on top. Of the four words below, only one starts with it.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Quét nhanh chữ cái đầu — bỏ qua nghĩa của từ.',
      bodyEn: 'Scan only the first letter — ignore the meaning of the words.',
      icon: _tipIcon,
    ),
  ],
  'find_target': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm ký hiệu KHÁC BIỆT trong lưới đầy ký hiệu giống nhau.',
      bodyEn: 'Spot the symbol that is DIFFERENT from the rest of the grid.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Chỉ có 1 ô lạ trong lưới. Chạm vào ô đó càng nhanh càng tốt.',
      bodyEn: 'Exactly one tile is the odd one. Tap it as fast as you can.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Quét theo hàng, không nhìn lung tung — bạn sẽ tìm thấy nhanh hơn.',
      bodyEn: 'Scan row by row instead of jumping around — it is faster.',
      icon: _tipIcon,
    ),
  ],
  'odd_hue': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tìm ô có MÀU LỆCH so với các ô còn lại.',
      bodyEn: 'Find the tile whose colour is OFF compared to the rest.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Cả lưới gần như cùng màu, chỉ 1 ô đậm/nhạt hơn. Chạm vào ô đó.',
      bodyEn:
          'The whole grid is nearly one colour with a single tile slightly off. Tap that tile.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Nheo mắt nhẹ để dễ thấy ô lệch màu giữa lưới.',
      bodyEn: 'Squint slightly — the odd tile becomes easier to spot.',
      icon: _tipIcon,
    ),
  ],
  'card_match': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Lật tìm tất cả các cặp thẻ giống nhau.',
      bodyEn: 'Flip to find every matching pair of cards.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Chạm lật 2 thẻ. Trùng nhau giữ nguyên, sai sẽ úp lại. Càng ít lần lật càng được điểm cao.',
      bodyEn:
          'Tap two cards to flip. Matches stay; mismatches flip back. Fewer flips → higher score.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Ghi nhớ vị trí thẻ vừa lật để dùng cho lượt sau.',
      bodyEn: 'Remember the position of every flip — it pays off next turn.',
      icon: _tipIcon,
    ),
  ],
  'lights_out': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Tắt hết các đèn đang sáng trên lưới.',
      bodyEn: 'Turn off every lit cell on the grid.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Chạm 1 ô sẽ đổi trạng thái ô đó cùng 4 ô lân cận. Tìm thứ tự để tắt sạch.',
      bodyEn:
          'Tapping a tile toggles it and its 4 neighbours. Find a sequence that clears the board.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Bắt đầu từ hàng trên cùng và làm việc dần xuống dưới.',
      bodyEn: 'Start from the top row and chase the lights downward.',
      icon: _tipIcon,
    ),
  ],
  'trail_maker': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Nối các số theo đúng thứ tự tăng dần.',
      bodyEn: 'Connect the numbers in ascending order.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Chạm số 1, rồi 2, rồi 3… cho đến hết. Chạm sai bị mất chuỗi.',
      bodyEn: 'Tap 1, then 2, then 3… all the way through. A wrong tap breaks your streak.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Tìm trước số kế tiếp trước khi chạm số hiện tại.',
      bodyEn: 'Spot the next number before you tap the current one.',
      icon: _tipIcon,
    ),
  ],
  'sliding_puzzle': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Trượt các ô về đúng thứ tự từ 1 đến hết.',
      bodyEn: 'Slide the tiles into order from 1 to the end.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi: 'Chạm ô kế bên ô trống để trượt nó vào. Càng ít bước càng tốt.',
      bodyEn: 'Tap a tile next to the gap to slide it in. The fewer moves the better.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Giải hàng trên cùng trước, rồi cột bên trái — phần dưới sẽ dễ hơn.',
      bodyEn: 'Solve the top row first, then the leftmost column — the rest gets easier.',
      icon: _tipIcon,
    ),
  ],
  'rule_shift': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Phân loại theo luật hiện tại — luật sẽ thay đổi liên tục.',
      bodyEn: 'Sort by the current rule — it keeps changing on you.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Mỗi vòng có 1 luật (màu/hình/số). Khi luật đổi, lập tức làm theo luật mới.',
      bodyEn:
          'Each round has a single rule (colour / shape / number). When it switches, snap to the new one.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Nhắc lại tên luật trong đầu mỗi khi nó đổi.',
      bodyEn: 'Repeat the rule name in your head each time it flips.',
      icon: _tipIcon,
    ),
  ],
  'number_bonds': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Ghép 2 con số có tổng bằng mục tiêu cho trước.',
      bodyEn: 'Pair two numbers whose sum equals the target.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Chạm con số đầu tiên rồi con số thứ hai. Nếu tổng đúng mục tiêu, cặp đó biến mất.',
      bodyEn:
          'Tap the first number, then the second. If their sum hits the target, the pair clears.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Tìm trước các số lớn — bạn sẽ biết nó cần ghép với số nhỏ nào.',
      bodyEn: 'Scan for the big numbers first — they tell you which small ones they need.',
      icon: _tipIcon,
    ),
  ],
  'anagram': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Sắp xếp các chữ cái xáo trộn thành từ có nghĩa.',
      bodyEn: 'Rearrange the scrambled letters into a real word.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Chạm chữ cái để đưa lên thanh đáp án. Khi đủ chữ và đúng → ghi điểm.',
      bodyEn:
          'Tap a letter to add it to the answer bar. Complete the word correctly to score.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Bắt đầu từ phụ âm đầu hợp lý nhất rồi suy ra phần còn lại.',
      bodyEn: 'Start from the most plausible first consonant and work outward.',
      icon: _tipIcon,
    ),
  ],
  'even_odd': const [
    TutorialStep(
      titleVi: 'Mục tiêu',
      titleEn: 'Goal',
      bodyVi: 'Theo luật chẵn/lẻ hoặc lớn/nhỏ đang yêu cầu.',
      bodyEn: 'Follow the active rule — even/odd or high/low.',
      icon: _goalIcon,
    ),
    TutorialStep(
      titleVi: 'Cách chơi',
      titleEn: 'How to play',
      bodyVi:
          'Một số hiện ra. Tiêu đề báo bạn cần phân loại theo CHẴN/LẺ hay LỚN/NHỎ rồi chọn ô phù hợp.',
      bodyEn:
          'A number appears. The header tells you to sort by EVEN/ODD or HIGH/LOW — tap the matching side.',
      icon: _playIcon,
    ),
    TutorialStep(
      titleVi: 'Mẹo',
      titleEn: 'Tip',
      bodyVi: 'Luật vừa đổi thường là cái gây sai — đọc lại trước mỗi vòng.',
      bodyEn: 'A rule that just flipped is the trap — re-read the header each round.',
      icon: _tipIcon,
    ),
  ],
};
