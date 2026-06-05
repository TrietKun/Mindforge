import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/session/timed_session.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/quiz_top_bar.dart';
import '../../../shared/widgets/result_overlay.dart';

const String _owDir = 'assets/games/odd_word';

// Category banks. Vietnamese and English are kept parallel; each round reads the
// bank that matches the active language. Words avoid cross-category homonyms so
// the "odd one out" is always unambiguous (e.g. yellow/gold stay in metals only).
const Map<String, List<String>> _categoriesVi = {
  'Động vật': ['Hổ', 'Voi', 'Khỉ', 'Sư tử', 'Gấu', 'Cá sấu', 'Hươu', 'Sói'],
  'Trái cây': ['Táo', 'Cam', 'Chuối', 'Xoài', 'Nho', 'Dứa', 'Ổi', 'Mận'],
  'Rau củ': [
    'Cà rốt', 'Khoai tây', 'Bắp cải', 'Cà chua', 'Hành', 'Tỏi', 'Súp lơ',
    'Dưa chuột'
  ],
  'Phương tiện': [
    'Ô tô', 'Xe máy', 'Tàu hỏa', 'Máy bay', 'Thuyền', 'Xe đạp', 'Trực thăng',
    'Tàu điện'
  ],
  'Màu sắc': ['Đỏ', 'Xanh dương', 'Lục', 'Tím', 'Xám', 'Nâu', 'Hồng', 'Đen'],
  'Nghề nghiệp': [
    'Bác sĩ', 'Giáo viên', 'Kỹ sư', 'Luật sư', 'Đầu bếp', 'Phi công',
    'Nông dân', 'Họa sĩ'
  ],
  'Thể thao': [
    'Bóng đá', 'Bơi lội', 'Tennis', 'Bóng rổ', 'Cầu lông', 'Đua xe',
    'Bóng chuyền', 'Đấm bốc'
  ],
  'Nội thất': ['Ghế', 'Bàn', 'Tủ', 'Giường', 'Kệ sách', 'Đèn', 'Sofa', 'Gương'],
  'Nhạc cụ': [
    'Guitar', 'Piano', 'Trống', 'Sáo', 'Violin', 'Kèn', 'Đàn tranh', 'Harmonica'
  ],
  'Quốc gia': [
    'Việt Nam', 'Nhật Bản', 'Pháp', 'Brazil', 'Canada', 'Ai Cập', 'Thái Lan',
    'Đức'
  ],
  'Hành tinh': [
    'Sao Thủy', 'Sao Kim', 'Trái Đất', 'Sao Hỏa', 'Sao Mộc', 'Sao Thổ',
    'Thiên Vương', 'Hải Vương'
  ],
  'Bộ phận cơ thể': ['Tay', 'Chân', 'Đầu', 'Mắt', 'Mũi', 'Tai', 'Miệng', 'Vai'],
  'Đồ uống': [
    'Nước', 'Trà', 'Cà phê', 'Sữa', 'Nước ép', 'Soda', 'Bia', 'Sinh tố'
  ],
  'Thời tiết': ['Mưa', 'Nắng', 'Gió', 'Bão', 'Tuyết', 'Sương mù', 'Sấm', 'Mây'],
  'Trang phục': [
    'Áo sơ mi', 'Quần', 'Váy', 'Áo khoác', 'Mũ', 'Tất', 'Giày', 'Khăn'
  ],
  'Côn trùng': [
    'Kiến', 'Ong', 'Bướm', 'Muỗi', 'Ruồi', 'Châu chấu', 'Bọ cánh cứng',
    'Chuồn chuồn'
  ],
  'Chim': [
    'Đại bàng', 'Chim sẻ', 'Vẹt', 'Cú', 'Bồ câu', 'Công', 'Hạc',
    'Chim cánh cụt'
  ],
  'Hải sản': ['Cá', 'Tôm', 'Cua', 'Mực', 'Sò', 'Ốc', 'Bạch tuộc', 'Hàu'],
  'Hoa': [
    'Hoa hồng', 'Cúc', 'Sen', 'Lan', 'Tulip', 'Hướng dương', 'Ly', 'Nhài'
  ],
  'Kim loại': ['Sắt', 'Vàng', 'Bạc', 'Đồng', 'Nhôm', 'Chì', 'Kẽm', 'Thiếc'],
  'Hình học': [
    'Hình tròn', 'Hình vuông', 'Tam giác', 'Hình chữ nhật', 'Ngũ giác',
    'Lục giác', 'Hình thoi', 'Hình bầu dục'
  ],
  'Cảm xúc': [
    'Vui', 'Buồn', 'Giận', 'Sợ', 'Ngạc nhiên', 'Lo lắng', 'Hạnh phúc', 'Chán'
  ],
  'Dụng cụ học tập': [
    'Bút chì', 'Tẩy', 'Thước', 'Vở', 'Bút mực', 'Cặp sách', 'Compa', 'Bút màu'
  ],
  'Tráng miệng': [
    'Bánh kem', 'Kem', 'Sô cô la', 'Bánh quy', 'Kẹo', 'Pudding', 'Donut',
    'Bánh nướng'
  ],
};

