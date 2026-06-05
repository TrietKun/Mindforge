import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/difficulty.dart';
import '../../../core/theme/app_palette.dart';

/// Live, read-only snapshot of the session — the HUD overlay listens to this.
class GameStats {
  const GameStats({
    this.score = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.hits = 0,
    this.misses = 0,
    this.timeLeft = kSessionSeconds,
  });

  static const double kSessionSeconds = 30;

  final int score;
  final int combo;
  final int bestCombo;
  final int hits;
  final int misses;
  final double timeLeft;

  int get accuracy {
    final total = hits + misses;
    if (total == 0) return 100;
    return ((hits / total) * 100).round();
  }

  GameStats copyWith({
    int? score,
    int? combo,
    int? bestCombo,
    int? hits,
    int? misses,
    double? timeLeft,
  }) {
    return GameStats(
      score: score ?? this.score,
      combo: combo ?? this.combo,
      bestCombo: bestCombo ?? this.bestCombo,
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }
}

class ReactionTapGame extends FlameGame {
  ReactionTapGame({required this.onFinished, this.difficulty = Difficulty.medium});

  /// Called once when the timer runs out, with the final stats.
  final void Function(GameStats finalStats) onFinished;
  final Difficulty difficulty;

  final ValueNotifier<GameStats> stats = ValueNotifier(const GameStats());
  final _rng = math.Random();

  // Internal mutable snapshot updated during `update()`; pushed to `stats`
  // after the frame to avoid setState-during-build crashes in the HUD overlay.
  GameStats _stats = const GameStats();
  bool _flushScheduled = false;
  bool _disposed = false;

  double _spawnTimer = 0;
  double _shake = 0;
  bool _running = true;

