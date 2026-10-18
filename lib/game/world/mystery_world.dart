import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/game_state.dart';
import '../spec/adventure_spec.dart';

class _Particle {
  _Particle(this.pos, this.vel, this.life, this.color, this.radius)
      : maxLife = life;

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final Color color;
  final double radius;
}

/// Renders the current stage and handles movement. It never decides game
/// rules: those live in [GameState].
class MysteryWorld extends FlameGame {
  MysteryWorld({required this.state});

  final GameState state;

  /// The entity the player can interact with right now (or null).
  final ValueNotifier<EntitySpec?> nearby = ValueNotifier(null);

  bool inputEnabled = true;
  Offset joystick = Offset.zero;

  Offset player = const Offset(0.5, 0.85);
  Offset _spawn = const Offset(0.5, 0.85);

  Color floorColor = const Color(0xFFEDE9FE);
  Color wallColor = const Color(0xFFB9A3EC);
  Color accentColor = const Color(0xFF7C3AED);
  String sceneName = 'Mystery World';

  final List<Rect> _obstacles = []; // normalized
  final List<_Particle> _particles = [];
  final Map<String, TextPainter> _labels = {};
  final Map<String, double> _revealStart = {};
  final Map<String, double> _blockerGoneAt = {};
  final Set<String> _visibleBefore = {};
  final Set<String> _blockersBefore = {};
  final math.Random _random = math.Random();

  int _stageShown = -1;
  String _banner = '';
  double _t = 0;
  double _shake = 0;
  double _doorOpen = 0;
  double _facing = 1;
  double _transition = 0;
  bool _moving = false;

  // ---------------------------------------------------------------- stage

  void _loadStage() {
    final s = state.stage;
    _stageShown = state.stageIndex;

    floorColor = s.floorColor;
    wallColor = s.wallColor;
    accentColor = s.accentColor;
    sceneName = s.name;
    _spawn = s.spawn;
    player = _spawn;

    _obstacles
      ..clear()
      ..addAll(s.obstacles);
    _particles.clear();
    _revealStart.clear();
    _blockerGoneAt.clear();

    _visibleBefore
      ..clear()
      ..addAll(s.entities.where(state.isVisible).map((e) => e.id));
    _blockersBefore
      ..clear()
      ..addAll(state.activeBlockers.map((b) => b.id));

    _doorOpen = 0;
    _shake = 0;
    _transition = 1;
    _banner = state.spec.stages.length > 1
        ? 'Stage ${state.stageIndex + 1}\n${s.name}'
        : s.name;
    joystick = Offset.zero;
    nearby.value = null;
  }

  void resetWorld() {
    _stageShown = -1; // reload on the next frame
    inputEnabled = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _labels.clear();
  }

  // -------------------------------------------------------------- helpers

  double get _unit => math.min(size.x, size.y);
  double get _playerRadius => (_unit * 0.045).clamp(10.0, 20.0).toDouble();
  double get _entityRadius => (_unit * 0.05).clamp(15.0, 28.0).toDouble();
  double get _interactRange => _unit * 0.17;

  Offset _px(Offset n) => Offset(n.dx * size.x, n.dy * size.y);

  Rect _rectPx(Rect n) => Rect.fromLTWH(
        n.left * size.x,
        n.top * size.y,
        n.width * size.x,
        n.height * size.y,
      );

  bool _free(Offset pixel) {
    final margin = _playerRadius + 8;
    if (pixel.dx < margin ||
        pixel.dy < margin ||
        pixel.dx > size.x - margin ||
        pixel.dy > size.y - margin) {
      return false;
    }
    final body = Rect.fromCircle(center: pixel, radius: _playerRadius);
    for (final o in _obstacles) {
      if (body.overlaps(_rectPx(o))) return false;
    }
    for (final b in state.activeBlockerRects) {
      if (body.overlaps(_rectPx(b))) return false;
    }
    return true;
  }

  // -------------------------------------------------------------- effects

