import 'dart:math' as math;
import 'dart:ui' show Color, Offset, Rect;

import '../engine/mechanic_registry.dart';

enum EntityType { evidence, item, puzzle, target, door }

class SpecValidationException implements Exception {
  SpecValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'Invalid adventure: ${errors.join('; ')}';
}

class EntitySpec {
  const EntitySpec({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.x,
    required this.y,
    required this.text,
    required this.requires,
    required this.lockedText,
    required this.hidden,
    this.revealedBy,
    this.puzzleId,
    this.needsItem,
    this.successText = '',
    this.wrongItemText = '',
  });

  final String id;
  final EntityType type;
  final String name;
  final String icon;
  final double x;
  final double y;
  final String text;
  final List<String> requires;
  final String lockedText;

  /// Starts invisible and appears when [revealedBy] is done.
  final bool hidden;
  final String? revealedBy;

  /// For puzzle spots: which puzzle opens here.
  final String? puzzleId;

  /// For targets: the item that must be used here.
  final String? needsItem;
  final String successText;
  final String wrongItemText;

  EntitySpec copyWith({List<String>? requires, String? revealedBy}) =>
      EntitySpec(
        id: id,
        type: type,
        name: name,
        icon: icon,
        x: x,
        y: y,
        text: text,
        requires: requires ?? this.requires,
        lockedText: lockedText,
        hidden: hidden,
        revealedBy: revealedBy ?? this.revealedBy,
        puzzleId: puzzleId,
        needsItem: needsItem,
        successText: successText,
        wrongItemText: wrongItemText,
      );
}

/// A barrier that blocks movement until [removedBy] is done.
class BlockerSpec {
  const BlockerSpec({
    required this.id,
    required this.rect,
    required this.label,
    required this.removedBy,
  });

  final String id;
  final Rect rect; // normalized 0..1
  final String label;
  final String removedBy;

  BlockerSpec copyWith({String? removedBy}) => BlockerSpec(
        id: id,
        rect: rect,
        label: label,
        removedBy: removedBy ?? this.removedBy,
      );
}

class StageSpec {
  const StageSpec({
    required this.id,
    required this.name,
    required this.intro,
    required this.floorColor,
    required this.wallColor,
    required this.accentColor,
    required this.spawn,
    required this.obstacles,
    required this.blockers,
    required this.entities,
  });

  final String id;
  final String name;
  final String intro;
  final Color floorColor;
  final Color wallColor;
  final Color accentColor;
  final Offset spawn;
  final List<Rect> obstacles;
  final List<BlockerSpec> blockers;
  final List<EntitySpec> entities;

  StageSpec withParts({
    required List<EntitySpec> entities,
    required List<BlockerSpec> blockers,
  }) =>
      StageSpec(
        id: id,
        name: name,
        intro: intro,
        floorColor: floorColor,
        wallColor: wallColor,
        accentColor: accentColor,
        spawn: spawn,
        obstacles: obstacles,
        blockers: blockers,
        entities: entities,
      );
}

class PuzzleSpec {
  const PuzzleSpec({
    required this.id,
    required this.type,
    required this.prompt,
    required this.config,
    required this.feedbackCorrect,
    required this.feedbackWrong,
    required this.hint,
    required this.skill,
  });

  final String id;
  final String type;
  final String prompt;
  final Map<String, dynamic> config;
  final String feedbackCorrect;
  final String feedbackWrong;
  final String hint;
  final String skill;
}

class AdventureSpec {
  AdventureSpec._({
    required this.title,
    required this.story,
    required this.learningSummary,
    required this.stages,
    required this.puzzles,
    required this.finalPuzzleId,
  });

  final String title;
  final String story;
  final String learningSummary;
  final List<StageSpec> stages;
  final List<PuzzleSpec> puzzles;
  final String finalPuzzleId;

  Iterable<EntitySpec> get allEntities => stages.expand((s) => s.entities);

  EntitySpec? entityById(String id) {
    for (final e in allEntities) {
      if (e.id == id) return e;
    }
    return null;
  }

