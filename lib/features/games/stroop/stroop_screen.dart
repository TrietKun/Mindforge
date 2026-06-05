import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/difficulty.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/result_overlay.dart';

class _Ink {
  const _Ink(this.label, this.color, this.asset);
  final String label;
  final Color color;
  final String asset; // glossy paint-drop sprite for this ink
}

const String _stroopDir = 'assets/games/stroop';
const List<_Ink> _inks = [
  _Ink('ĐỎ', Color(0xFFFB5871), '$_stroopDir/ink_red.png'),
  _Ink('XANH', Color(0xFF38BDF8), '$_stroopDir/ink_blue.png'),
  _Ink('VÀNG', Color(0xFFFFC857), '$_stroopDir/ink_yellow.png'),
  _Ink('LỤC', Color(0xFF4ADE80), '$_stroopDir/ink_green.png'),
  _Ink('TÍM', Color(0xFFA855F7), '$_stroopDir/ink_purple.png'),
];

class StroopScreen extends StatefulWidget {
  const StroopScreen({super.key, this.difficulty = Difficulty.medium});

  final Difficulty difficulty;

  @override
  State<StroopScreen> createState() => _StroopScreenState();
}

class _StroopScreenState extends State<StroopScreen> {
  static const double _sessionSeconds = 30;

  final _rng = math.Random();
  Timer? _ticker;

  ({double trap, double penalty}) get _tune => switch (widget.difficulty) {
        Difficulty.easy => (trap: 0.45, penalty: 1.0),
        Difficulty.medium => (trap: 0.7, penalty: 1.5),
        Difficulty.hard => (trap: 0.85, penalty: 2.2),
      };

  double _timeLeft = _sessionSeconds;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _hits = 0;
  int _misses = 0;
  bool _finished = false;

  late _Ink _word; // which color name is written
  late _Ink _ink; // the color it is painted in (the answer)
  late List<_Ink> _options;
  int _promptId = 0;
  Color? _flash;
  String? _feedbackAsset;
  int _feedbackId = 0;
  bool _showCelebrate = false;

  @override
  void initState() {
    super.initState();
    _nextPrompt();
    _start();
  }

