import 'package:flutter/material.dart';

import '../../core/i18n/app_lang.dart';
import '../../core/theme/app_palette.dart';

/// The seven cognitive categories games are grouped under.
enum CognitiveGroup {
  speed,
  memory,
  attention,
  flexibility,
  problemSolving,
  math,
  language,
}

extension CognitiveGroupX on CognitiveGroup {
  Color get color => switch (this) {
        CognitiveGroup.speed => AppPalette.reaction,
        CognitiveGroup.memory => AppPalette.memory,
        CognitiveGroup.attention => AppPalette.focus,
        CognitiveGroup.flexibility => AppPalette.flexibility,
        CognitiveGroup.problemSolving => AppPalette.logic,
        CognitiveGroup.math => AppPalette.math,
        CognitiveGroup.language => AppPalette.language,
      };

  String get label => switch (this) {
        CognitiveGroup.speed => L('Tốc độ', 'Speed'),
        CognitiveGroup.memory => L('Trí nhớ', 'Memory'),
        CognitiveGroup.attention => L('Tập trung', 'Attention'),
        CognitiveGroup.flexibility => L('Linh hoạt', 'Flexibility'),
        CognitiveGroup.problemSolving => L('Giải đố', 'Problem'),
        CognitiveGroup.math => L('Toán', 'Math'),
        CognitiveGroup.language => L('Ngôn ngữ', 'Language'),
      };

  IconData get icon => switch (this) {
        CognitiveGroup.speed => Icons.bolt_rounded,
        CognitiveGroup.memory => Icons.psychology_rounded,
        CognitiveGroup.attention => Icons.center_focus_strong_rounded,
        CognitiveGroup.flexibility => Icons.swap_horiz_rounded,
        CognitiveGroup.problemSolving => Icons.extension_rounded,
        CognitiveGroup.math => Icons.calculate_rounded,
        CognitiveGroup.language => Icons.translate_rounded,
      };
}

class GameInfo {
  const GameInfo({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.subtitleVi,
    required this.subtitleEn,
    required this.group,
    required this.icon,
    this.available = false,
  });

  final String id;
  final String titleVi;
  final String titleEn;
  final String subtitleVi;
  final String subtitleEn;
  final CognitiveGroup group;
  final IconData icon;
  final bool available;

  String get title => L(titleVi, titleEn);
  String get subtitle => L(subtitleVi, subtitleEn);
  Color get color => group.color;
}