  PuzzleSpec? puzzleById(String id) {
    for (final p in puzzles) {
      if (p.id == id) return p;
    }
    return null;
  }

  int stageIndexOf(String entityId) {
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].entities.any((e) => e.id == entityId)) return i;
    }
    return -1;
  }

  /// Parses and validates untrusted data. Accepts spec v3, and upgrades v2
  /// (a single room) into one stage. Throws [SpecValidationException].
  static AdventureSpec parse(Map<String, dynamic> input) {
    final rawVersion = input['specVersion'];
    final version = rawVersion is num ? rawVersion.toInt() : null;
    if (version != 2 && version != 3) {
      throw SpecValidationException(['specVersion: must be 2 or 3']);
    }
    final json = version == 2 ? _upgradeV2(input) : input;

    final errors = <String>[];

    final title = _text(errors, 'title', json['title'], 100);
    final story = _text(errors, 'story', json['story'], 700);
    final summary =
        _text(errors, 'learningSummary', json['learningSummary'], 300);
    final finalPuzzleId =
        _text(errors, 'finalPuzzleId', json['finalPuzzleId'], 40);

    final puzzles = <PuzzleSpec>[];
    final rawPuzzles = json['puzzles'];
    if (rawPuzzles is! List || rawPuzzles.isEmpty) {
      errors.add('puzzles: required non-empty list');
    } else {
      for (var i = 0; i < rawPuzzles.length && i < 8; i++) {
        final puzzle = _parsePuzzle(errors, i, rawPuzzles[i]);
        if (puzzle != null) puzzles.add(puzzle);
      }
    }

    var stages = <StageSpec>[];
    final rawStages = json['stages'];
    if (rawStages is! List || rawStages.isEmpty || rawStages.length > 4) {
      errors.add('stages: 1 to 4 stages required');
    } else {
      for (var i = 0; i < rawStages.length; i++) {
        final stage = _parseStage(errors, i, rawStages[i]);
        if (stage != null) stages.add(stage);
      }
    }

    stages = _resolveReferences(stages);
    _crossCheck(errors, stages, puzzles, finalPuzzleId);

    if (errors.isNotEmpty) throw SpecValidationException(errors);

    return AdventureSpec._(
      title: title,
      story: story,
      learningSummary: summary,
      stages: stages,
      puzzles: puzzles,
      finalPuzzleId: finalPuzzleId,
    );
  }
}

// ------------------------------------------------------------ v2 upgrade

Map<String, dynamic> _upgradeV2(Map<String, dynamic> v2) {
  final env = v2['environment'];
  return {
    'specVersion': 3,
    'title': v2['title'],
    'story': v2['story'],
    'learningSummary': v2['learningSummary'],
    'finalPuzzleId': v2['finalPuzzleId'],
    'puzzles': v2['puzzles'],
    'stages': [
      {
        'id': 'stage_1',
        'name': env is Map ? env['name'] : 'Mystery',
        'intro': v2['story'],
        'environment': env,
        'spawn': v2['spawn'],
        'obstacles': v2['obstacles'],
        'blockers': <dynamic>[],
        'entities': v2['entities'],
      },
    ],
  };
}

// --------------------------------------------------------------- helpers

String _text(List<String> errors, String path, dynamic value, int max) {
  if (value is! String || value.trim().isEmpty) {
    errors.add('$path: missing or empty text');
    return '';
  }
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return clean.length <= max ? clean : clean.substring(0, max);
}

String _optText(dynamic value, int max) {
  if (value is! String) return '';
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return clean.length <= max ? clean : clean.substring(0, max);
}

String _icon(dynamic value) {
  if (value is! String) return '';
  final clean = value.trim();
  return clean.runes.length <= 6 ? clean : '';
}

double _clampD(num value, double lo, double hi) =>
    math.min(math.max(value.toDouble(), lo), hi);

double? _coord(List<String> errors, String path, dynamic value) {
  if (value is! num || value < 0.04 || value > 0.96) {
    errors.add('$path: must be a number between 0.04 and 0.96');
    return null;
  }
  return value.toDouble();
}