  void _setStats(GameStats next) {
    if (_disposed) return;
    _stats = next;
    if (_flushScheduled) return;
    _flushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;
      if (_disposed) return;
      stats.value = _stats;
    });
  }

  static const Color _accent = AppPalette.reaction;

  // Sprites stay null if the assets are missing → components fall back to
  // drawing themselves with Canvas.
  final _assets = Images(prefix: 'assets/games/reaction_tap/');
  Sprite? _targetSprite;
  Sprite? _targetSprite2;
  Sprite? _burstSprite;
  Sprite? _sparkSprite;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await add(_AmbientBackground());
    try {
      _targetSprite = Sprite(await _assets.load('target.png'));
      _targetSprite2 = Sprite(await _assets.load('target_2.png'));
      _burstSprite = Sprite(await _assets.load('burst.png'));
      _sparkSprite = Sprite(await _assets.load('spark.png'));
    } catch (_) {
      // Assets not bundled — keep the procedural look.
    }
  }

  ({double spawnBase, double spawnMin, double lifeBase, double lifeMin})
      get _tune => switch (difficulty) {
            Difficulty.easy =>
              (spawnBase: 1.15, spawnMin: 0.6, lifeBase: 1.95, lifeMin: 1.15),
            Difficulty.medium =>
              (spawnBase: 0.95, spawnMin: 0.42, lifeBase: 1.55, lifeMin: 0.85),
            Difficulty.hard =>
              (spawnBase: 0.78, spawnMin: 0.34, lifeBase: 1.2, lifeMin: 0.6),
          };

  double get _spawnInterval {
    // Speeds up as the score climbs — adaptive on top of the difficulty floor.
    final score = _stats.score;
    return (_tune.spawnBase - score / 4000)
        .clamp(_tune.spawnMin, _tune.spawnBase);
  }

  double get _targetLifetime {
    final score = _stats.score;
    return (_tune.lifeBase - score / 3000)
        .clamp(_tune.lifeMin, _tune.lifeBase);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running) return;

    // Session timer
    final left = _stats.timeLeft - dt;
    if (left <= 0) {
      _setStats(_stats.copyWith(timeLeft: 0));
      _finish();
      return;
    }
    _setStats(_stats.copyWith(timeLeft: left));

    // Spawning
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = _spawnInterval;
      _spawnTarget();
    }

    if (_shake > 0) _shake = math.max(0, _shake - dt);
  }

  @override
  void render(Canvas canvas) {
    if (_shake > 0) {
      final intensity = _shake * 26;
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * intensity,
        (_rng.nextDouble() - 0.5) * intensity,
      );
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  void _spawnTarget() {
    const margin = 56.0;
    final pos = Vector2(
      margin + _rng.nextDouble() * (size.x - margin * 2),
      margin + 40 + _rng.nextDouble() * (size.y - margin * 2 - 120),
    );
    add(
      _Target(
        position: pos,
        lifetime: _targetLifetime,
        color: _accent,
        sprite: _rng.nextBool() ? _targetSprite : (_targetSprite2 ?? _targetSprite),
        onHit: _onHit,
        onExpire: _onExpire,
      ),
    );
  }

  void _onHit(Vector2 at) {
    HapticFeedback.lightImpact();
    final combo = _stats.combo + 1;
    final bestCombo = math.max(combo, _stats.bestCombo);
    final gained =
        (10 * (1 + combo ~/ 5) * difficulty.scoreMultiplier).round();
    _setStats(_stats.copyWith(
      score: _stats.score + gained,
      combo: combo,
      bestCombo: bestCombo,
      hits: _stats.hits + 1,
    ));
    _burst(at, _accent, count: 18 + combo.clamp(0, 22));
    if (_burstSprite != null) {
      final burst = SpriteComponent(
        sprite: _burstSprite!,
        anchor: Anchor.center,
        position: at.clone(),
        size: Vector2.all(96),
      )
        ..add(ScaleEffect.by(
            Vector2.all(1.6), EffectController(duration: 0.34, curve: Curves.easeOut)))
        ..add(OpacityEffect.fadeOut(EffectController(duration: 0.34)));
      burst.add(RemoveEffect(delay: 0.36));
      add(burst);
    }
    add(_FloatingScore(
      text: '+$gained',
      position: at.clone()..y -= 30,
      color: combo >= 5 ? AppPalette.gold : _accent,
    ));
    if (combo > 0 && combo % 5 == 0) {
      HapticFeedback.mediumImpact();
      _shake = math.max(_shake, 0.22);
    }
  }

  void _onExpire(Vector2 at) {
    if (!_running) return;
    HapticFeedback.heavyImpact();
    _setStats(_stats.copyWith(
      combo: 0,
      misses: _stats.misses + 1,
    ));
    _shake = 0.3;
    add(_FlashOverlay(color: AppPalette.danger.withValues(alpha: 0.18)));
  }

  void _burst(Vector2 at, Color color, {int count = 18}) {
    add(
      ParticleSystemComponent(
        position: at,
        particle: Particle.generate(
          count: count,
          lifespan: 0.6,
          generator: (i) {
            final angle = _rng.nextDouble() * math.pi * 2;
            final speed = 90 + _rng.nextDouble() * 220;
            return AcceleratedParticle(
              acceleration: Vector2(0, 220),
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final opacity = 1 - particle.progress;
                  final spark = _sparkSprite;
                  if (spark != null) {
                    final side = 16 * opacity + 5;
                    spark.render(
                      canvas,
                      anchor: Anchor.center,
                      size: Vector2.all(side),
                      overridePaint: Paint()
                        ..color = Colors.white.withValues(alpha: opacity),
                    );
                  } else {
                    canvas.drawCircle(
                      Offset.zero,
                      3.2 * opacity + 0.6,
                      Paint()
                        ..color = color.withValues(alpha: opacity)
                        ..maskFilter =
                            const MaskFilter.blur(BlurStyle.normal, 1.5),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _finish() {
    _running = false;
    pauseEngine();
    // Ensure listeners see the final snapshot even if a flush is still pending.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      stats.value = _stats;
    });
    onFinished(_stats);
  }

  @override
  void onRemove() {
    _disposed = true;
    stats.dispose();
    super.onRemove();
  }
}

/// A pulsing, glowing target the player must tap before it expires.
class _Target extends PositionComponent with TapCallbacks {
  _Target({
    required Vector2 position,
    required this.lifetime,
    required this.color,
    required this.onHit,
    required this.onExpire,
    this.sprite,
  }) : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(_baseRadius * 2),
        );

  static const double _baseRadius = 34;

  final double lifetime;
  final Color color;
  final Sprite? sprite;
  final void Function(Vector2 at) onHit;
  final void Function(Vector2 at) onExpire;

  double _age = 0;
  bool _resolved = false;

  @override
  Future<void> onLoad() async {
    // Spring-in
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.28, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final center = size / 2;
    return point.distanceTo(center) <= _baseRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime && !_resolved) {
      _resolved = true;
      onExpire(absoluteCenter);
      _vanish();
    }
  }

  @override
  void render(Canvas canvas) {
    final remaining = (1 - _age / lifetime).clamp(0.0, 1.0);
    final pulse = 1 + 0.06 * math.sin(_age * 9);
    final center = (size / 2).toOffset();
    final r = _baseRadius * pulse;

    if (sprite != null) {
      // Draw the sprite a little larger than the hit circle so its baked-in
      // glow shows beyond the rim.
      sprite!.render(
        canvas,
        position: size / 2,
        size: Vector2.all((_baseRadius * 2 + 24) * pulse),
        anchor: Anchor.center,
      );
    } else {
      // Procedural fallback: outer glow + body gradient + highlight.
      canvas.drawCircle(
        center,
        r + 14,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.55),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      canvas.drawCircle(
        center.translate(-r * 0.28, -r * 0.28),
        r * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    // Countdown ring (shrinks as time runs out)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r + 7),
      -math.pi / 2,
      math.pi * 2 * remaining,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_resolved) return;
    _resolved = true;
    onHit(absoluteCenter);
    _vanish();
  }

  void _vanish() {
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.16, curve: Curves.easeIn),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// Quick full-screen color flash that fades out (used on a miss).
class _FlashOverlay extends RectangleComponent {
  _FlashOverlay({required Color color})
      : super(paint: Paint()..color = color, priority: 100);

  @override
  Future<void> onLoad() async {
    size = (findGame()!).size;
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.35),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// A "+N" score number that rises and fades out where a target was tapped.
class _FloatingScore extends PositionComponent {
  _FloatingScore({
    required this.text,
    required Vector2 position,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  final String text;
  final Color color;
  double _t = 0;
  static const _duration = 0.75;

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 46 * dt;
    if (_t >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1 - _t / _duration).clamp(0.0, 1.0);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.6),
              blurRadius: 12,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
}

/// Slowly drifting blurred orbs for an alive background.
class _AmbientBackground extends Component {
  final _rng = math.Random();
  late List<_Orb> _orbs;
  Vector2 _bounds = Vector2.zero();

  @override
  Future<void> onLoad() async {
    _bounds = (findGame()!).size;
    _orbs = List.generate(5, (i) {
      final colors = [
        AppPalette.reaction,
        AppPalette.focus,
        AppPalette.memory,
      ];
      return _Orb(
        pos: Vector2(
          _rng.nextDouble() * _bounds.x,
          _rng.nextDouble() * _bounds.y,
        ),
        vel: Vector2(
          (_rng.nextDouble() - 0.5) * 18,
          (_rng.nextDouble() - 0.5) * 18,
        ),
        radius: 90 + _rng.nextDouble() * 130,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _bounds = size;
  }

  @override
  void update(double dt) {
    for (final orb in _orbs) {
      orb.pos += orb.vel * dt;
      if (orb.pos.x < -orb.radius) orb.pos.x = _bounds.x + orb.radius;
      if (orb.pos.x > _bounds.x + orb.radius) orb.pos.x = -orb.radius;
      if (orb.pos.y < -orb.radius) orb.pos.y = _bounds.y + orb.radius;
      if (orb.pos.y > _bounds.y + orb.radius) orb.pos.y = -orb.radius;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final orb in _orbs) {
      canvas.drawCircle(
        orb.pos.toOffset(),
        orb.radius,
        Paint()
          ..color = orb.color.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }
}

class _Orb {
  _Orb({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.color,
  });
  Vector2 pos;
  Vector2 vel;
  double radius;
  Color color;
}