const Map<String, List<String>> _categoriesEn = {
  'Animals': [
    'Tiger', 'Elephant', 'Monkey', 'Lion', 'Bear', 'Crocodile', 'Deer', 'Wolf'
  ],
  'Fruits': [
    'Apple', 'Orange', 'Banana', 'Mango', 'Grape', 'Pineapple', 'Guava', 'Plum'
  ],
  'Vegetables': [
    'Carrot', 'Potato', 'Cabbage', 'Tomato', 'Onion', 'Garlic', 'Cauliflower',
    'Cucumber'
  ],
  'Vehicles': [
    'Car', 'Motorbike', 'Train', 'Airplane', 'Boat', 'Bicycle', 'Helicopter',
    'Tram'
  ],
  'Colors': ['Red', 'Blue', 'Green', 'Purple', 'Gray', 'Brown', 'Pink', 'Black'],
  'Jobs': [
    'Doctor', 'Teacher', 'Engineer', 'Lawyer', 'Chef', 'Pilot', 'Farmer',
    'Painter'
  ],
  'Sports': [
    'Soccer', 'Swimming', 'Tennis', 'Basketball', 'Badminton', 'Racing',
    'Volleyball', 'Boxing'
  ],
  'Furniture': [
    'Chair', 'Table', 'Wardrobe', 'Bed', 'Bookshelf', 'Lamp', 'Sofa', 'Mirror'
  ],
  'Instruments': [
    'Guitar', 'Piano', 'Drum', 'Flute', 'Violin', 'Trumpet', 'Harp', 'Harmonica'
  ],
  'Countries': [
    'Vietnam', 'Japan', 'France', 'Brazil', 'Canada', 'Egypt', 'Thailand',
    'Germany'
  ],
  'Planets': [
    'Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus',
    'Neptune'
  ],
  'Body parts': ['Hand', 'Leg', 'Head', 'Eye', 'Nose', 'Ear', 'Mouth',
    'Shoulder'],
  'Drinks': [
    'Water', 'Tea', 'Coffee', 'Milk', 'Juice', 'Soda', 'Beer', 'Smoothie'
  ],
  'Weather': ['Rain', 'Sun', 'Wind', 'Storm', 'Snow', 'Fog', 'Thunder', 'Cloud'],
  'Clothing': [
    'Shirt', 'Pants', 'Skirt', 'Jacket', 'Hat', 'Socks', 'Shoes', 'Scarf'
  ],
  'Insects': [
    'Ant', 'Bee', 'Butterfly', 'Mosquito', 'Fly', 'Grasshopper', 'Beetle',
    'Dragonfly'
  ],
  'Birds': [
    'Eagle', 'Sparrow', 'Parrot', 'Owl', 'Pigeon', 'Peacock', 'Crane', 'Penguin'
  ],
  'Sea creatures': [
    'Fish', 'Shrimp', 'Crab', 'Squid', 'Clam', 'Snail', 'Octopus', 'Oyster'
  ],
  'Flowers': [
    'Rose', 'Daisy', 'Lotus', 'Orchid', 'Tulip', 'Sunflower', 'Lily', 'Jasmine'
  ],
  'Metals': ['Iron', 'Gold', 'Silver', 'Copper', 'Aluminum', 'Lead', 'Zinc',
    'Tin'],
  'Shapes': [
    'Circle', 'Square', 'Triangle', 'Rectangle', 'Pentagon', 'Hexagon',
    'Rhombus', 'Oval'
  ],
  'Emotions': [
    'Happy', 'Sad', 'Angry', 'Scared', 'Surprised', 'Anxious', 'Joyful', 'Bored'
  ],
  'School supplies': [
    'Pencil', 'Eraser', 'Ruler', 'Notebook', 'Pen', 'Backpack', 'Compass',
    'Crayon'
  ],
  'Desserts': [
    'Cake', 'Ice cream', 'Chocolate', 'Cookie', 'Candy', 'Pudding', 'Donut',
    'Pie'
  ],
};

