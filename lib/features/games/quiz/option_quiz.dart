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

/// A single answer choice — either a text label or a color swatch.
class QuizOption {
  const QuizOption.text(this.text)
      : color = null,
        asset = null;
  const QuizOption.color(this.color)
      : text = null,
        asset = null;
  const QuizOption.asset(this.asset)
      : text = null,
        color = null;
  final String? text;
  final Color? color;
  final String? asset;
}

/// One generated question: a prompt (rendered by the spec) and its options.
class QuizRound {
  const QuizRound({
    required this.options,
    required this.answerIndex,
    this.data,
  });
  final List<QuizOption> options;
  final int answerIndex;
  final Object? data; // arbitrary payload for the prompt builder
}

/// Optional rich-FX pack for a [QuizSpec]. When set, the engine renders a fuller
/// celebration (burst/confetti/ring/streak + combo spark), a wrong-answer cross
/// flash + screen-shake, and a pulsing header icon. Specs that leave this null
/// keep the lightweight default behaviour.
class QuizFx {
  const QuizFx({
    this.header,
    this.headerHalo,
    this.cross,
    this.shimmer,
    this.screenShake = false,
    this.winBuilder,
  });

  final String? header;
  final String? headerHalo;
  final String? cross;
  final String? shimmer;
  final bool screenShake;

  /// When set, fully replaces the default correct-answer FX. Receives the spark
  /// id (changes per correct answer), the current combo and the answered option
  /// index — letting a spec render a bespoke celebration with its own assets.
  final Widget Function(int sparkId, int combo, int answerIndex)? winBuilder;
}

/// Declarative description of a timed multiple-choice game. Most MindForge
/// games are just a [QuizSpec]; the engine below handles the rest.
class QuizSpec {
  const QuizSpec({
    required this.title,
    required this.accent,
    required this.icon,
    required this.instruction,
    required this.generate,
    required this.buildPrompt,
    this.iconAsset,
    this.sparkAsset,
    this.fx,
    this.sessionSeconds = 40,
    this.basePoints = 12,
    this.comboDiv = 3,
    this.optionsPerRow = 2,
    this.penalties = const {
      Difficulty.easy: 1.0,
      Difficulty.medium: 1.5,
      Difficulty.hard: 2.0,
    },
  });

  /// Optional rich-FX pack (see [QuizFx]).
  final QuizFx? fx;

  final String title;
  final Color accent;
  final IconData icon;
  final String? iconAsset;

  /// Sparkle sprite shown on a correct answer (defaults to the shared kit one).
  final String? sparkAsset;

  /// A thunk so the language toggle re-evaluates it at build time.
  final String Function() instruction;
  final double sessionSeconds;
  final int basePoints;
  final int comboDiv;
  final int optionsPerRow;
  final Map<Difficulty, double> penalties;

  /// Builds the next question. [solved] is how many correct so far (for ramps).
  final QuizRound Function(int solved, Difficulty difficulty, math.Random rng)
      generate;

  /// Renders the big prompt card content for a round.
  final Widget Function(BuildContext context, QuizRound round) buildPrompt;
}

class OptionQuizScreen extends StatefulWidget {
  const OptionQuizScreen({
    super.key,
    required this.spec,
    this.difficulty = Difficulty.medium,
  });

  final QuizSpec spec;
  final Difficulty difficulty;

  @override
  State<OptionQuizScreen> createState() => _OptionQuizScreenState();
}

