import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/challenge.dart';
import '../../core/difficulty.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_info.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/difficulty_selector.dart';
import '../../shared/widgets/duration_selector.dart';
import '../../shared/widgets/glass_card.dart';
import '../games/anagram/anagram_screen.dart';
import '../games/card_match/card_match_screen.dart';
import '../games/counting_dots/counting_dots_screen.dart';
import '../games/even_odd/even_odd_switch_screen.dart';
import '../games/grid_find/grid_find_screen.dart';
import '../games/lights_out/lights_out_screen.dart';
import '../games/memory_grid/memory_grid_screen.dart';
import '../games/number_bonds/number_bonds_screen.dart';
import '../games/number_flow/number_flow_screen.dart';
import '../games/odd_word/odd_word_screen.dart';
import '../games/quick_math/quick_math_screen.dart';
import '../games/quiz/option_quiz.dart';
import '../games/quiz/quiz_specs.dart';
import '../games/reaction_tap/reaction_tap_screen.dart';
import '../games/rule_shift/rule_shift_screen.dart';
import '../games/sliding_puzzle/sliding_puzzle_screen.dart';
import '../games/stroop/stroop_screen.dart';
import '../games/switch_game/switch_screen.dart';
import '../games/trail_maker/trail_maker_screen.dart';

Widget _screenFor(String id, Difficulty difficulty) {
  final spec = quizSpecFor(id);
  if (spec != null) {
    return OptionQuizScreen(spec: spec, difficulty: difficulty);
  }
  return switch (id) {
    'reaction_tap' => ReactionTapScreen(difficulty: difficulty),
    'memory_grid' => MemoryGridScreen(difficulty: difficulty),
    'stroop' => StroopScreen(difficulty: difficulty),
    'switch' => SwitchScreen(difficulty: difficulty),
    'sequence' => NumberFlowScreen(difficulty: difficulty),
    'quick_math' => QuickMathScreen(difficulty: difficulty),
    'odd_word' => OddWordScreen(difficulty: difficulty),
    'find_target' =>
      GridFindScreen(mode: GridFindMode.symbol, difficulty: difficulty),
    'odd_hue' => GridFindScreen(mode: GridFindMode.hue, difficulty: difficulty),
    'card_match' => CardMatchScreen(difficulty: difficulty),
    'lights_out' => LightsOutScreen(difficulty: difficulty),
    'trail_maker' => TrailMakerScreen(difficulty: difficulty),
    'sliding_puzzle' => SlidingPuzzleScreen(difficulty: difficulty),
    'rule_shift' => RuleShiftScreen(difficulty: difficulty),
    'number_bonds' => NumberBondsScreen(difficulty: difficulty),
    'anagram' => AnagramScreen(difficulty: difficulty),
    'even_odd' => EvenOddSwitchScreen(difficulty: difficulty),
    'counting_dots' => CountingDotsScreen(difficulty: difficulty),
    _ => ReactionTapScreen(difficulty: difficulty),
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CognitiveGroup? _filter;

  void _open(BuildContext context, GameInfo game) {
    if (!game.available) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppPalette.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            content: Text(L('${game.title} sắp ra mắt 🔓',
                '${game.title} coming soon 🔓'),
                style: const TextStyle(color: AppPalette.textPrimary)),
          ),
        );
      return;
    }
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, anim, secondaryAnim) => GameScope(
          gameId: game.id,
          child: _screenFor(game.id, GameSettings.difficulty.value),
        ),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final games = _filter == null
        ? kGames
        : kGames.where((g) => g.group == _filter).toList();
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.lg, Insets.lg, Insets.lg, Insets.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(),
                      const SizedBox(height: Insets.lg),
                      _DailyCard(onOpen: (game) => _open(context, game))
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: Insets.lg),
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: AppPalette.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text(L('Độ khó', 'Difficulty'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppPalette.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: Insets.sm),
                      const DifficultySelector()
                          .animate()
                          .fadeIn(delay: 280.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: Insets.md),
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded,
                              color: AppPalette.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text(L('Thời gian', 'Play time'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppPalette.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: Insets.sm),
                      const DurationSelector()
                          .animate()
                          .fadeIn(delay: 340.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.lg, Insets.sm, 0, Insets.sm),
                sliver: SliverToBoxAdapter(
                  child: _CategoryFilter(
                    selected: _filter,
                    onChanged: (group) => setState(() => _filter = group),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.lg, Insets.sm, Insets.lg, Insets.md),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(L('Trò chơi', 'Games'),
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(width: Insets.sm),
                      Text(L('${games.length} bài tập', '${games.length} games'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppPalette.textMuted)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.lg, 0, Insets.lg, Insets.xl),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: Insets.md,
                    crossAxisSpacing: Insets.md,
                    childAspectRatio: 0.84,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      final card = _GameCard(
                        key: ValueKey('${_filter?.name}-${game.id}'),
                        game: game,
                        onTap: () => _open(context, game),
                      );
                      // Only stagger the first viewport-worth of cards so the
                      // entrance feels lively without making off-screen cards
                      // wait 1+ second when they scroll in.
                      if (index >= 6) return card;
                      return card
                          .animate()
                          .fadeIn(delay: (index * 60).ms, duration: 320.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOutCubic);
                    },
                    childCount: games.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});

  final CognitiveGroup? selected;
  final ValueChanged<CognitiveGroup?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _Chip(
            label: L('Tất cả', 'All'),
            icon: Icons.apps_rounded,
            color: AppPalette.textSecondary,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final group in CognitiveGroup.values)
            _Chip(
              label: group.label,
              icon: group.icon,
              color: group.color,
              active: selected == group,
              onTap: () => onChanged(group),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Insets.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding:
              const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.18)
                : AppPalette.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: active ? color : AppPalette.stroke,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 15, color: active ? color : AppPalette.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: active ? color : AppPalette.textSecondary,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L('Chào buổi sáng 👋', 'Good morning 👋'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppPalette.textSecondary))
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 2),
              Text('MindForge', style: theme.textTheme.headlineLarge)
                  .animate()
                  .fadeIn(duration: 420.ms)
                  .slideX(begin: -0.12, curve: Curves.easeOut),
            ],
          ),
        ),
        const _MenuButton()
            .animate()
            .fadeIn(delay: 120.ms)
            .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
      ],
    );
  }
}

