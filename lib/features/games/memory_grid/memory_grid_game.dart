import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/difficulty.dart';
import '../../../core/theme/app_palette.dart';

class MemoryStats {
  const MemoryStats({
    this.round = 1,
    this.score = 0,
    this.lives = 3,
    this.status = MemoryStatus.intro,
  });

  final int round;
  final int score;
  final int lives;
  final MemoryStatus status;

  MemoryStats copyWith({
    int? round,
    int? score,
    int? lives,
    MemoryStatus? status,
  }) =>
      MemoryStats(
        round: round ?? this.round,
        score: score ?? this.score,
        lives: lives ?? this.lives,
        status: status ?? this.status,
      );
}

enum MemoryStatus { intro, watch, repeat, over }

class MemoryGridGame extends FlameGame with TapCallbacks {
  MemoryGridGame({
    required this.onFinished,
    this.difficulty = Difficulty.medium,
  });

  final void Function(MemoryStats finalStats) onFinished;
  final Difficulty difficulty;

  ({double light, double gap, int lives}) get _tune => switch (difficulty) {
        Difficulty.easy => (light: 0.55, gap: 0.24, lives: 4),
        Difficulty.medium => (light: 0.42, gap: 0.18, lives: 3),
        Difficulty.hard => (light: 0.32, gap: 0.12, lives: 2),
      };

  final ValueNotifier<MemoryStats> stats = ValueNotifier(const MemoryStats());
  final _rng = math.Random();

  static const int _cols = 3;
  static const int _rows = 3;
  static const Color _accent = AppPalette.memory;

  final List<_Tile> _tiles = [];
  final List<int> _sequence = [];
  int _inputIndex = 0;

  final _assets = Images(prefix: 'assets/games/memory_grid/');
  Sprite? _litSprite;
  Sprite? _correctSprite;
  Sprite? _starSprite;

  // Playback state
  double _playbackTimer = 0;
  int _playbackStep = 0;
  bool _locked = true; // input disabled during playback / transitions

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    try {
      _litSprite = Sprite(await _assets.load('tile_lit.png'));
      _correctSprite = Sprite(await _assets.load('tile_correct.png'));
      _starSprite = Sprite(await _assets.load('tile_star.png'));
    } catch (_) {
      // Assets missing — tiles fall back to procedural drawing.
    }
    _buildGrid();
    _startRound(reset: true);
  }

  void _buildGrid() {
    _tiles.clear();
    removeWhere((c) => c is _Tile);
    final boardSize = math.min(size.x - 48, size.y - 220);
    const gap = 14.0;
    final tileSize = (boardSize - gap * (_cols - 1)) / _cols;
    final originX = (size.x - boardSize) / 2;
    final originY = (size.y - boardSize) / 2 + 20;

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final tile = _Tile(
          index: r * _cols + c,
          color: _accent,
          position: Vector2(
            originX + c * (tileSize + gap),
            originY + r * (tileSize + gap),
          ),
          tileSize: tileSize,
          onTapped: _onTileTapped,
          litSprite: _litSprite,
          correctSprite: _correctSprite,
          starSprite: _starSprite,
        );
        _tiles.add(tile);
        add(tile);
      }
    }
  }

  void _startRound({bool reset = false}) {
    if (reset) {
      _sequence.clear();
      stats.value = MemoryStats(lives: _tune.lives);
    }
    _sequence.add(_rng.nextInt(_tiles.length));
    _inputIndex = 0;
    _locked = true;
    _playbackStep = 0;
    _playbackTimer = 0.6; // small lead-in
    stats.value = stats.value.copyWith(status: MemoryStatus.watch);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (stats.value.status != MemoryStatus.watch) return;

    _playbackTimer -= dt;
    if (_playbackTimer > 0) return;

    final litSteps = _sequence.length * 2; // on + off per tile
    if (_playbackStep >= litSteps) {
      // Playback finished → hand over to player.
      _locked = false;
      stats.value = stats.value.copyWith(status: MemoryStatus.repeat);
      return;
    }

    final isLightStep = _playbackStep.isEven;
    if (isLightStep) {
      _tiles[_sequence[_playbackStep ~/ 2]].flash();
      _playbackTimer = _tune.light;
    } else {
      _playbackTimer = _tune.gap;
    }
    _playbackStep++;
  }

  void _onTileTapped(int index) {
    if (_locked || stats.value.status != MemoryStatus.repeat) return;

    if (index == _sequence[_inputIndex]) {
      HapticFeedback.selectionClick();
      _tiles[index].flash(success: true);
      _inputIndex++;
      if (_inputIndex >= _sequence.length) {
        _roundCleared();
      }
    } else {
      _wrongAnswer(index);
    }
  }

  void _roundCleared() {
    _locked = true;
    HapticFeedback.mediumImpact();
    final round = stats.value.round;
    stats.value = stats.value.copyWith(
      score: stats.value.score +
          (round * 10 * difficulty.scoreMultiplier).round(),
      round: round + 1,
    );
    for (final tile in _tiles) {
      tile.celebrate();
    }
    add(
      TimerComponent(
        period: 0.9,
        removeOnFinish: true,
        onTick: () => _startRound(),
      ),
    );
  }

  void _wrongAnswer(int index) {
    _locked = true;
    HapticFeedback.heavyImpact();
    _tiles[index].error();
    final lives = stats.value.lives - 1;
    stats.value = stats.value.copyWith(lives: lives);
    if (lives <= 0) {
      stats.value = stats.value.copyWith(status: MemoryStatus.over);
      add(
        TimerComponent(
          period: 0.5,
          removeOnFinish: true,
          onTick: () {
            pauseEngine();
            onFinished(stats.value);
          },
        ),
      );
    } else {
      // Replay the same sequence so the player can retry.
      add(
        TimerComponent(
          period: 0.9,
          removeOnFinish: true,
          onTick: () {
            _inputIndex = 0;
            _playbackStep = 0;
            _playbackTimer = 0.5;
            stats.value = stats.value.copyWith(status: MemoryStatus.watch);
          },
        ),
      );
    }
  }

  @override
  void onRemove() {
    stats.dispose();
    super.onRemove();
  }
}