  void _start() {
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finish();
        }
      });
    });
  }

  void _nextPrompt() {
    _word = _inks[_rng.nextInt(_inks.length)];
    // The ink often differs from the word — that is the trap (rate by level).
    if (_rng.nextDouble() < _tune.trap) {
      do {
        _ink = _inks[_rng.nextInt(_inks.length)];
      } while (_ink.label == _word.label);
    } else {
      _ink = _word;
    }

    final options = <_Ink>{_ink};
    while (options.length < 4) {
      options.add(_inks[_rng.nextInt(_inks.length)]);
    }
    _options = options.toList()..shuffle(_rng);
    _promptId++;
  }

  void _answer(_Ink choice) {
    if (_finished) return;
    if (choice.color == _ink.color) {
      HapticFeedback.lightImpact();
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      _hits++;
      setState(() {
        _score += (10 * (1 + _combo ~/ 4) * widget.difficulty.scoreMultiplier)
            .round();
        _flash = _ink.color.withValues(alpha: 0.16);
        _feedbackAsset = 'assets/games/stroop/check.png';
        _feedbackId++;
        _showCelebrate = true;
        _nextPrompt();
      });
    } else {
      HapticFeedback.heavyImpact();
      _combo = 0;
      _misses++;
      setState(() {
        _timeLeft = math.max(0, _timeLeft - _tune.penalty); // penalty
        _flash = AppPalette.danger.withValues(alpha: 0.2);
        _feedbackAsset = 'assets/games/stroop/cross.png';
        _feedbackId++;
        _nextPrompt();
      });
    }
    // Clear the flash shortly after.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _flash = null);
    });
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        setState(() {
          _feedbackAsset = null;
          _showCelebrate = false;
        });
      }
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    HapticFeedback.mediumImpact();
  }

  void _restart() {
    setState(() {
      _timeLeft = _sessionSeconds;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _hits = 0;
      _misses = 0;
      _finished = false;
      _flash = null;
      _nextPrompt();
    });
    _ticker?.cancel();
    _start();
  }

  int get _accuracy {
    final total = _hits + _misses;
    if (total == 0) return 100;
    return ((_hits / total) * 100).round();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_timeLeft / _sessionSeconds).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: const [AppPalette.focus, AppPalette.memory],
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: _flash ?? Colors.transparent,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        Text('$_score',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppPalette.focus)),
                        const Spacer(),
                        _ComboChip(combo: _combo),
                      ],
                    ),
                    const SizedBox(height: Insets.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppPalette.surfaceHigh,
                        valueColor: AlwaysStoppedAnimation(
                          Color.lerp(
                              AppPalette.danger, AppPalette.focus, progress)!,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Image.asset('assets/games/stroop/eye.png',
                        width: 54, height: 54),
                    const SizedBox(height: Insets.md),
                    Text(
                      L('Chọn MÀU của chữ', 'Pick the INK color'),
                      style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 14,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: Insets.lg),
                    // The Stroop word, framed by the neon word-frame sprite.
                    SizedBox(
                      key: ValueKey(_promptId),
                      height: 130,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset('$_stroopDir/word_frame.png',
                                fit: BoxFit.fill),
                          ),
                          Text(
                            _word.label,
                            style: TextStyle(
                              color: _ink.color,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(key: ValueKey(_promptId))
                        .fadeIn(duration: 160.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut)
                        .scale(
                            begin: const Offset(0.9, 0.9),
                            curve: Curves.easeOutBack),
                    const Spacer(),
                    // Answer buttons
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: Insets.md,
                      crossAxisSpacing: Insets.md,
                      childAspectRatio: 2.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final option in _options)
                          _ColorButton(
                            ink: option,
                            onTap: () => _answer(option),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_showCelebrate)
              IgnorePointer(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('$_stroopDir/burst.png', width: 220)
                          .animate(key: ValueKey('cb$_feedbackId'))
                          .scale(
                              begin: const Offset(0.4, 0.4),
                              curve: Curves.easeOut,
                              duration: 360.ms)
                          .fadeOut(delay: 180.ms, duration: 300.ms),
                      Image.asset('$_stroopDir/sparkle.png', width: 90)
                          .animate(key: ValueKey('cs$_feedbackId'))
                          .scale(
                              begin: const Offset(0.3, 0.3),
                              curve: Curves.easeOutBack,
                              duration: 300.ms)
                          .then()
                          .fadeOut(duration: 220.ms),
                    ],
                  ),
                ),
              ),
            if (_feedbackAsset != null)
              IgnorePointer(
                child: Center(
                  child: Image.asset(_feedbackAsset!, width: 96, height: 96)
                      .animate(key: ValueKey(_feedbackId))
                      .scale(
                          begin: const Offset(0.4, 0.4),
                          curve: Curves.easeOutBack,
                          duration: 240.ms)
                      .then()
                      .fadeOut(delay: 140.ms, duration: 280.ms),
                ),
              ),
            if (_finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: _score,
                scoreSuffix: L('điểm', 'pts'),
                accent: AppPalette.focus,
                iconAsset: 'assets/games/stroop/trophy.png',
                icon: Icons.center_focus_strong_rounded,
                stats: [
                  ResultStat('Combo', 'x$_bestCombo'),
                  ResultStat(L('Chính xác', 'Accuracy'), '$_accuracy%'),
                  ResultStat(L('Đúng', 'Correct'), '$_hits'),
                ],
                onRetry: _restart,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatefulWidget {
  const _ColorButton({required this.ink, required this.onTap});
  final _Ink ink;
  final VoidCallback onTap;

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inset so the neon frame never touches the grid cell edge.
            Positioned(
              left: 4,
              right: 4,
              top: 4,
              bottom: 4,
              child: Image.asset('$_stroopDir/pad.png', fit: BoxFit.fill),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(widget.ink.asset, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    final active = combo >= 2;
    return AnimatedOpacity(
      opacity: active ? 1 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppPalette.focus, AppPalette.success])
              : null,
          color: active ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'x$combo',
          style: TextStyle(
            color: active ? Colors.black : AppPalette.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ).animate(target: active ? 1 : 0).scaleXY(begin: 1, end: 1.1, duration: 130.ms);
  }
}