/// The category bank for the active language.
Map<String, List<String>> get _categories =>
    appLang.value == AppLang.vi ? _categoriesVi : _categoriesEn;

class _Round {
  const _Round(this.words, this.oddIndex);
  final List<String> words;
  final int oddIndex;
}

class OddWordScreen extends StatefulWidget {
  const OddWordScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<OddWordScreen> createState() => _OddWordScreenState();
}

class _OddWordScreenState extends State<OddWordScreen> with TimedSessionMixin {
  static const Color _accent = AppPalette.language;

  final _rng = math.Random();
  late _Round _round;
  int _roundId = 0;
  int? _wrongIndex;

  // Visual feedback state (never touches scoring/logic).
  Timer? _winTimer;
  int _fxId = 0;
  bool _showWin = false;
  int _winCombo = 0;

  @override
  double get sessionSeconds => 40;

  double get _penalty => switch (widget.difficulty) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.5,
        Difficulty.hard => 2.0,
      };

  @override
  void initState() {
    super.initState();
    _round = _generate();
    // Switching language mid-game must reshuffle into the new word bank, else the
    // current round keeps showing the previous language.
    appLang.addListener(_onLangChanged);
    startSession();
  }

  @override
  void dispose() {
    _winTimer?.cancel();
    appLang.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (!mounted || finished) return;
    setState(() {
      _wrongIndex = null;
      _round = _generate();
      _roundId++;
    });
  }

  @override
  void onSessionFinished() => setState(() {});

  _Round _generate() {
    final keys = _categories.keys.toList();
    final mainKey = keys[_rng.nextInt(keys.length)];
    String oddKey;
    do {
      oddKey = keys[_rng.nextInt(keys.length)];
    } while (oddKey == mainKey);

    final mainWords = [..._categories[mainKey]!]..shuffle(_rng);
    final oddWord = ([..._categories[oddKey]!]..shuffle(_rng)).first;

    final words = mainWords.take(3).toList();
    final oddIndex = _rng.nextInt(4);
    words.insert(oddIndex, oddWord);
    return _Round(words, oddIndex);
  }

  void _answer(int index) {
    if (finished) return;
    if (index == _round.oddIndex) {
      registerCorrect(
        points: (c) =>
            (12 * (1 + c ~/ 3) * widget.difficulty.scoreMultiplier).round(),
        flashColor: _accent.withValues(alpha: 0.14),
      );
      final winCombo = combo;
      setState(() {
        _wrongIndex = null;
        _winCombo = winCombo;
        _showWin = true;
        _fxId++;
        _round = _generate();
        _roundId++;
      });
      _winTimer?.cancel();
      _winTimer = Timer(const Duration(milliseconds: 760), () {
        if (mounted) setState(() => _showWin = false);
      });
    } else {
      registerWrong(
        penalty: _penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() => _wrongIndex = index);
    }
  }

  void _restart() {
    setState(() {
      _wrongIndex = null;
      _showWin = false;
      _round = _generate();
      _roundId++;
    });
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.language, AppPalette.reaction],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            const Positioned.fill(child: _FloatingLetters()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  children: [
                    QuizTopBar(
                      score: score,
                      combo: combo,
                      progress: progress,
                      accent: _accent,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const _OddWordHeader(),
                    const SizedBox(height: Insets.md),
                    Text(
                      L('Từ nào không cùng nhóm?', 'Which word does not belong?'),
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: Insets.lg),
                    Column(
                      key: ValueKey(_roundId),
                      children: [
                        for (var i = 0; i < _round.words.length; i++)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: Insets.md),
                            child: _WordButton(
                              word: _round.words[i],
                              isWrong: _wrongIndex == i,
                              onTap: () => _answer(i),
                            )
                                .animate(key: ValueKey('$_roundId-$i'))
                                .fadeIn(delay: (i * 60).ms, duration: 200.ms)
                                .slideX(begin: 0.12, curve: Curves.easeOut),
                          ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            if (_showWin) _buildWinFx(),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _accent,
                iconAsset: 'assets/games/odd_word/trophy.png',
                icon: Icons.translate_rounded,
                stats: [
                  ResultStat(L('Đúng', 'Correct'), '$hits'),
                  ResultStat('Combo', 'x$bestCombo'),
                  ResultStat(L('Chính xác', 'Accuracy'), '$accuracy%'),
                ],
                onRetry: _restart,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }

  /// Reward burst at the centre when the odd word is found: a glowing
  /// highlight + halo, radial burst, confetti, sparkle and a check pop.
  /// Higher combo adds a spark and an expanding ring.
  Widget _buildWinFx() {
    final strong = _winCombo >= 3;
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Image.asset('$_owDir/highlight.png', width: 230)
                  .animate(key: ValueKey('hl$_fxId'))
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.15, 1.15),
                      duration: 320.ms,
                      curve: Curves.easeOut)
                  .fadeOut(delay: 240.ms, duration: 280.ms),
              Image.asset('$_owDir/halo.png', width: 200)
                  .animate(key: ValueKey('halo$_fxId'))
                  .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.easeOut)
                  .fadeOut(delay: 220.ms, duration: 260.ms),
              if (strong)
                Image.asset('$_owDir/ring.png', width: 250)
                    .animate(key: ValueKey('ring$_fxId'))
                    .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1.15, 1.15),
                        duration: 360.ms,
                        curve: Curves.easeOut)
                    .fadeOut(delay: 260.ms, duration: 280.ms),
              Image.asset('$_owDir/burst.png', width: 210)
                  .animate(key: ValueKey('burst$_fxId'))
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.easeOut)
                  .fadeOut(delay: 220.ms, duration: 260.ms),
              Image.asset('$_owDir/confetti.png', width: 230)
                  .animate(key: ValueKey('conf$_fxId'))
                  .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.1, 1.1),
                      delay: 120.ms,
                      duration: 340.ms,
                      curve: Curves.easeOut)
                  .fadeOut(delay: 380.ms, duration: 280.ms),
              if (strong)
                Image.asset('$_owDir/spark.png', width: 240)
                    .animate(key: ValueKey('spark$_fxId'))
                    .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1),
                        duration: 280.ms,
                        curve: Curves.easeOutBack)
                    .fadeOut(delay: 240.ms, duration: 240.ms),
              Image.asset('$_owDir/sparkle.png', width: 80)
                  .animate(key: ValueKey('sp$_fxId'))
                  .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                      delay: 80.ms,
                      duration: 260.ms,
                      curve: Curves.easeOutBack)
                  .then()
                  .fadeOut(duration: 220.ms),
              Image.asset('$_owDir/check.png', width: 64)
                  .animate(key: ValueKey('chk$_fxId'))
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      duration: 360.ms,
                      curve: Curves.easeOutBack)
                  .then(delay: 220.ms)
                  .fadeOut(duration: 240.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header: a book, a gently bobbing magnifier (the "search" motif) and the
/// scholarly owl mascot.
class _OddWordHeader extends StatelessWidget {
  const _OddWordHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('$_owDir/book.png', width: 44, height: 44),
          const SizedBox(width: 10),
          Image.asset('$_owDir/magnifier.png', width: 52, height: 52)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                  begin: -4, end: 4, duration: 1500.ms, curve: Curves.easeInOut),
          const SizedBox(width: 10),
          Image.asset('$_owDir/owl_mascot.png', width: 48, height: 48),
        ],
      ),
    );
  }
}