class _OptionQuizScreenState extends State<OptionQuizScreen>
    with TimedSessionMixin {
  final _rng = math.Random();
  late QuizRound _round;
  int _roundId = 0;
  int _solved = 0;
  int? _wrongIndex;
  bool _showSpark = false;
  int _sparkId = 0;

  // Rich-FX state (only exercised when the spec provides [QuizSpec.fx]).
  bool _showCross = false;
  int _wrongId = 0;
  int _winCombo = 0;
  int _winAnswerIndex = 0;
  Timer? _sparkTimer;
  Timer? _crossTimer;

  String get _sparkAsset => _spec.sparkAsset ?? 'assets/kit/sparkle.png';

  QuizSpec get _spec => widget.spec;

  @override
  void dispose() {
    _sparkTimer?.cancel();
    _crossTimer?.cancel();
    super.dispose();
  }

  @override
  double get sessionSeconds => _spec.sessionSeconds;

  double get _penalty =>
      _spec.penalties[widget.difficulty] ?? 1.5;

  @override
  void initState() {
    super.initState();
    _round = _spec.generate(_solved, widget.difficulty, _rng);
    startSession();
  }

  @override
  void onSessionFinished() => setState(() {});

  void _answer(int index) {
    if (finished) return;
    if (index == _round.answerIndex) {
      _solved++;
      final winAnswerIndex = _round.answerIndex;
      registerCorrect(
        points: (c) => (_spec.basePoints *
                (1 + c ~/ _spec.comboDiv) *
                widget.difficulty.scoreMultiplier)
            .round(),
        flashColor: _spec.accent.withValues(alpha: 0.14),
      );
      final winCombo = combo;
      setState(() {
        _wrongIndex = null;
        _showSpark = true;
        _sparkId++;
        _winCombo = winCombo;
        _winAnswerIndex = winAnswerIndex;
        _round = _spec.generate(_solved, widget.difficulty, _rng);
        _roundId++;
      });
      _sparkTimer?.cancel();
      _sparkTimer = Timer(const Duration(milliseconds: 760), () {
        if (mounted) setState(() => _showSpark = false);
      });
    } else {
      registerWrong(
        penalty: _penalty,
        flashColor: AppPalette.danger.withValues(alpha: 0.2),
      );
      setState(() {
        _wrongIndex = index;
        if (_spec.fx?.cross != null) {
          _showCross = true;
          _wrongId++;
        }
      });
      if (_spec.fx?.cross != null) {
        _crossTimer?.cancel();
        _crossTimer = Timer(const Duration(milliseconds: 460), () {
          if (mounted) setState(() => _showCross = false);
        });
      }
    }
  }

  void _restart() {
    setState(() {
      _solved = 0;
      _wrongIndex = null;
      _round = _spec.generate(_solved, widget.difficulty, _rng);
      _roundId++;
    });
    startSession();
  }

  /// Correct-answer celebration. A spec can fully customise it via
  /// [QuizFx.winBuilder]; otherwise it's the lightweight sparkle.
  Widget _buildCorrectFx() {
    final builder = _spec.fx?.winBuilder;
    if (builder != null) {
      return IgnorePointer(
          child: builder(_sparkId, _winCombo, _winAnswerIndex));
    }
    return IgnorePointer(
      child: Center(
        child: Image.asset(_sparkAsset, width: 120)
            .animate(key: ValueKey(_sparkId))
            .scale(
                begin: const Offset(0.3, 0.3),
                curve: Curves.easeOutBack,
                duration: 260.ms)
            .then()
            .fadeOut(delay: 120.ms, duration: 240.ms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AuroraBackground(
        blobs: [_spec.accent, AppPalette.focus],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: flash ?? Colors.transparent,
            ),
            SafeArea(
              child: _ShakeIf(
                shake: _spec.fx?.screenShake ?? false,
                trigger: _wrongId,
                child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  children: [
                    QuizTopBar(
                      score: score,
                      combo: combo,
                      progress: progress,
                      accent: _spec.accent,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    if (_spec.fx?.header != null)
                      _QuizHeader(
                        asset: _spec.fx!.header!,
                        halo: _spec.fx!.headerHalo,
                      ),
                    Text(
                      _spec.instruction(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: Insets.lg),
                    Container(
                      key: ValueKey(_roundId),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.lg, vertical: Insets.xl),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: BorderRadius.circular(Radii.lg),
                        border: Border.all(color: AppPalette.stroke),
                      ),
                      alignment: Alignment.center,
                      child: _spec.buildPrompt(context, _round),
                    )
                        .animate(key: ValueKey(_roundId))
                        .fadeIn(duration: 160.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut)
                        .scale(
                            begin: const Offset(0.92, 0.92),
                            curve: Curves.easeOutBack),
                    const Spacer(),
                    _Options(
                      round: _round,
                      accent: _spec.accent,
                      perRow: _spec.optionsPerRow,
                      wrongIndex: _wrongIndex,
                      onTap: _answer,
                    ),
                  ],
                ),
              ),
              ),
            ),
            if (_showSpark) _buildCorrectFx(),
            if (_showSpark &&
                _spec.fx?.shimmer != null &&
                _winCombo >= 6 &&
                _winCombo % 3 == 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Image.asset(_spec.fx!.shimmer!,
                            width: MediaQuery.of(context).size.width * 1.2,
                            fit: BoxFit.fitWidth)
                        .animate(key: ValueKey('shim$_sparkId'))
                        .slideX(
                            begin: -1.4,
                            end: 1.4,
                            duration: 720.ms,
                            curve: Curves.easeInOut)
                        .fadeOut(delay: 520.ms, duration: 200.ms),
                  ),
                ),
              ),
            if (_showCross && _spec.fx?.cross != null)
              IgnorePointer(
                child: Center(
                  child: Image.asset(_spec.fx!.cross!, width: 108)
                      .animate(key: ValueKey('x$_wrongId'))
                      .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                          duration: 200.ms,
                          curve: Curves.easeOutBack)
                      .then(delay: 120.ms)
                      .fadeOut(duration: 220.ms),
                ),
              ),
            if (finished)
              ResultOverlay(
                title: L('Hết giờ!', 'Time up!'),
                score: score,
                scoreSuffix: L('điểm', 'pts'),
                accent: _spec.accent,
                iconAsset: _spec.iconAsset,
                icon: _spec.icon,
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
}

