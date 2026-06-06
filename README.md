# MindForge

Brain-training app built with Flutter — 24 short, animated cognitive games covering speed, memory, attention, flexibility, problem solving, math and language. Vibrant dark theme, per-game accent color, bilingual VI / EN UI.

---

## Table of Contents

- [Features](#features)
- [Game catalog](#game-catalog)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Conventions](#conventions)
- [Adding a new game](#adding-a-new-game)
- [Tutorial system](#tutorial-system)
- [Daily challenge](#daily-challenge)
- [Localization](#localization)
- [Assets](#assets)
- [Scripts & quality gates](#scripts--quality-gates)

---

## Features

- 24 mini-games grouped into 7 cognitive categories.
- Per-game first-time tutorial with bilingual content (persisted via `SharedPreferences`).
- In-game help button (`?`) to replay the tutorial any time.
- Daily challenge card — picks a deterministic game + score target every day.
- Difficulty selector (Easy / Medium / Hard) and play-time selector applied across all games.
- Vibrant dark aurora background, animated entrances (`flutter_animate`), and per-game FX.
- Bilingual UI: Vietnamese (default) and English, switchable from the in-app settings sheet.

## Game catalog

| Group | Game (VI / EN) | Id |
|-------|----------------|----|
| Speed | Chạm Nhanh / Quick Tap | `reaction_tap` |
| Memory | Lưới Nhớ / Memory Grid | `memory_grid` |
| Memory | Lật Thẻ / Card Match | `card_match` |
| Attention | Màu Chữ / Ink Color (Stroop) | `stroop` |
| Attention | Tìm Khác / Find Target | `find_target` |
| Attention | Lệch Màu / Odd Hue | `odd_hue` |
| Attention | Nối Số / Trail Maker | `trail_maker` |
| Flexibility | Đảo Chiều / Switch | `switch` |
| Flexibility | Mũi Tên / Arrows (Flanker) | `arrow_flanker` |
| Flexibility | Đổi Luật / Rule Shift | `rule_shift` |
| Flexibility | Chẵn Lẻ / Even-Odd | `even_odd` |
| Problem solving | Dòng Số / Number Flow | `sequence` |
| Problem solving | Tắt Đèn / Lights Out | `lights_out` |
| Problem solving | Ô Trượt / Sliding Puzzle | `sliding_puzzle` |
| Math | Tính Nhanh / Quick Math | `quick_math` |
| Math | Đếm Chấm / Counting Dots | `counting_dots` |
| Math | Vế Lớn Hơn / Bigger Sum | `bigger_sum` |
| Math | Dãy Số / Sequence | `sequence_math` |
| Math | Cân Bằng / Balance | `balance_eq` |
| Math | Ghép Số / Number Bonds | `number_bonds` |
| Language | Từ Lạc / Odd Word | `odd_word` |
| Language | Đồng Nghĩa / Synonym | `synonym` |
| Language | Chữ Đầu / First Letter | `first_letter` |
| Language | Xếp Chữ / Anagram | `anagram` |

## Tech stack

- **Flutter** SDK `^3.11.0`
- **flame** `^1.37.0` — the reaction-tap game uses a Flame engine widget; the rest are pure Flutter
- **flutter_animate** `^4.5.2` — entrance / loop animations everywhere
- **google_fonts** `^8.1.0` — Outfit + Sora typography
- **shared_preferences** — persist tutorial seen state
- **flutter_lints** `^6.0.0`

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on the connected device / simulator
flutter run

# 3. Static analysis (run before every commit)
flutter analyze

# 4. Tests
flutter test
```

> Adding native plugins (e.g. `shared_preferences`) requires a **full cold restart** — hot restart is not enough for native plugin registration.

## Project structure

```
lib/
├── main.dart                       # MaterialApp + TutorialStore.load() boot
├── core/
│   ├── challenge.dart              # ChallengeStore + DailyChallenge + GameScope
│   ├── difficulty.dart             # Difficulty enum + GameSettings
│   ├── tutorial.dart               # TutorialStep + TutorialStore (SharedPreferences)
│   ├── i18n/app_lang.dart          # AppLang enum, L(vi, en) helper, toggleLang()
│   └── theme/
│       ├── app_palette.dart        # Surfaces, text, per-category accents
│       └── app_theme.dart          # Insets, Radii, dark ThemeData
├── data/
│   └── models/game_info.dart       # GameInfo, kGames catalog, CognitiveGroup
├── features/
│   ├── home/home_screen.dart       # Home grid + daily card + settings sheet
│   └── games/
│       ├── reaction_tap/           # Flame-based
│       ├── memory_grid/
│       ├── stroop/
│       ├── ... (one folder per game)
│       └── quiz/                   # Shared engine for option-quiz games
│           ├── option_quiz.dart
│           └── quiz_specs.dart     # bigger_sum, synonym, first_letter, ...
└── shared/
    ├── session/timed_session.dart  # Mixin: 60s timer, score, combo
    └── widgets/
        ├── tutorial_overlay.dart   # showGameTutorial() + TutorialButton
        ├── quiz_top_bar.dart       # Close + tutorial button + score + combo
        ├── result_overlay.dart     # End-of-round panel
        ├── aurora_background.dart
        ├── difficulty_selector.dart
        ├── duration_selector.dart
        ├── glass_card.dart
        ├── win_burst.dart
        ├── animated_counter.dart
        └── app_buttons.dart        # PrimaryButton, GhostButton, RoundIconButton
```

```
assets/
├── games/
│   ├── reaction_tap/        # one folder per game with all FX sprites
│   ├── memory_grid/
│   ├── anagram/             # board_frame, letter_tile, owl_mascot, ...
│   └── ...
└── kit/                     # app icon, menu icon, shared chrome
```

## Conventions

- **Naming** — meaningful, no `btn` / `idx` / `tmp`.
- **Strict typing** — no `dynamic` unless absolutely required.
- **Comments** — only for the **why**, never the what.
- **Strings** — every user-facing string goes through `L('vi', 'en')`.
- **Spacing / radii** — always use `Insets.*` and `Radii.*` tokens.
- **Colors** — pull from `AppPalette` / `CognitiveGroup.color`, no hard-coded hex in features.
- **Commits** — Conventional Commits: `feat: ...`, `fix: ...`, `refactor: ...`, `chore: ...`, `perf: ...`.
- **Quality gate** — run `flutter analyze` before every commit; CI / hooks rely on zero issues.

## Adding a new game

1. Create `lib/features/games/<id>/<id>_screen.dart`.
2. Register a `GameInfo` entry in `lib/data/models/game_info.dart` (`kGames`):
   ```dart
   GameInfo(
     id: 'my_game',
     titleVi: 'Tên', titleEn: 'Name',
     subtitleVi: '...', subtitleEn: '...',
     group: CognitiveGroup.attention,
     icon: Icons.foo_rounded,
     available: true,
   ),
   ```
3. Add the `case` for the id in `_screenFor()` inside `lib/features/home/home_screen.dart`.
4. Add a tutorial entry (3 steps: goal / how to play / tip) in `_tutorials` inside `lib/core/tutorial.dart`.
5. (Optional) Drop sprites into `assets/games/<id>/` and append the path to `pubspec.yaml > assets:`.
6. Use `QuizTopBar` (or the existing `_Hud` pattern) so the close button + tutorial replay button are consistent.

If the game is just a multiple-choice round, skip steps 1 & 3 and add a `QuizSpec` to `lib/features/games/quiz/quiz_specs.dart` instead — `OptionQuizScreen` handles the rest.

## Tutorial system

- Content lives in `lib/core/tutorial.dart` as `_tutorials: Map<String, List<TutorialStep>>`. Each step has `titleVi/En`, `bodyVi/En`, `icon`.
- `TutorialStore` persists the seen set in `SharedPreferences` (`tutorial.seen`). Call `TutorialStore.load()` once at app boot — `main.dart` already does.
- First time a player opens a game, the home screen awaits `showGameTutorial(context, game)` before pushing the game route.
- Inside any game that uses `QuizTopBar` or the reaction-tap `_Hud`, the `TutorialButton` re-opens the tutorial. It resolves the active game from `GameScope`.

## Daily challenge

- `ChallengeStore.today()` picks a deterministic game and a target (200…500) from the day-of-year, so every device sees the same challenge.
- `ChallengeStore.report(gameId, score)` is called by `ResultOverlay` whenever a round ends — keeps the highest score per game.
- The home daily card listens to `ChallengeStore.revision` and rebuilds when a new best is recorded.

## Localization

- App language lives in a `ValueNotifier<AppLang>` (`appLang`) so toggling rebuilds the whole tree.
- Use `L('Vietnamese text', 'English text')` for every user-facing string.
- The settings sheet on the home screen exposes a VI / EN toggle.

## Assets

- Per-game FX sprites live under `assets/games/<id>/`. New folders **must** be added to the `assets:` list in `pubspec.yaml`.
- Shared chrome (app icon, menu, trophy, etc.) sits in `assets/kit/`.
- Reaction-tap also pulls sprites from `assets/games/reaction_tap/` via the Flame engine.

## Scripts & quality gates

| Command | When |
|---------|------|
| `flutter pub get` | After pulling or changing `pubspec.yaml` |
| `flutter analyze` | Before every commit — must be zero issues |
| `flutter test` | Before pushing |
| `flutter run` | Day-to-day dev; cold restart after adding plugins |
| `flutter build ipa` / `flutter build apk` | Release builds |

---

Built with Flutter. Issues / ideas welcome via PR.
