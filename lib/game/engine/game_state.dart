import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import '../spec/adventure_spec.dart';
import 'mechanic_registry.dart';

enum InteractKind {
  collected,
  pickedUp,
  alreadyDone,
  locked,
  openPuzzle,
  needsItem,
  nextStage,
  completed,
  notFound,
}

class InteractResult {
  const InteractResult(this.kind, this.message, {this.entity, this.puzzle});

  final InteractKind kind;
  final String message;
  final EntitySpec? entity;
  final PuzzleSpec? puzzle;
}

class PuzzleResult {
  const PuzzleResult({
    required this.correct,
    required this.message,
    required this.points,
  });

  final bool correct;
  final String message;
  final int points;
}

class UseResult {
  const UseResult({required this.correct, required this.message});

  final bool correct;
  final String message;
}

/// All game rules live here. No rendering, no Flame, no widgets.
class GameState extends ChangeNotifier {
  GameState(this.spec);

  final AdventureSpec spec;

  int stageIndex = 0;

  final Set<String> evidence = {};

  /// Items the player holds right now.
  final Set<String> inventory = {};

  /// Everything finished: evidence, collected items, solved puzzles, used
  /// targets. Requirements, reveals, and blockers all look at this set.
  final Set<String> done = {};
  final Set<String> solved = {};
  final Map<String, int> attempts = {};
  final Map<String, int> _skillCorrect = {};
  final Map<String, int> _skillWrong = {};

  int score = 0;
  int mistakes = 0;
  bool completed = false;

  StageSpec get stage => spec.stages[stageIndex];
  bool get isLastStage => stageIndex == spec.stages.length - 1;

  int get evidenceTotal =>
      spec.allEntities.where((e) => e.type == EntityType.evidence).length;

  int get stars => mistakes == 0 ? 3 : (mistakes <= 3 ? 2 : 1);

  bool requirementsMet(EntitySpec e) => e.requires.every(done.contains);

  bool isVisible(EntitySpec e) {
    if (!e.hidden) return true;
    final by = e.revealedBy;
    return by != null && done.contains(by);
  }

  bool entityDone(EntitySpec e) {
    switch (e.type) {
      case EntityType.evidence:
      case EntityType.item:
      case EntityType.target:
        return done.contains(e.id);
      case EntityType.puzzle:
        return solved.contains(e.puzzleId);
      case EntityType.door:
        return completed;
    }
  }

  List<BlockerSpec> get activeBlockers =>
      stage.blockers.where((b) => !done.contains(b.removedBy)).toList();

  List<Rect> get activeBlockerRects =>
      activeBlockers.map((b) => b.rect).toList();

  EntitySpec? _inStage(String id) {
    for (final e in stage.entities) {
      if (e.id == id) return e;
    }
    return null;
  }

  InteractResult interact(String entityId) {
    if (completed) return const InteractResult(InteractKind.notFound, '');

    final entity = _inStage(entityId);
    if (entity == null || !isVisible(entity)) {
      return const InteractResult(InteractKind.notFound, '');
    }

    if (!requirementsMet(entity)) {
      return InteractResult(InteractKind.locked, entity.lockedText,
          entity: entity);
    }

    switch (entity.type) {
      case EntityType.evidence:
        if (done.contains(entity.id)) {
          return InteractResult(InteractKind.alreadyDone, entity.text,
              entity: entity);
        }
        evidence.add(entity.id);
        done.add(entity.id);
        score += 2;
        notifyListeners();
        return InteractResult(InteractKind.collected, entity.text,
            entity: entity);

      case EntityType.item:
        if (done.contains(entity.id)) {
          return InteractResult(InteractKind.alreadyDone, entity.text,
              entity: entity);
        }
        inventory.add(entity.id);
        done.add(entity.id);
        score += 2;
        notifyListeners();
        return InteractResult(InteractKind.pickedUp, entity.text,
            entity: entity);

      case EntityType.puzzle:
        final id = entity.puzzleId;
        final puzzle = id == null ? null : spec.puzzleById(id);
        if (puzzle == null) {
          return const InteractResult(InteractKind.notFound, '');
        }
        if (solved.contains(puzzle.id)) {
          return InteractResult(InteractKind.alreadyDone, puzzle.feedbackCorrect,
              entity: entity);
        }
        return InteractResult(InteractKind.openPuzzle, puzzle.prompt,
            entity: entity, puzzle: puzzle);

      case EntityType.target:
        if (done.contains(entity.id)) {
          return InteractResult(
              InteractKind.alreadyDone,
              entity.successText.isEmpty ? entity.text : entity.successText,
              entity: entity);
        }
        return InteractResult(InteractKind.needsItem, entity.text,
            entity: entity);

      case EntityType.door:
        if (isLastStage) {
          completed = true;
          score += 20;
          notifyListeners();
          return InteractResult(InteractKind.completed, entity.text,
              entity: entity);
        }
        stageIndex++;
        score += 10;
        notifyListeners();
        return InteractResult(InteractKind.nextStage, entity.text,
            entity: entity);
    }
  }