class _Options extends StatelessWidget {
  const _Options({
    required this.round,
    required this.accent,
    required this.perRow,
    required this.wrongIndex,
    required this.onTap,
  });

  final QuizRound round;
  final Color accent;
  final int perRow;
  final int? wrongIndex;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    if (perRow == 1) {
      return Column(
        children: [
          for (var i = 0; i < round.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: _OptionButton(
                option: round.options[i],
                accent: accent,
                isWrong: wrongIndex == i,
                fullWidth: true,
                onTap: () => onTap(i),
              ),
            ),
        ],
      );
    }
    final hasAsset = round.options.any((o) => o.asset != null);
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: perRow,
      mainAxisSpacing: Insets.md,
      crossAxisSpacing: Insets.md,
      childAspectRatio: hasAsset ? 1.6 : (perRow == 3 ? 1.6 : 2.4),
      clipBehavior: Clip.none,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < round.options.length; i++)
          _OptionButton(
            option: round.options[i],
            accent: accent,
            isWrong: wrongIndex == i,
            fullWidth: false,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.option,
    required this.accent,
    required this.isWrong,
    required this.fullWidth,
    required this.onTap,
  });
  final QuizOption option;
  final Color accent;
  final bool isWrong;
  final bool fullWidth;
  final VoidCallback onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final isColor = option.color != null;
    final isAsset = option.asset != null;

    final Widget face;
    if (isAsset) {
      // The sprite fills the cell, contained & centered (never overflows).
      face = Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(option.asset!, fit: BoxFit.contain),
        ),
      );
    } else {
      face = Container(
        width: widget.fullWidth ? double.infinity : null,
        padding: widget.fullWidth
            ? const EdgeInsets.symmetric(vertical: Insets.md)
            : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isColor
              ? option.color!.withValues(alpha: 0.16)
              : AppPalette.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: widget.isWrong
                ? AppPalette.danger
                : (isColor ? option.color! : widget.accent)
                    .withValues(alpha: 0.55),
          ),
        ),
        child: isColor
            ? Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
              )
            : Text(
                option.text ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
      );
    }

    final base = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        child: face,
      ),
    );
    if (widget.isWrong) {
      return base.animate().shake(hz: 4, rotation: 0.02, duration: 320.ms);
    }
    return base;
  }
}

/// A pulsing header icon (e.g. the flanker target) with an optional glowing halo.
class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.asset, this.halo});
  final String asset;
  final String? halo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (halo != null)
            Image.asset(halo!, width: 92, height: 92)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.18, end: 0.5, duration: 1500.ms)
                .scaleXY(begin: 0.9, end: 1.12, duration: 1500.ms),
          Image.asset(asset, width: 54, height: 54)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                  begin: 1.0,
                  end: 1.08,
                  duration: 1400.ms,
                  curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

/// Wraps [child] in a [_Shaker] only when [shake] is set.
class _ShakeIf extends StatelessWidget {
  const _ShakeIf({
    required this.shake,
    required this.trigger,
    required this.child,
  });
  final bool shake;
  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      shake ? _Shaker(trigger: trigger, child: child) : child;
}

/// Quick decaying horizontal shake on [trigger] change — the wrong-answer nudge.
class _Shaker extends StatefulWidget {
  const _Shaker({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<_Shaker> createState() => _ShakerState();
}

class _ShakerState extends State<_Shaker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(covariant _Shaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 6) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