  void burstAt(Offset normalized, Color color, {int count = 22}) {
    final origin = _px(normalized);
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 70 + _random.nextDouble() * 170;
      _particles.add(_Particle(
        origin,
        Offset(math.cos(angle) * speed, math.sin(angle) * speed - 60),
        0.6 + _random.nextDouble() * 0.5,
        color,
        2 + _random.nextDouble() * 3.5,
      ));
    }
  }

  void burstEntity(EntitySpec entity, {Color? color}) {
    burstAt(Offset(entity.x, entity.y), color ?? const Color(0xFFFBBF24));
  }

  void celebrate() {
    const colors = [
      Color(0xFFFBBF24),
      Color(0xFF22C55E),
      Color(0xFF7C3AED),
      Color(0xFF38BDF8),
      Color(0xFFF472B6),
    ];
    for (var i = 0; i < 6; i++) {
      burstAt(
        Offset(0.15 + _random.nextDouble() * 0.7,
            0.2 + _random.nextDouble() * 0.5),
        colors[i % colors.length],
        count: 26,
      );
    }
  }

  void shake() => _shake = 0.35;

  // --------------------------------------------------------------- update

  Offset _inputVector() {
    var v = joystick;
    if (v == Offset.zero) {
      final keys = HardwareKeyboard.instance;
      var dx = 0.0;
      var dy = 0.0;
      if (keys.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft) ||
          keys.isLogicalKeyPressed(LogicalKeyboardKey.keyA)) {
        dx -= 1;
      }
      if (keys.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight) ||
          keys.isLogicalKeyPressed(LogicalKeyboardKey.keyD)) {
        dx += 1;
      }
      if (keys.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) ||
          keys.isLogicalKeyPressed(LogicalKeyboardKey.keyW)) {
        dy -= 1;
      }
      if (keys.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) ||
          keys.isLogicalKeyPressed(LogicalKeyboardKey.keyS)) {
        dy += 1;
      }
      v = Offset(dx, dy);
    }
    final length = v.distance;
    if (length < 0.08) return Offset.zero;
    return length > 1 ? v / length : v;
  }

  void _updateMovement(double dt) {
    final dir = _inputVector();
    _moving = dir != Offset.zero &&
        inputEnabled &&
        !state.completed &&
        _transition < 0.6;
    if (!_moving) return;

    final step = dir * (_unit * 0.55 * dt);
    var pos = _px(player);

    final tryX = Offset(pos.dx + step.dx, pos.dy);
    if (_free(tryX)) pos = tryX;

    final tryY = Offset(pos.dx, pos.dy + step.dy);
    if (_free(tryY)) pos = tryY;

    player = Offset(pos.dx / size.x, pos.dy / size.y);
    if (dir.dx.abs() > 0.1) _facing = dir.dx > 0 ? 1 : -1;
  }

  /// Notices things that just appeared or disappeared, and plays effects.
  void _trackChanges() {
    final nowVisible = <String>{};
    for (final e in state.stage.entities) {
      if (!state.isVisible(e)) continue;
      nowVisible.add(e.id);
      if (!_visibleBefore.contains(e.id)) {
        _revealStart[e.id] = _t;
        burstAt(Offset(e.x, e.y), const Color(0xFFFDE68A), count: 18);
      }
    }
    _visibleBefore
      ..clear()
      ..addAll(nowVisible);

    final nowBlockers = state.activeBlockers.map((b) => b.id).toSet();
    for (final id in _blockersBefore) {
      if (nowBlockers.contains(id)) continue;
      _blockerGoneAt[id] = _t;
      for (final b in state.stage.blockers) {
        if (b.id != id) continue;
        for (var i = 0; i < 5; i++) {
          burstAt(
            Offset(b.rect.left + b.rect.width * (0.1 + 0.8 * _random.nextDouble()),
                b.rect.center.dy),
            accentColor,
            count: 8,
          );
        }
      }
    }
    _blockersBefore
      ..clear()
      ..addAll(nowBlockers);
  }

  bool _isInteractable(EntitySpec e) {
    if (e.type == EntityType.door) return !state.completed;
    return !state.entityDone(e);
  }

  void _updateNearby() {
    EntitySpec? best;
    var bestDistance = _interactRange;
    final me = _px(player);

    if (!state.completed && _transition < 0.6) {
      for (final e in state.stage.entities) {
        if (!state.isVisible(e) || !_isInteractable(e)) continue;
        final d = (_px(Offset(e.x, e.y)) - me).distance;
        if (d < bestDistance) {
          bestDistance = d;
          best = e;
        }
      }
    }

    if (nearby.value?.id != best?.id) nearby.value = best;
  }

  void _updateEffects(double dt) {
    if (_shake > 0) _shake = math.max(0, _shake - dt);
    if (_transition > 0) _transition = math.max(0, _transition - dt * 0.9);
    if (state.completed) _doorOpen = math.min(1, _doorOpen + dt * 1.2);

    for (final p in _particles) {
      p.pos = p.pos + p.vel * dt;
      p.vel = p.vel + Offset(0, 260 * dt);
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (size.x <= 0 || size.y <= 0) return;

    if (_stageShown != state.stageIndex) _loadStage();

    _updateMovement(dt);
    _trackChanges();
    _updateNearby();
    _updateEffects(dt);
  }

  // --------------------------------------------------------------- render

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0 || _stageShown < 0) return;

    canvas.save();
    if (_shake > 0) {
      final m = _shake * 14;
      canvas.translate(
        (_random.nextDouble() - 0.5) * m,
        (_random.nextDouble() - 0.5) * m,
      );
    }

    _drawFloor(canvas, w, h);
    _drawObstacles(canvas);
    _drawBlockers(canvas);

    final visible = state.stage.entities.where(state.isVisible).toList()
      ..sort((a, b) => a.y.compareTo(b.y));
    for (final e in visible) {
      _drawEntity(canvas, e);
    }

    _drawPlayer(canvas);
    _drawParticles(canvas);
    canvas.restore();

    _drawTransition(canvas, w, h);
  }

  void _drawFloor(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(floorColor, Colors.white, 0.35)!,
            floorColor,
          ],
        ).createShader(rect),
    );

    final grid = Paint()
      ..color = wallColor.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y < h; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    canvas.drawRect(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      Paint()
        ..color = wallColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    _label(canvas, sceneName.toUpperCase(), Offset(w / 2, 24), fontSize: 11);
  }

  void _drawObstacles(Canvas canvas) {
    for (final o in _obstacles) {
      final rect = _rectPx(o);
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      canvas.drawRRect(
        shape.shift(const Offset(0, 4)),
        Paint()..color = Colors.black.withValues(alpha: 0.10),
      );
      canvas.drawRRect(shape, Paint()..color = wallColor);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(7)),
        Paint()..color = floorColor.withValues(alpha: 0.9),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..color = accentColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawBlockers(Canvas canvas) {
    for (final b in state.stage.blockers) {
      final goneAt = _blockerGoneAt[b.id];
      var alpha = 1.0;
      if (goneAt != null) {
        alpha = (1 - (_t - goneAt) / 0.6).clamp(0.0, 1.0).toDouble();
        if (alpha <= 0) continue;
      } else if (state.done.contains(b.removedBy)) {
        continue;
      }

      final rect = _rectPx(b.rect);
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(
        shape,
        Paint()..color = const Color(0xFF3B0764).withValues(alpha: 0.88 * alpha),
      );

      canvas.save();
      canvas.clipRRect(shape);
      final stripe = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85 * alpha)
        ..strokeWidth = 5;
      for (double x = rect.left - rect.height; x < rect.right; x += 22) {
        canvas.drawLine(
          Offset(x, rect.bottom),
          Offset(x + rect.height, rect.top),
          stripe,
        );
      }
      canvas.restore();

      canvas.drawRRect(
        shape,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      if (b.label.isNotEmpty && goneAt == null) {
        _label(canvas, '🚧 ${b.label}',
            Offset(rect.center.dx, rect.top - 11),
            fontSize: 10);
      }
    }
  }

  String _defaultIcon(EntitySpec e) {
    switch (e.type) {
      case EntityType.evidence:
        return '🔍';
      case EntityType.item:
        return '🎒';
      case EntityType.target:
        return '⚙️';
      case EntityType.door:
        return '🚪';
      case EntityType.puzzle:
        final type = state.spec.puzzleById(e.puzzleId ?? '')?.type;
        switch (type) {
          case 'codeLock':
            return '🔢';
          case 'sequence':
            return '🔀';
          case 'matching':
            return '🧩';
          case 'choice':
            return '💡';
          case 'sort':
            return '🗂️';
          case 'experiment':
            return '🧪';
          default:
            return '❓';
        }
    }
  }

  Color _baseColor(EntitySpec e, bool unlocked) {
    if (!unlocked) return const Color(0xFF9CA3AF);
    switch (e.type) {
      case EntityType.evidence:
        return const Color(0xFFF59E0B);
      case EntityType.item:
        return const Color(0xFF14B8A6);
      case EntityType.target:
        return const Color(0xFFF97316);
      case EntityType.puzzle:
      case EntityType.door:
        return accentColor;
    }
  }

  double _easeOutBack(double p) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(p - 1, 3).toDouble() +
        c1 * math.pow(p - 1, 2).toDouble();
  }

  void _drawEntity(Canvas canvas, EntitySpec e) {
    final done = state.entityDone(e);
    if (e.type == EntityType.item && done) return; // picked up

    final center = _px(Offset(e.x, e.y));
    final r = _entityRadius;
    final unlocked = state.requirementsMet(e);
    final isNear = nearby.value?.id == e.id;

    var scale = 1.0;
    final start = _revealStart[e.id];
    if (start != null) {
      final p = ((_t - start) / 0.6).clamp(0.0, 1.0).toDouble();
      scale = _easeOutBack(p);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    if (e.type == EntityType.door) {
      _drawDoor(canvas, e, r, unlocked, isNear);
    } else if (done) {
      canvas.drawCircle(Offset.zero, r * 0.7,
          Paint()..color = const Color(0xFF22C55E));
      _label(canvas, '✓', Offset.zero, fontSize: r, color: Colors.white);
    } else {
      _drawPickup(canvas, e, r, unlocked, isNear);
    }

    canvas.restore();
  }

  void _drawPickup(
    Canvas canvas,
    EntitySpec e,
    double r,
    bool unlocked,
    bool isNear,
  ) {
    final base = _baseColor(e, unlocked);
    final pulse = 1 + 0.06 * math.sin(_t * 3 + e.x * 9);

    if (unlocked) {
      canvas.drawCircle(
        Offset.zero,
        r * 1.8 * pulse,
        Paint()..color = base.withValues(alpha: 0.16),
      );
    }

    if (isNear) {
      canvas.drawCircle(
        Offset.zero,
        r * 1.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(
        Offset.zero,
        r * 1.5,
        Paint()
          ..color = base
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.drawCircle(
      const Offset(0, 3),
      r * pulse,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawCircle(Offset.zero, r * pulse, Paint()..color = base);
    canvas.drawCircle(
      Offset.zero,
      r * 0.78 * pulse,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );

    final icon = e.icon.isNotEmpty ? e.icon : _defaultIcon(e);
    _label(canvas, icon, Offset.zero, fontSize: r * 1.05);

    if (!unlocked) {
      _label(canvas, '🔒', Offset(r * 0.8, -r * 0.8), fontSize: r * 0.75);
    }

    _label(canvas, e.name, Offset(0, r + 14), fontSize: 10);
  }

  void _drawDoor(
    Canvas canvas,
    EntitySpec e,
    double r,
    bool unlocked,
    bool isNear,
  ) {
    final frame = Rect.fromCenter(
      center: Offset.zero,
      width: r * 1.9,
      height: r * 2.6,
    );
    final frameShape =
        RRect.fromRectAndRadius(frame, const Radius.circular(10));

    if (_doorOpen > 0 || unlocked) {
      canvas.drawCircle(
        Offset.zero,
        r * 2.1,
        Paint()
          ..color = const Color(0xFF22C55E)
              .withValues(alpha: 0.12 + 0.12 * _doorOpen),
      );
    }

    canvas.drawRRect(frameShape, Paint()..color = const Color(0xFF3B0764));

    if (_doorOpen > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(frame.deflate(4), const Radius.circular(7)),
        Paint()..color = const Color(0xFFFDE68A),
      );
    }

    final panelWidth = (frame.width - 8) * (1 - _doorOpen);
    if (panelWidth > 1) {
      final panel = Rect.fromLTWH(
        frame.left + 4,
        frame.top + 4,
        panelWidth,
        frame.height - 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(7)),
        Paint()..color = unlocked ? const Color(0xFF22C55E) : accentColor,
      );
      canvas.drawCircle(
        Offset(panel.right - 7, panel.center.dy),
        2.6,
        Paint()..color = Colors.white,
      );
    }

    if (isNear) {
      canvas.drawRRect(
        frameShape.inflate(5),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    if (!unlocked) _label(canvas, '🔒', Offset.zero, fontSize: r * 0.9);
    _label(canvas, e.name, Offset(0, r * 1.3 + 14), fontSize: 10);
  }

  void _drawPlayer(Canvas canvas) {
    final center = _px(player);
    final r = _playerRadius;
    final bob = _moving ? math.sin(_t * 14) * 2.2 : math.sin(_t * 2.5) * 1.0;
    final body = center + Offset(0, bob);

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r + 4),
        width: r * 2,
        height: r * 0.7,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    canvas.drawCircle(body, r, Paint()..color = const Color(0xFF7C3AED));
    canvas.drawCircle(
      body + Offset(-r * 0.3, -r * 0.35),
      r * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    final eyeShift = _facing * r * 0.12;
    for (final dx in [-0.34, 0.34]) {
      canvas.drawCircle(
        body + Offset(r * dx + eyeShift, -r * 0.12),
        r * 0.19,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        body + Offset(r * dx + eyeShift * 1.6, -r * 0.12),
        r * 0.09,
        Paint()..color = const Color(0xFF3B0764),
      );
    }

    canvas.drawArc(
      Rect.fromCenter(
        center: body + Offset(eyeShift, r * 0.25),
        width: r * 0.7,
        height: r * 0.45,
      ),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _drawParticles(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(
        p.pos,
        p.radius,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  void _drawTransition(Canvas canvas, double w, double h) {
    if (_transition <= 0) return;
    final a = _transition.clamp(0.0, 1.0).toDouble();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF3B0764).withValues(alpha: a),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: _banner,
        style: TextStyle(
          color: Colors.white.withValues(alpha: math.min(1.0, a * 1.5)),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: math.max(120, w * 0.8));

    painter.paint(
      canvas,
      Offset((w - painter.width) / 2, (h - painter.height) / 2),
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 12,
    Color color = const Color(0xFF3B0764),
    bool bold = true,
  }) {
    final key = '$text|$fontSize|${color.hashCode}|$bold';
    final painter = _labels.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: 160),
    );
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}