List<String> _idList(List<String> errors, String path, dynamic value) {
  if (value == null) return [];
  if (value is! List || value.any((v) => v is! String)) {
    errors.add('$path: must be a list of ids');
    return [];
  }
  return value.cast<String>().map((s) => s.trim()).toList();
}

String? _optId(dynamic value) {
  if (value is! String) return null;
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}

Color _color(dynamic value, Color fallback) {
  if (value is! String) return fallback;
  final hex = value.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) return fallback;
  return Color(int.parse('FF$hex', radix: 16));
}

Rect? _rect(dynamic value) {
  if (value is! Map) return null;
  final x = value['x'];
  final y = value['y'];
  final w = value['width'];
  final h = value['height'];
  if (x is! num || y is! num || w is! num || h is! num) return null;
  final left = _clampD(x, 0.0, 0.98);
  final top = _clampD(y, 0.0, 0.98);
  final width = _clampD(w, 0.02, 1.0 - left);
  final height = _clampD(h, 0.02, 1.0 - top);
  return Rect.fromLTWH(left, top, width, height);
}

// ------------------------------------------------------------- parsers

StageSpec? _parseStage(List<String> errors, int i, dynamic item) {
  final path = 'stages[$i]';
  if (item is! Map) {
    errors.add('$path: not an object');
    return null;
  }

  final id = _text(errors, '$path.id', item['id'], 40);
  final name = _text(errors, '$path.name', item['name'], 80);
  final intro = _text(errors, '$path.intro', item['intro'], 400);

  final env = item['environment'] is Map
      ? Map<String, dynamic>.from(item['environment'] as Map)
      : <String, dynamic>{};

  final spawnRaw = item['spawn'];
  final sx = _coord(errors, '$path.spawn.x', spawnRaw is Map ? spawnRaw['x'] : null);
  final sy = _coord(errors, '$path.spawn.y', spawnRaw is Map ? spawnRaw['y'] : null);

  final obstacles = <Rect>[];
  final rawObstacles = item['obstacles'];
  if (rawObstacles is List) {
    for (var o = 0; o < rawObstacles.length && o < 8; o++) {
      final rect = _rect(rawObstacles[o]);
      if (rect != null) obstacles.add(rect);
    }
  }

  final blockers = <BlockerSpec>[];
  final rawBlockers = item['blockers'];
  if (rawBlockers is List) {
    for (var b = 0; b < rawBlockers.length && b < 4; b++) {
      final raw = rawBlockers[b];
      final rect = _rect(raw);
      if (raw is! Map || rect == null) continue;
      blockers.add(BlockerSpec(
        id: _text(errors, '$path.blockers[$b].id', raw['id'], 40),
        rect: rect,
        label: _optText(raw['label'], 40),
        removedBy:
            _text(errors, '$path.blockers[$b].removedBy', raw['removedBy'], 40),
      ));
    }
  }

  final entities = <EntitySpec>[];
  final rawEntities = item['entities'];
  if (rawEntities is! List || rawEntities.isEmpty) {
    errors.add('$path.entities: required non-empty list');
  } else {
    if (rawEntities.length > 14) {
      errors.add('$path.entities: at most 14 allowed');
    }
    for (var e = 0; e < rawEntities.length && e < 14; e++) {
      final entity = _parseEntity(errors, '$path.entities[$e]', rawEntities[e]);
      if (entity != null) entities.add(entity);
    }
  }

  return StageSpec(
    id: id,
    name: name,
    intro: intro,
    floorColor: _color(env['floorColor'], const Color(0xFFEDE9FE)),
    wallColor: _color(env['wallColor'], const Color(0xFFB9A3EC)),
    accentColor: _color(env['accentColor'], const Color(0xFF7C3AED)),
    spawn: Offset(sx ?? 0.5, sy ?? 0.85),
    obstacles: obstacles,
    blockers: blockers,
    entities: entities,
  );
}

