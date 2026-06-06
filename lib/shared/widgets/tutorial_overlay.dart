import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/challenge.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tutorial.dart';
import '../../data/models/game_info.dart';

/// Shows the first-time tutorial for [game]. Resolves to `true` if the player
/// taps "Start", `false` if they dismiss it (back / skip). Caller is expected
/// to mark the tutorial as seen and continue to the game on `true`.
Future<bool> showGameTutorial(BuildContext context, GameInfo game) async {
  final steps = tutorialFor(game.id);
  if (steps.isEmpty) return true;

  final accent = game.color;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'tutorial',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => _TutorialDialog(
      game: game,
      steps: steps,
      accent: accent,
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

/// Compact "?" button used inside game HUDs to re-open the tutorial. Resolves
/// the current game from [GameScope]; renders nothing if the scope is missing
/// or the game has no tutorial defined.
class TutorialButton extends StatelessWidget {
  const TutorialButton({super.key});

  @override
  Widget build(BuildContext context) {
    final gameId = GameScope.maybeOf(context);
    if (gameId == null || !hasTutorial(gameId)) return const SizedBox.shrink();
    final game = kGames.firstWhere(
      (g) => g.id == gameId,
      orElse: () => kGames.first,
    );
    return Material(
      color: AppPalette.surface.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          showGameTutorial(context, game);
        },
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.help_outline_rounded,
              color: AppPalette.textSecondary, size: 22),
        ),
      ),
    );
  }
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({
    required this.game,
    required this.steps,
    required this.accent,
  });

  final GameInfo game;
  final List<TutorialStep> steps;
  final Color accent;

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    // Skip just shortcuts past the walkthrough — still launches the game.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == widget.steps.length - 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppPalette.backgroundElevated,
                    AppPalette.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.4),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: -12,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                  Insets.lg, Insets.lg, Insets.lg, Insets.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(game: widget.game, onSkip: _skip),
                  const SizedBox(height: Insets.md),
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.steps.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) =>
                          _StepPage(step: widget.steps[i], accent: widget.accent),
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  _Dots(
                    count: widget.steps.length,
                    index: _page,
                    accent: widget.accent,
                  ),
                  const SizedBox(height: Insets.md),
                  _PrimaryButton(
                    label: isLast
                        ? L('Bắt đầu', 'Start')
                        : L('Tiếp', 'Next'),
                    icon: isLast
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    accent: widget.accent,
                    onTap: _next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.onSkip});

  final GameInfo game;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                game.color.withValues(alpha: 0.45),
                game.color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: game.color.withValues(alpha: 0.5)),
          ),
          child: Icon(game.icon, color: game.color, size: 24),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L('HƯỚNG DẪN', 'HOW TO PLAY'),
                style: TextStyle(
                  color: game.color,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppPalette.textMuted,
          ),
          child: Text(L('Bỏ qua', 'Skip'),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step, required this.accent});

  final TutorialStep step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.32),
                  accent.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            child: Icon(step.icon, color: accent, size: 30),
          )
              .animate(key: ValueKey(step.icon))
              .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 320.ms,
                  curve: Curves.easeOutBack)
              .fadeIn(duration: 220.ms),
          const SizedBox(height: Insets.md),
          Text(
            L(step.titleVi, step.titleEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Flexible(
            child: Text(
              L(step.bodyVi, step.bodyEn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.accent,
  });

  final int count;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? accent
                  : AppPalette.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.pill),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