enum _GlowKind { flash, success, celebrate, error }

class _Tile extends PositionComponent with TapCallbacks {
  _Tile({
    required this.index,
    required this.color,
    required Vector2 position,
    required double tileSize,
    required this.onTapped,
    this.litSprite,
    this.correctSprite,
    this.starSprite,
  }) : super(
          position: position,
          size: Vector2.all(tileSize),
          anchor: Anchor.topLeft,
        );

  final int index;
  final Color color;
  final void Function(int index) onTapped;
  final Sprite? litSprite;
  final Sprite? correctSprite;
  final Sprite? starSprite;

  double _glow = 0; // 0 = dim, 1 = fully lit
  Color _glowColor = AppPalette.memory;
  _GlowKind _kind = _GlowKind.flash;

  Sprite? get _kindSprite => switch (_kind) {
        _GlowKind.flash => litSprite,
        _GlowKind.success => correctSprite,
        _GlowKind.celebrate => starSprite,
        _GlowKind.error => null, // no red sprite → procedural
      };

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final radius = Radius.circular(size.x * 0.22);

    // Base idle tile
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = AppPalette.surfaceHigh,
    );

    if (_glow > 0) {
      // Glow halo behind the lit state
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(6), radius),
        Paint()
          ..color = _glowColor.withValues(alpha: 0.5 * _glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );

      final sprite = _kindSprite;
      if (sprite != null) {
        sprite.render(
          canvas,
          position: size / 2,
          size: size * 1.12,
          anchor: Anchor.center,
          overridePaint: Paint()
            ..color = Colors.white.withValues(alpha: _glow),
        );
      } else {
        // Procedural lit fill (used for the red error state).
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = _glowColor.withValues(alpha: 0.9 * _glow),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(size.x * 0.28), radius),
          Paint()..color = Colors.white.withValues(alpha: 0.35 * _glow),
        );
      }
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppPalette.stroke,
    );
  }

  void flash({bool success = false}) {
    _glowColor = success ? AppPalette.success : color;
    _kind = success ? _GlowKind.success : _GlowKind.flash;
    _pulse();
  }

  void celebrate() {
    _glowColor = AppPalette.gold;
    _kind = _GlowKind.celebrate;
    _pulse();
  }

  void error() {
    _glowColor = AppPalette.danger;
    _kind = _GlowKind.error;
    _pulse();
    add(
      MoveByEffect(
        Vector2(10, 0),
        EffectController(
          duration: 0.06,
          alternate: true,
          repeatCount: 3,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void _pulse() {
    _glow = 1;
    add(
      ScaleEffect.by(
        Vector2.all(1.08),
        EffectController(duration: 0.12, alternate: true),
      ),
    );
    // Fade the glow back down.
    add(
      _GlowFade(onUpdate: (v) => _glow = v),
    );
  }

  @override
  void onTapDown(TapDownEvent event) => onTapped(index);
}

/// Drives the tile glow from 1 → 0 over a short duration.
class _GlowFade extends Component {
  _GlowFade({required this.onUpdate});
  final void Function(double value) onUpdate;
  double _t = 0;
  static const _duration = 0.35;

  @override
  void update(double dt) {
    _t += dt;
    final v = (1 - _t / _duration).clamp(0.0, 1.0);
    onUpdate(v);
    if (_t >= _duration) removeFromParent();
  }
}