EntitySpec? _parseEntity(List<String> errors, String path, dynamic item) {
  if (item is! Map) {
    errors.add('$path: not an object');
    return null;
  }

  final id = _text(errors, '$path.id', item['id'], 40);
  final name = _text(errors, '$path.name', item['name'], 60);
  final text = _text(errors, '$path.text', item['text'], 300);

  EntityType? type;
  for (final t in EntityType.values) {
    if (t.name == item['type']) type = t;
  }
  if (type == null) {
    errors.add('$path.type: unsupported "${item['type']}"');
  }

  final x = _coord(errors, '$path.x', item['x']);
  final y = _coord(errors, '$path.y', item['y']);
  final requires = _idList(errors, '$path.requires', item['requires']);

  String? puzzleId;
  if (type == EntityType.puzzle) {
    puzzleId = _text(errors, '$path.puzzleId', item['puzzleId'], 40);
  }

  if (type == null || x == null || y == null) return null;

  final locked = _optText(item['lockedText'], 180);

  return EntitySpec(
    id: id,
    type: type,
    name: name,
    icon: _icon(item['icon']),
    x: x,
    y: y,
    text: text,
    requires: requires,
    lockedText: locked.isEmpty
        ? 'Something is still missing. Keep investigating.'
        : locked,
    hidden: item['hidden'] == true,
    revealedBy: _optId(item['revealedBy']),
    puzzleId: puzzleId,
    needsItem: _optId(item['needsItem']),
    successText: _optText(item['successText'], 200),
    wrongItemText: _optText(item['wrongItemText'], 200),
  );
}

PuzzleSpec? _parsePuzzle(List<String> errors, int i, dynamic item) {
  final path = 'puzzles[$i]';
  if (item is! Map) {
    errors.add('$path: not an object');
    return null;
  }

  final id = _text(errors, '$path.id', item['id'], 40);
  final type = item['type'];
  final mechanic = type is String ? MechanicRegistry.lookup(type) : null;

  if (mechanic == null) {
    errors.add('$path.type: unsupported mechanic "$type"');
    return null;
  }

  final config = item['config'];
  if (config is! Map) {
    errors.add('$path.config: missing');
    return null;
  }

  final configMap = Map<String, dynamic>.from(config);
  for (final e in mechanic.validate(configMap)) {
    errors.add('$path.config: $e');
  }

  return PuzzleSpec(
    id: id,
    type: type as String,
    prompt: _text(errors, '$path.prompt', item['prompt'], 300),
    config: configMap,
    feedbackCorrect:
        _text(errors, '$path.feedbackCorrect', item['feedbackCorrect'], 250),
    feedbackWrong:
        _text(errors, '$path.feedbackWrong', item['feedbackWrong'], 250),
    hint: _optText(item['hint'], 200),
    skill: _text(errors, '$path.skill', item['skill'], 80),
  );
}

// ----------------------------------------------------------- validation

/// A model often points at a puzzle's placement id (the spot in the room)
/// instead of the puzzle id. The engine tracks puzzle ids, so rewrite them.
List<StageSpec> _resolveReferences(List<StageSpec> stages) {
  final spotToPuzzle = <String, String>{};
  for (final s in stages) {
    for (final e in s.entities) {
      final pid = e.puzzleId;
      if (e.type == EntityType.puzzle && pid != null && pid != e.id) {
        spotToPuzzle[e.id] = pid;
      }
    }
  }

  String fix(String ref) => spotToPuzzle[ref] ?? ref;

  return stages.map((s) {
    final entities = s.entities.map((e) {
      final requires = <String>[];
      for (final r in e.requires) {
        final target = fix(r);
        final own = e.type == EntityType.puzzle ? e.puzzleId : e.id;
        if (target == own) continue; // self reference
        if (!requires.contains(target)) requires.add(target);
      }
      final rb = e.revealedBy;
      return e.copyWith(
        requires: requires,
        revealedBy: rb == null ? null : fix(rb),
      );
    }).toList();

    final blockers =
        s.blockers.map((b) => b.copyWith(removedBy: fix(b.removedBy))).toList();

    return s.withParts(entities: entities, blockers: blockers);
  }).toList();
}