/// Faint vocabulary letters drifting in the background.
class _FloatingLetters extends StatelessWidget {
  const _FloatingLetters();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 110,
            left: 16,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset('$_owDir/letters.png', width: 150)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: -10,
                      end: 10,
                      duration: 4200.ms,
                      curve: Curves.easeInOut),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 12,
            child: Opacity(
              opacity: 0.10,
              child: Image.asset('$_owDir/letters.png', width: 120)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: 8,
                      end: -8,
                      duration: 4800.ms,
                      curve: Curves.easeInOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordButton extends StatefulWidget {
  const _WordButton({
    required this.word,
    required this.isWrong,
    required this.onTap,
  });
  final String word;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  State<_WordButton> createState() => _WordButtonState();
}

class _WordButtonState extends State<_WordButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset('$_owDir/word_btn.png', fit: BoxFit.fill),
              ),
              if (widget.isWrong)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      color: AppPalette.danger.withValues(alpha: 0.26),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.isWrong)
                Positioned(
                  right: 14,
                  child: Image.asset('$_owDir/cross.png', width: 30)
                      .animate(key: ValueKey('x${widget.word}'))
                      .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1, 1),
                          duration: 240.ms,
                          curve: Curves.easeOutBack),
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.isWrong) {
      return base.animate().shake(hz: 4, rotation: 0.015, duration: 320.ms);
    }
    return base;
  }
}