const List<GameInfo> kGames = [
  GameInfo(
    id: 'reaction_tap',
    titleVi: 'Chạm Nhanh',
    titleEn: 'Quick Tap',
    subtitleVi: 'Chạm mục tiêu trước khi nó biến mất',
    subtitleEn: 'Tap targets before they vanish',
    group: CognitiveGroup.speed,
    icon: Icons.bolt_rounded,
    available: true,
  ),
  GameInfo(
    id: 'memory_grid',
    titleVi: 'Lưới Nhớ',
    titleEn: 'Memory Grid',
    subtitleVi: 'Ghi nhớ vị trí các ô sáng',
    subtitleEn: 'Remember the lit tiles',
    group: CognitiveGroup.memory,
    icon: Icons.grid_view_rounded,
    available: true,
  ),
  GameInfo(
    id: 'stroop',
    titleVi: 'Màu Chữ',
    titleEn: 'Ink Color',
    subtitleVi: 'Chọn màu chữ, đừng đọc nghĩa',
    subtitleEn: 'Pick the ink color, not the word',
    group: CognitiveGroup.attention,
    icon: Icons.palette_rounded,
    available: true,
  ),
  GameInfo(
    id: 'switch',
    titleVi: 'Đảo Chiều',
    titleEn: 'Switch',
    subtitleVi: 'Luật đổi liên tục — bám kịp nhé',
    subtitleEn: 'The rule keeps flipping — keep up',
    group: CognitiveGroup.flexibility,
    icon: Icons.swap_horiz_rounded,
    available: true,
  ),
  GameInfo(
    id: 'sequence',
    titleVi: 'Dòng Số',
    titleEn: 'Number Flow',
    subtitleVi: 'Tìm quy luật của dãy số',
    subtitleEn: 'Find the number pattern',
    group: CognitiveGroup.problemSolving,
    icon: Icons.timeline_rounded,
    available: true,
  ),
  GameInfo(
    id: 'quick_math',
    titleVi: 'Tính Nhanh',
    titleEn: 'Quick Math',
    subtitleVi: 'Tính nhanh trước khi hết giờ',
    subtitleEn: 'Solve fast before time runs out',
    group: CognitiveGroup.math,
    icon: Icons.calculate_rounded,
    available: true,
  ),
  GameInfo(
    id: 'odd_word',
    titleVi: 'Từ Lạc',
    titleEn: 'Odd Word',
    subtitleVi: 'Tìm từ không cùng nhóm',
    subtitleEn: 'Find the word that does not belong',
    group: CognitiveGroup.language,
    icon: Icons.abc_rounded,
    available: true,
  ),
  GameInfo(
    id: 'counting_dots',
    titleVi: 'Đếm Chấm',
    titleEn: 'Counting Dots',
    subtitleVi: 'Đếm số chấm trên sân',
    subtitleEn: 'Count the dots on the board',
    group: CognitiveGroup.math,
    icon: Icons.blur_on_rounded,
    available: true,
  ),
  GameInfo(
    id: 'arrow_flanker',
    titleVi: 'Mũi Tên',
    titleEn: 'Arrows',
    subtitleVi: 'Theo mũi tên giữa, bỏ qua nhiễu',
    subtitleEn: 'Follow the middle arrow, ignore the rest',
    group: CognitiveGroup.flexibility,
    icon: Icons.compare_arrows_rounded,
    available: true,
  ),
  GameInfo(
    id: 'bigger_sum',
    titleVi: 'Vế Lớn Hơn',
    titleEn: 'Bigger Sum',
    subtitleVi: 'Chọn vế có kết quả lớn hơn',
    subtitleEn: 'Pick the bigger result',
    group: CognitiveGroup.math,
    icon: Icons.balance_rounded,
    available: true,
  ),
  GameInfo(
    id: 'sequence_math',
    titleVi: 'Dãy Số',
    titleEn: 'Sequence',
    subtitleVi: 'Tìm số tiếp theo của dãy',
    subtitleEn: 'Find the next number',
    group: CognitiveGroup.math,
    icon: Icons.functions_rounded,
    available: true,
  ),
  GameInfo(
    id: 'balance_eq',
    titleVi: 'Cân Bằng',
    titleEn: 'Balance',
    subtitleVi: 'Điền dấu cho đúng phép tính',
    subtitleEn: 'Fill in the right operator',
    group: CognitiveGroup.math,
    icon: Icons.calculate_rounded,
    available: true,
  ),
  GameInfo(
    id: 'synonym',
    titleVi: 'Đồng Nghĩa',
    titleEn: 'Synonym',
    subtitleVi: 'Ghép từ đồng nghĩa',
    subtitleEn: 'Match the synonym',
    group: CognitiveGroup.language,
    icon: Icons.compare_arrows_rounded,
    available: true,
  ),
  GameInfo(
    id: 'first_letter',
    titleVi: 'Chữ Đầu',
    titleEn: 'First Letter',
    subtitleVi: 'Tìm từ bắt đầu bằng chữ cho trước',
    subtitleEn: 'Find the word starting with the letter',
    group: CognitiveGroup.language,
    icon: Icons.text_fields_rounded,
    available: true,
  ),
  GameInfo(
    id: 'find_target',
    titleVi: 'Tìm Khác',
    titleEn: 'Find Target',
    subtitleVi: 'Tìm ký hiệu khác biệt trong lưới',
    subtitleEn: 'Spot the odd symbol',
    group: CognitiveGroup.attention,
    icon: Icons.search_rounded,
    available: true,
  ),
  GameInfo(
    id: 'odd_hue',
    titleVi: 'Lệch Màu',
    titleEn: 'Odd Hue',
    subtitleVi: 'Tìm ô lệch màu',
    subtitleEn: 'Spot the off-color tile',
    group: CognitiveGroup.attention,
    icon: Icons.gradient_rounded,
    available: true,
  ),
  GameInfo(
    id: 'card_match',
    titleVi: 'Lật Thẻ',
    titleEn: 'Card Match',
    subtitleVi: 'Lật tìm các cặp giống nhau',
    subtitleEn: 'Flip to find matching pairs',
    group: CognitiveGroup.memory,
    icon: Icons.style_rounded,
    available: true,
  ),
  GameInfo(
    id: 'lights_out',
    titleVi: 'Tắt Đèn',
    titleEn: 'Lights Out',
    subtitleVi: 'Tắt hết đèn trên lưới',
    subtitleEn: 'Turn off all the lights',
    group: CognitiveGroup.problemSolving,
    icon: Icons.lightbulb_rounded,
    available: true,
  ),
  GameInfo(
    id: 'trail_maker',
    titleVi: 'Nối Số',
    titleEn: 'Trail Maker',
    subtitleVi: 'Nối các số theo thứ tự',
    subtitleEn: 'Connect numbers in order',
    group: CognitiveGroup.attention,
    icon: Icons.timeline_rounded,
    available: true,
  ),
  GameInfo(
    id: 'sliding_puzzle',
    titleVi: 'Ô Trượt',
    titleEn: 'Sliding Puzzle',
    subtitleVi: 'Trượt ô xếp đúng thứ tự',
    subtitleEn: 'Slide tiles into order',
    group: CognitiveGroup.problemSolving,
    icon: Icons.grid_4x4_rounded,
    available: true,
  ),
  GameInfo(
    id: 'rule_shift',
    titleVi: 'Đổi Luật',
    titleEn: 'Rule Shift',
    subtitleVi: 'Luật phân loại đổi liên tục',
    subtitleEn: 'The sorting rule keeps changing',
    group: CognitiveGroup.flexibility,
    icon: Icons.rule_rounded,
    available: true,
  ),
  GameInfo(
    id: 'number_bonds',
    titleVi: 'Ghép Số',
    titleEn: 'Number Bonds',
    subtitleVi: 'Ghép 2 số bằng mục tiêu',
    subtitleEn: 'Pair two numbers to the target',
    group: CognitiveGroup.math,
    icon: Icons.join_full_rounded,
    available: true,
  ),
  GameInfo(
    id: 'anagram',
    titleVi: 'Xếp Chữ',
    titleEn: 'Anagram',
    subtitleVi: 'Xếp chữ cái thành từ',
    subtitleEn: 'Arrange letters into a word',
    group: CognitiveGroup.language,
    icon: Icons.spellcheck_rounded,
    available: true,
  ),
  GameInfo(
    id: 'even_odd',
    titleVi: 'Chẵn Lẻ',
    titleEn: 'Even / Odd',
    subtitleVi: 'Luật chẵn-lẻ, lớn-nhỏ đổi liên tục',
    subtitleEn: 'Even-odd and high-low rules flip',
    group: CognitiveGroup.flexibility,
    icon: Icons.swap_vert_rounded,
    available: true,
  ),
];