void _crossCheck(
  List<String> errors,
  List<StageSpec> stages,
  List<PuzzleSpec> puzzles,
  String finalPuzzleId,
) {
  final entityStage = <String, int>{};
  final entities = <EntitySpec>[];

  for (var s = 0; s < stages.length; s++) {
    var doors = 0;
    for (final e in stages[s].entities) {
      if (entityStage.containsKey(e.id)) {
        errors.add('duplicate entity id "${e.id}"');
      }
      entityStage[e.id] = s;
      entities.add(e);
      if (e.type == EntityType.door) doors++;
    }
    if (doors != 1) {
      errors.add('stage "${stages[s].name}" needs exactly one door, '
          'found $doors');
    }
  }

  final puzzleIds = <String>{};
  for (final p in puzzles) {
    if (!puzzleIds.add(p.id)) errors.add('duplicate puzzle id "${p.id}"');
  }

  // Everything that can be "done": evidence, items, targets, puzzles.
  final triggerStage = <String, int>{};
  final placed = <String, int>{};

  for (final e in entities) {
    final s = entityStage[e.id]!;
    switch (e.type) {
      case EntityType.evidence:
      case EntityType.item:
      case EntityType.target:
        triggerStage[e.id] = s;
        break;
      case EntityType.puzzle:
        final pid = e.puzzleId;
        if (pid == null || !puzzleIds.contains(pid)) {
          errors.add('entity "${e.id}" points at unknown puzzle "$pid"');
        } else {
          placed[pid] = (placed[pid] ?? 0) + 1;
          triggerStage[pid] = s;
        }
        break;
      case EntityType.door:
        break;
    }
  }

  for (final p in puzzles) {
    final n = placed[p.id] ?? 0;
    if (n != 1) {
      errors.add('puzzle "${p.id}" must be placed exactly once (found $n)');
    }
  }

  for (final e in entities) {
    final ownPlacement = e.type == EntityType.puzzle && e.puzzleId == e.id;
    if (puzzleIds.contains(e.id) && !ownPlacement) {
      errors.add('entity "${e.id}" has the same id as a puzzle');
    }
  }

  if (!puzzleIds.contains(finalPuzzleId)) {
    errors.add('finalPuzzleId "$finalPuzzleId" does not exist');
  } else if ((triggerStage[finalPuzzleId] ?? -1) != stages.length - 1) {
    errors.add('the final puzzle must be placed in the last stage');
  }

  void checkRef(String owner, int stage, String ref, String what,
      {String? self}) {
    final s = triggerStage[ref];
    if (s == null) {
      errors.add('$owner $what "$ref", which is not a clue, item, puzzle, '
          'or target');
      return;
    }
    if (s > stage) errors.add('$owner $what "$ref" from a later stage');
    if (ref == self) errors.add('$owner $what itself');
  }

  final byId = {for (final e in entities) e.id: e};
  final itemUsedBy = <String, String>{};

  for (final e in entities) {
    final s = entityStage[e.id]!;
    final self = e.type == EntityType.puzzle ? e.puzzleId : e.id;
    final owner = 'entity "${e.id}"';

    for (final r in e.requires) {
      checkRef(owner, s, r, 'requires', self: self);
    }

    if (e.hidden) {
      final rb = e.revealedBy;
      if (rb == null) {
        errors.add('$owner is hidden but has no revealedBy');
      } else {
        checkRef(owner, s, rb, 'is revealed by', self: self);
      }
    }

    if (e.type == EntityType.target) {
      final need = e.needsItem;
      if (need == null || byId[need]?.type != EntityType.item) {
        errors.add('target "${e.id}" must need an item that exists');
      } else {
        if ((entityStage[need] ?? 0) > s) {
          errors.add('target "${e.id}" needs an item from a later stage');
        }
        final other = itemUsedBy[need];
        if (other != null) {
          errors.add('item "$need" is needed by both "$other" and "${e.id}"');
        }
        itemUsedBy[need] = e.id;
      }
    }
  }

  final blockerIds = <String>{};
  for (var s = 0; s < stages.length; s++) {
    for (final b in stages[s].blockers) {
      if (!blockerIds.add(b.id)) errors.add('duplicate blocker id "${b.id}"');
      checkRef('blocker "${b.id}"', s, b.removedBy, 'is removed by');
    }
  }
}