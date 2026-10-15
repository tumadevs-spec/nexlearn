import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/adventure_service.dart';

class MysteryGameScreen extends StatefulWidget {
  const MysteryGameScreen({
    super.key,
    required this.topicName,
    required this.classNumber,
    required this.subject,
    required this.curriculumPath,
    required this.mode,
  });

  final String topicName;
  final int classNumber;
  final String subject;
  final String curriculumPath;
  final String mode;

  @override
  State<MysteryGameScreen> createState() => _MysteryGameScreenState();
}

class _MysteryGameScreenState extends State<MysteryGameScreen> {
  late final MysteryWorldGame _game;
  bool _isLoading = true;
  String? _loadError;

  static const violet = Color(0xFF7C3AED);
  static const deepViolet = Color(0xFF3B0764);

  @override
  void initState() {
    super.initState();
    _game = MysteryWorldGame(onChanged: _refresh);
    _loadAdventure();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAdventure() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Read the selected topic and its learning objectives.
      final jsonText = await rootBundle.loadString(widget.curriculumPath);
      final curriculum = jsonDecode(jsonText) as Map<String, dynamic>;
      final classes = curriculum['classes'] as List<dynamic>? ?? [];

      Map<String, dynamic>? selectedTopic;

      for (final classEntry in classes) {
        if (classEntry is! Map) continue;

        final classMap = Map<String, dynamic>.from(classEntry);
        if (classMap['class'] != widget.classNumber) continue;

        final strands = classMap['strands'] as List<dynamic>? ?? [];

        for (final strand in strands) {
          if (strand is! Map) continue;

          final topics = strand['topics'] as List<dynamic>? ?? [];

          for (final topic in topics) {
            if (topic is! Map) continue;

            final topicMap = Map<String, dynamic>.from(topic);
            final name = topicMap['name']?.toString() ?? '';
            final id = topicMap['id']?.toString() ?? '';

            if (name == widget.topicName || id == widget.topicName) {
              selectedTopic = topicMap;
              break;
            }
          }

          if (selectedTopic != null) break;
        }

        break;
      }

      if (selectedTopic == null) {
        throw Exception(
          'Topic "${widget.topicName}" was not found in '
          'the selected class curriculum.',
        );
      }

      final rawObjectives =
          selectedTopic['learning_objectives'] as List<dynamic>? ?? [];

      final objectives = rawObjectives
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(5)
          .toList();

      if (objectives.isEmpty) {
        throw Exception('This topic has no learning objectives.');
      }

      final preferences = await SharedPreferences.getInstance();
      final age = preferences.getInt('player_age') ?? 6;

      // Ask the Firebase callable function to generate the adventure.
      final adventure = await AdventureService().generateAdventure(
        subject: widget.subject,
        topicName: widget.topicName,
        classNumber: widget.classNumber,
        age: age,
        learningObjectives: objectives,
      );

      if (!mounted) return;

      _game.loadAdventure(adventure);

      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _restart() {
    if (_game.hasAdventure) {
      _game.reset();
    } else {
      _loadAdventure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: deepViolet,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: deepViolet,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${widget.subject} • Class ${widget.classNumber}',
                          style: const TextStyle(
                            color: Color(0xFF7C6A99),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _restart,
                    tooltip: 'Restart adventure',
                    icon: const Icon(Icons.refresh_rounded),
                    color: violet,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: violet,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _game.hasAdventure
                          ? 'Clues found: ${_game.cluesFound}/${_game.totalClues}'
                          : 'Preparing your adventure...',
                      style: const TextStyle(
                        color: deepViolet,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_game.completed)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget<MysteryWorldGame>(game: _game),
                      if (_isLoading)
                        Container(
                          color: const Color(0xFFF5F3FF),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: violet),
                                SizedBox(height: 18),
                                Text(
                                  'Creating your adventure...',
                                  style: TextStyle(
                                    color: deepViolet,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Building your world and clues',
                                  style: TextStyle(
                                    color: Color(0xFF7C6A99),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_loadError != null)
                        Container(
                          color: const Color(0xFFF5F3FF),
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_off_rounded,
                                    size: 46,
                                    color: violet,
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Adventure could not be created',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: deepViolet,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _loadError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF665477),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: _loadAdventure,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Try again'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: violet,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!_isLoading && _loadError == null && _game.completed)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.all(14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD8CCF7),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: violet,
                                  size: 34,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _game.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: deepViolet,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _game.learningSummary,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF665477),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  Text(
                    _game.message,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: deepViolet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MoveButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'LEFT',
                          onPressed: () => _game.moveOneStep(-1, 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MoveButton(
                          icon: Icons.arrow_upward_rounded,
                          label: 'UP',
                          onPressed: () => _game.moveOneStep(0, -1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MoveButton(
                          icon: Icons.arrow_downward_rounded,
                          label: 'DOWN',
                          onPressed: () => _game.moveOneStep(0, 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MoveButton(
                          icon: Icons.arrow_forward_rounded,
                          label: 'RIGHT',
                          onPressed: () => _game.moveOneStep(1, 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _loadError != null
                          ? null
                          : _game.interact,
                      icon: const Icon(Icons.touch_app_rounded),
                      label: const Text('INTERACT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violet,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD8CCF7),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF7C3AED), size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF3B0764),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MysteryWorldGame extends FlameGame {
  MysteryWorldGame({required this.onChanged});

  final VoidCallback onChanged;

  static const double _playerRadius = 13;
static const double _movementSpeed = 0.05;

  bool hasAdventure = false;
  bool completed = false;

  String title = 'Your Adventure';
  String story = '';
  String settingName = 'Mystery World';
  String learningSummary = '';
  String message = 'Explore your world and discover the clues.';

  Color floorColor = const Color(0xFFF5F3FF);
  Color wallColor = const Color(0xFFB9A3EC);
  Color accentColor = const Color(0xFF7C3AED);

  Offset player = const Offset(0.5, 0.82);
  Offset spawn = const Offset(0.5, 0.82);
  Offset exitPosition = const Offset(0.5, 0.12);

  String exitName = 'Exit';
  String lockedText = 'Find all the clues to unlock the exit.';
  String unlockedText = 'The exit is unlocked!';

  int cluesFound = 0;
  int unlockAfterClues = 3;

  List<Map<String, dynamic>> _clues = [];
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _obstacles = [];

  final Set<String> _collected = {};
  final Set<LogicalKeyboardKey> _keys = {};

  int get totalClues => _clues.length;

  Color _readColor(dynamic value, Color fallback) {
    if (value is! String) return fallback;

    var hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Offset _readPoint(dynamic value, Offset fallback) {
    if (value is! Map) return fallback;

    final x = value['x'];
    final y = value['y'];

    if (x is! num || y is! num) return fallback;

    return Offset(
      x.toDouble().clamp(0.04, 0.96),
      y.toDouble().clamp(0.04, 0.96),
    );
  }

  List<Map<String, dynamic>> _readItems(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void loadAdventure(Map<String, dynamic> data) {
    title = data['title']?.toString() ?? 'Mystery Adventure';
    story = data['story']?.toString() ?? '';
    learningSummary = data['learningSummary']?.toString() ??
        'Explore, investigate, and learn something new.';

    final environment = data['environment'] is Map
        ? Map<String, dynamic>.from(data['environment'] as Map)
        : <String, dynamic>{};

    settingName = environment['name']?.toString() ?? 'Mystery World';
    floorColor = _readColor(
      environment['floorColor'],
      const Color(0xFFF5F3FF),
    );
    wallColor = _readColor(
      environment['wallColor'],
      const Color(0xFFB9A3EC),
    );
    accentColor = _readColor(
      environment['accentColor'],
      const Color(0xFF7C3AED),
    );

    final rawPlayer = data['spawn'];
    spawn = _readPoint(rawPlayer, const Offset(0.5, 0.82));
    player = spawn;

    _clues = _readItems(data['clues']);
    _objects = _readItems(data['objects']);
    _obstacles = _readItems(data['obstacles']);

    final exit = data['exit'] is Map
        ? Map<String, dynamic>.from(data['exit'] as Map)
        : <String, dynamic>{};

    exitPosition = _readPoint(
      exit,
      const Offset(0.5, 0.12),
    );
    exitName = exit['name']?.toString() ?? 'Exit';
    lockedText = exit['lockedText']?.toString() ??
        'Find all the clues to unlock the exit.';
    unlockedText = exit['unlockedText']?.toString() ?? 'The exit is unlocked!';

    final requiredClues = exit['unlockAfterClues'];
    unlockAfterClues =
        requiredClues is num ? requiredClues.toInt() : _clues.length;

    _collected.clear();
    _keys.clear();
    cluesFound = 0;
    completed = false;
    hasAdventure = true;
    message =
        story.isNotEmpty ? story : 'Explore $settingName and find the clues.';

    onChanged();
  }

  Offset _pixelPoint(Offset normalized) {
    return Offset(normalized.dx * size.x, normalized.dy * size.y);
  }

  List<Rect> get _obstacleRects {
    return _obstacles.map((obstacle) {
      final x = (obstacle['x'] as num?)?.toDouble() ?? 0.4;
      final y = (obstacle['y'] as num?)?.toDouble() ?? 0.4;
      final width = (obstacle['width'] as num?)?.toDouble() ?? 0.1;
      final height = (obstacle['height'] as num?)?.toDouble() ?? 0.1;

      return Rect.fromLTWH(
        x * size.x,
        y * size.y,
        width * size.x,
        height * size.y,
      );
    }).toList();
  }

  bool _collides(Offset normalized) {
    final point = _pixelPoint(normalized);
    final playerRect = Rect.fromCircle(
      center: point,
      radius: _playerRadius,
    );

    for (final obstacle in _obstacleRects) {
      if (playerRect.overlaps(obstacle)) return true;
    }

    return false;
  }

  void moveOneStep(double dx, double dy) {
    if (!hasAdventure || completed || size.x <= 0 || size.y <= 0) return;

    final next = Offset(
      (player.dx + dx * _movementSpeed).clamp(0.04, 0.96),
      (player.dy + dy * _movementSpeed).clamp(0.04, 0.96),
    );

    if (!_collides(next)) {
      player = next;
    } else {
      message = 'There is an obstacle in the way. Try another route.';
    }

    onChanged();
  }

  void interact() {
    if (!hasAdventure || completed) return;

    final playerPixels = _pixelPoint(player);

    // Check clues first.
    Map<String, dynamic>? nearestClue;
    double nearestDistance = double.infinity;

    for (final clue in _clues) {
      final id = clue['id']?.toString() ?? '';
      if (_collected.contains(id)) continue;

      final point = _pixelPoint(
        _readPoint(clue, const Offset(0.5, 0.5)),
      );
      final distance = (point - playerPixels).distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestClue = clue;
      }
    }

    if (nearestClue != null && nearestDistance < 70) {
      final id = nearestClue['id']?.toString() ?? '';
      _collected.add(id);
      cluesFound = _collected.length;

      final discovery = nearestClue['discoveryText']?.toString() ??
          nearestClue['evidence']?.toString() ??
          'You discovered a clue!';

      message = discovery;
      onChanged();
      return;
    }

    // Check interactive objects.
    Map<String, dynamic>? nearestObject;
    nearestDistance = double.infinity;

    for (final object in _objects) {
      final point = _pixelPoint(
        _readPoint(object, const Offset(0.5, 0.5)),
      );
      final distance = (point - playerPixels).distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestObject = object;
      }
    }

    if (nearestObject != null && nearestDistance < 70) {
      message = nearestObject['interactionText']?.toString() ??
          nearestObject['description']?.toString() ??
          'You investigated an object.';
      onChanged();
      return;
    }

    final exitPixels = _pixelPoint(exitPosition);
    if ((exitPixels - playerPixels).distance < 75) {
      if (cluesFound >= unlockAfterClues) {
        completed = true;
        message = 'Mission complete! You explored $settingName.';
      } else {
        message = lockedText;
      }

      onChanged();
      return;
    }

    message = 'Move closer to a clue, object, or exit, then interact.';
    onChanged();
  }

  void reset() {
    player = spawn;
    _collected.clear();
    _keys.clear();
    cluesFound = 0;
    completed = false;
    message = 'Your adventure has restarted. Find the clues!';
    onChanged();
  }

  void setKey(LogicalKeyboardKey key, bool pressed) {
    if (pressed) {
      _keys.add(key);
    } else {
      _keys.remove(key);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!hasAdventure || completed || size.x <= 0 || size.y <= 0) {
      return;
    }

    var dx = 0.0;
    var dy = 0.0;

    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      dx += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) {
      dy += 1;
    }

    if (dx == 0 && dy == 0) return;

    final length = math.sqrt(dx * dx + dy * dy);
    dx /= length;
    dy /= length;

    final next = Offset(
      (player.dx + dx * _movementSpeed * dt).clamp(0.04, 0.96),
      (player.dy + dy * _movementSpeed * dt).clamp(0.04, 0.96),
    );

    if (!_collides(next)) player = next;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = size.x;
    final height = size.y;

    if (width <= 0 || height <= 0) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = floorColor,
    );

    // Floor grid.
    final gridPaint = Paint()
      ..color = wallColor.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    for (double x = 0; x < width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // World boundary.
    canvas.drawRect(
      Rect.fromLTWH(4, 4, width - 8, height - 8),
      Paint()
        ..color = wallColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    _drawLabel(
      canvas,
      settingName.toUpperCase(),
      Offset(width / 2, 23),
      color: const Color(0xFF3B0764),
      fontSize: 12,
      bold: true,
    );

    _drawExit(canvas);
    _drawObstacles(canvas);
    _drawObjects(canvas);
    _drawClues(canvas);
    _drawPlayer(canvas);
  }

  void _drawExit(Canvas canvas) {
    final point = _pixelPoint(exitPosition);
    final isUnlocked = cluesFound >= unlockAfterClues;

    canvas.drawCircle(
      point,
      27,
      Paint()
        ..color = (isUnlocked ? const Color(0xFF22C55E) : accentColor)
            .withValues(alpha: 0.16),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: point, width: 38, height: 43),
        const Radius.circular(8),
      ),
      Paint()
        ..color =
            isUnlocked ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6),
    );

    canvas.drawCircle(
      point + const Offset(8, 0),
      2.5,
      Paint()..color = Colors.white,
    );

    _drawLabel(
      canvas,
      isUnlocked ? exitName : 'LOCKED',
      point + const Offset(0, 35),
      color: const Color(0xFF3B0764),
      fontSize: 10,
      bold: true,
    );
  }

  void _drawObstacles(Canvas canvas) {
    for (var i = 0; i < _obstacleRects.length; i++) {
      final rect = _obstacleRects[i];

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        Paint()..color = wallColor,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(4),
          const Radius.circular(6),
        ),
        Paint()..color = floorColor.withValues(alpha: 0.9),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        Paint()
          ..color = accentColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawClues(Canvas canvas) {
    for (final clue in _clues) {
      final id = clue['id']?.toString() ?? '';
      final found = _collected.contains(id);
      final point = _pixelPoint(
        _readPoint(clue, const Offset(0.5, 0.5)),
      );

      if (found) {
        canvas.drawCircle(
          point,
          12,
          Paint()..color = const Color(0xFF22C55E),
        );
        _drawLabel(
          canvas,
          '✓',
          point,
          color: Colors.white,
          fontSize: 16,
          bold: true,
        );
      } else {
        canvas.drawCircle(
          point,
          24,
          Paint()..color = accentColor.withValues(alpha: 0.13),
        );
        canvas.drawCircle(
          point,
          15,
          Paint()..color = accentColor,
        );
        canvas.drawCircle(
          point,
          6,
          Paint()..color = Colors.white,
        );

        _drawLabel(
          canvas,
          clue['name']?.toString() ?? 'Clue',
          point + const Offset(0, 29),
          color: const Color(0xFF3B0764),
          fontSize: 10,
          bold: true,
        );
      }
    }
  }

  void _drawObjects(Canvas canvas) {
    for (final object in _objects) {
      final point = _pixelPoint(
        _readPoint(object, const Offset(0.5, 0.5)),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: point, width: 31, height: 27),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xFFFFD166),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: point, width: 31, height: 27),
          const Radius.circular(7),
        ),
        Paint()
          ..color = const Color(0xFFB7791F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      _drawLabel(
        canvas,
        object['name']?.toString() ?? 'Object',
        point + const Offset(0, 22),
        color: const Color(0xFF3B0764),
        fontSize: 9,
        bold: true,
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    final point = _pixelPoint(player);

    canvas.drawCircle(
      point + const Offset(0, 5),
      _playerRadius + 3,
      Paint()..color = accentColor.withValues(alpha: 0.16),
    );

    canvas.drawCircle(
      point,
      _playerRadius,
      Paint()..color = const Color(0xFF7C3AED),
    );

    canvas.drawCircle(
      point + const Offset(-4, -2),
      2,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      point + const Offset(4, -2),
      2,
      Paint()..color = Colors.white,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: point + const Offset(0, 2),
        width: 10,
        height: 7,
      ),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center, {
    Color color = const Color(0xFF3B0764),
    double fontSize = 12,
    bool bold = false,
  }) {
    final painter = TextPainter(
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
    )..layout(maxWidth: math.max(60, size.x * 0.7));

    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }
}