/// 3-dot menu button → opens the settings sheet.
class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSettingsSheet(context),
      child: Image.asset('assets/kit/menu.png', width: 38, height: 38),
    );
  }
}

void _showSettingsSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppPalette.backgroundElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.lg, Insets.lg, Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/kit/app_icon.png', width: 64, height: 64),
          const SizedBox(height: Insets.sm),
          Text('MindForge',
              style: Theme.of(context).textTheme.headlineSmall),
          Text('v1.0',
              style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
          const SizedBox(height: Insets.lg),
          _SettingsRow(
            icon: Icons.language_rounded,
            label: L('Ngôn ngữ', 'Language'),
            trailing: const _LangChips(),
          ),
          const SizedBox(height: Insets.sm),
          _SettingsRow(
            iconAsset: 'assets/kit/trophy_gold.png',
            label: L('Thành tích', 'Achievements'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppPalette.surfaceHigh,
                  content: Text(L('Sắp ra mắt 🏆', 'Coming soon 🏆'),
                      style: const TextStyle(color: AppPalette.textPrimary)),
                ));
            },
          ),
        ],
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.icon,
    this.iconAsset,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? iconAsset;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.md),
          child: Row(
            children: [
              iconAsset != null
                  ? Image.asset(iconAsset!, width: 26, height: 26)
                  : Icon(icon, color: AppPalette.textSecondary, size: 24),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact VI / EN toggle used inside the settings sheet.
class _LangChips extends StatefulWidget {
  const _LangChips();

  @override
  State<_LangChips> createState() => _LangChipsState();
}

class _LangChipsState extends State<_LangChips> {
  @override
  Widget build(BuildContext context) {
    Widget chip(String text, AppLang lang) {
      final active = appLang.value == lang;
      return GestureDetector(
        onTap: () => setState(() => appLang.value = lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppPalette.focus.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
                color: active ? AppPalette.focus : AppPalette.stroke),
          ),
          child: Text(text,
              style: TextStyle(
                  color: active ? AppPalette.focus : AppPalette.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('VI', AppLang.vi),
        const SizedBox(width: 6),
        chip('EN', AppLang.en),
      ],
    );
  }
}

/// Live "Today's Challenge" card — picks a real game + target for the day,
/// tracks the player's best score toward it, and opens the game when tapped.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.onOpen});

  final void Function(GameInfo game) onOpen;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ChallengeStore.revision,
      builder: (context, _, _) {
        final challenge = ChallengeStore.today();
        final game = challenge.game;
        final done = challenge.done;
        final card = GestureDetector(
          onTap: () => onOpen(game),
          child: Container(
            padding: const EdgeInsets.all(Insets.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.memory.withValues(alpha: 0.9),
                  AppPalette.focus.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.lg),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.focus.withValues(alpha: 0.35),
                  blurRadius: 34,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        done
                            ? Icons.verified_rounded
                            : Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(L('THỬ THÁCH HÔM NAY', "TODAY'S CHALLENGE"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (done)
                      Text(L('HOÀN THÀNH', 'DONE'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              L('Đạt ${challenge.target} điểm',
                                  'Reach ${challenge.target} points'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${game.title} • ${challenge.best}/${challenge.target}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    const SizedBox(width: Insets.md),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          done
                              ? Icons.check_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        // Keep the inviting shimmer only while the goal is still open.
        if (done) return card;
        return card.animate(onPlay: (c) => c.repeat()).shimmer(
            delay: 1400.ms,
            duration: 1600.ms,
            color: Colors.white.withValues(alpha: 0.25));
      },
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({super.key, required this.game, required this.onTap});
  final GameInfo game;
  final VoidCallback onTap;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final card = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        child: GlassCard(
          tint: game.available ? game.color : null,
          glow: game.available ? game.color : null,
          borderColor: game.available
              ? game.color.withValues(alpha: 0.45)
              : AppPalette.stroke,
          // Backdrop blur on every grid tile tanks scroll FPS — solid fill is
          // visually close enough since the aurora background is busy already.
          blur: 0,
          padding: const EdgeInsets.all(Insets.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      game.color.withValues(alpha: 0.35),
                      game.color.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: game.color.withValues(alpha: 0.4)),
                ),
                child: Icon(game.icon, color: game.color, size: 26),
              ),
              const Spacer(),
              Row(
                children: [
                  _GroupTag(group: game.group),
                  const Spacer(),
                  if (!game.available)
                    const Icon(Icons.lock_rounded,
                        color: AppPalette.textMuted, size: 16),
                ],
              ),
              const SizedBox(height: Insets.sm),
              Text(game.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                      )),
              const SizedBox(height: 2),
              Text(
                game.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppPalette.textMuted, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );

    // Infinite shimmer on every available card kept the whole grid repainting
    // forever, which was the other half of the scroll-jank problem. Drop it.
    return card;
  }
}

class _GroupTag extends StatelessWidget {
  const _GroupTag({required this.group});
  final CognitiveGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(group.label,
          style: TextStyle(
              color: group.color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}