  /// Uses an inventory item on a target. The wrong item is a mistake.
  UseResult useItem(String targetId, String itemId) {
    final target = _inStage(targetId);
    if (target == null ||
        target.type != EntityType.target ||
        done.contains(target.id)) {
      return const UseResult(correct: false, message: 'Nothing happens.');
    }
    if (!inventory.contains(itemId)) {
      return const UseResult(
          correct: false, message: 'You do not have that item.');
    }

    if (itemId == target.needsItem) {
      inventory.remove(itemId);
      done.add(target.id);
      score += 8;
      notifyListeners();
      return UseResult(
        correct: true,
        message: target.successText.isEmpty ? 'It works!' : target.successText,
      );
    }

    mistakes++;
    notifyListeners();
    return UseResult(
      correct: false,
      message: target.wrongItemText.isEmpty
          ? 'That does not seem to work here.'
          : target.wrongItemText,
    );
  }

  PuzzleResult submit(String puzzleId, Object? answer) {
    final puzzle = spec.puzzleById(puzzleId);
    final mechanic =
        puzzle == null ? null : MechanicRegistry.lookup(puzzle.type);

    if (puzzle == null || mechanic == null) {
      return const PuzzleResult(
          correct: false, message: 'This puzzle is unavailable.', points: 0);
    }

    if (solved.contains(puzzleId)) {
      return PuzzleResult(
          correct: true, message: puzzle.feedbackCorrect, points: 0);
    }

    final tries = (attempts[puzzleId] ?? 0) + 1;
    attempts[puzzleId] = tries;

    final correct = mechanic.evaluate(puzzle.config, answer);
    final detail = mechanic.detail?.call(puzzle.config, answer, correct);

    if (correct) {
      solved.add(puzzleId);
      done.add(puzzleId);
      final points = tries == 1 ? 10 : 5;
      score += points;
      _skillCorrect[puzzle.skill] = (_skillCorrect[puzzle.skill] ?? 0) + 1;
      notifyListeners();
      return PuzzleResult(
        correct: true,
        message: detail == null
            ? puzzle.feedbackCorrect
            : '$detail ${puzzle.feedbackCorrect}',
        points: points,
      );
    }

    if (mechanic.countsMistakes) {
      mistakes++;
      _skillWrong[puzzle.skill] = (_skillWrong[puzzle.skill] ?? 0) + 1;
    }
    notifyListeners();
    return PuzzleResult(
      correct: false,
      message: detail == null
          ? puzzle.feedbackWrong
          : '$detail ${puzzle.feedbackWrong}',
      points: 0,
    );
  }

  /// Per-skill results for later analytics.
  Map<String, ({int correct, int wrong})> assessment() {
    final skills = {..._skillCorrect.keys, ..._skillWrong.keys};
    return {
      for (final s in skills)
        s: (correct: _skillCorrect[s] ?? 0, wrong: _skillWrong[s] ?? 0),
    };
  }

  void reset() {
    stageIndex = 0;
    evidence.clear();
    inventory.clear();
    done.clear();
    solved.clear();
    attempts.clear();
    _skillCorrect.clear();
    _skillWrong.clear();
    score = 0;
    mistakes = 0;
    completed = false;
    notifyListeners();
  }
}