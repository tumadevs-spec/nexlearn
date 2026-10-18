import '../engine/game_state.dart';
import '../engine/mechanic_registry.dart';
import 'adventure_spec.dart';

class AdventureLoader {
  AdventureLoader._();

  /// Parses untrusted data, then plays it like a perfect player to prove it
  /// can be finished. Throws [SpecValidationException] if anything is wrong.
  static AdventureSpec load(Map<String, dynamic> json) {
    final spec = AdventureSpec.parse(json);
    final problem = simulateCompletion(spec);
    if (problem != null) throw SpecValidationException([problem]);
    return spec;
  }
}

/// Returns a description of what goes wrong, or null if a perfect player can
/// finish the adventure and touch everything in it.
String? simulateCompletion(AdventureSpec spec) {
  final state = GameState(spec);
  var steps = 0;

  while (!state.completed) {
    if (++steps > 600) return 'The adventure never finishes.';

    final stage = state.stage;
    var progressed = false;

    for (final e in stage.entities) {
      if (e.type == EntityType.door) continue;
      if (!state.isVisible(e) ||
          state.entityDone(e) ||
          !state.requirementsMet(e)) {
        continue;
      }

      switch (e.type) {
        case EntityType.evidence:
        case EntityType.item:
          state.interact(e.id);
          progressed = true;
          break;
        case EntityType.puzzle:
          final puzzle = spec.puzzleById(e.puzzleId ?? '');
          final mechanic =
              puzzle == null ? null : MechanicRegistry.lookup(puzzle.type);
          if (puzzle == null || mechanic == null) {
            return 'Puzzle for "${e.name}" is missing.';
          }
          final result = state.submit(puzzle.id, mechanic.solve(puzzle.config));
          if (!result.correct) {
            return 'Puzzle "${puzzle.id}" cannot be solved with its own answer.';
          }
          progressed = true;
          break;
        case EntityType.target:
          final need = e.needsItem;
          if (need != null && state.inventory.contains(need)) {
            if (!state.useItem(e.id, need).correct) {
              return 'Item "$need" does not work on "${e.name}".';
            }
            progressed = true;
          }
          break;
        case EntityType.door:
          break;
      }
    }

    if (progressed) continue;

    final undone = stage.entities
        .where((e) => e.type != EntityType.door && !state.entityDone(e))
        .toList();
    if (undone.isNotEmpty) {
      return 'In stage "${stage.name}", "${undone.first.name}" can never be '
          'reached or finished.';
    }

    final door = stage.entities.firstWhere((e) => e.type == EntityType.door);
    if (!state.requirementsMet(door)) {
      return 'The door of stage "${stage.name}" never unlocks.';
    }
    state.interact(door.id);
  }

  return null;
}