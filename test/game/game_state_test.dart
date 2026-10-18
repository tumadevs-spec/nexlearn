import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nexlearn/game/debug/sample_spec.dart';
import 'package:nexlearn/game/engine/game_state.dart';
import 'package:nexlearn/game/spec/adventure_loader.dart';
import 'package:nexlearn/game/spec/adventure_spec.dart';

Map<String, dynamic> sample() =>
    jsonDecode(jsonEncode(debugSampleSpec())) as Map<String, dynamic>;

Map<String, dynamic> entity(Map<String, dynamic> json, String id) {
  for (final stage in json['stages'] as List) {
    for (final e in (stage as Map)['entities'] as List) {
      if ((e as Map)['id'] == id) return e as Map<String, dynamic>;
    }
  }
  throw StateError('no entity $id');
}

/// An old-format (v2) single-room adventure.
Map<String, dynamic> v2() => {
      'specVersion': 2,
      'title': 'Old format',
      'story': 'A test story.',
      'learningSummary': 'A test summary.',
      'finalPuzzleId': 'why',
      'environment': {
        'name': 'Room',
        'floorColor': '#EDE9FE',
        'wallColor': '#B9A3EC',
        'accentColor': '#7C3AED',
      },
      'spawn': {'x': 0.5, 'y': 0.85},
      'obstacles': <dynamic>[],
      'entities': [
        {'id': 'e1', 'type': 'evidence', 'name': 'Note', 'x': 0.2, 'y': 0.3,
         'text': 'The chest has 3 rows of 4 coins.'},
        {'id': 'e2', 'type': 'evidence', 'name': 'Tray', 'x': 0.7, 'y': 0.3,
         'text': 'The tray is empty.'},
        {'id': 'p1', 'type': 'puzzle', 'name': 'Lock', 'x': 0.5, 'y': 0.5,
         'text': 'A number lock.', 'puzzleId': 'lock',
         'requires': ['e1', 'e2']},
        {'id': 'p2', 'type': 'puzzle', 'name': 'Board', 'x': 0.5, 'y': 0.7,
         'text': 'Who did it?', 'puzzleId': 'why', 'requires': ['p1']},
        {'id': 'exit', 'type': 'door', 'name': 'Gate', 'x': 0.5, 'y': 0.2,
         'text': 'The gate opens!', 'requires': ['why']},
      ],
      'puzzles': [
        {'id': 'lock', 'type': 'codeLock', 'prompt': 'Enter the total.',
         'config': {'answer': '12'}, 'feedbackCorrect': 'Click! Open.',
         'feedbackWrong': 'Count the rows again.', 'hint': '3 x 4',
         'skill': 'multiplication'},
        {'id': 'why', 'type': 'choice', 'prompt': 'What happened?',
         'config': {'options': ['A', 'B'], 'correctIndex': 1},
         'feedbackCorrect': 'Yes!', 'feedbackWrong': 'Look at the tray.',
         'skill': 'reasoning'},
      ],
    };

/// Plays stage 1 of the sample like a perfect player.
GameState stageTwo() {
  final state = GameState(AdventureLoader.load(sample()));
  state.interact('ev_tray');
  state.interact('ev_manual');
  state.submit('lock', '12');
  state.interact('battery');
  state.submit(
      'order', ['Plug in', 'Switch on', 'Wait for the light', 'Press start']);
  state.useItem('robot_slot', 'battery');
  state.interact('door_1');
  return state;
}

void main() {
  test('sample adventure parses and a perfect player can finish it', () {
    final spec = AdventureLoader.load(sample());
    expect(spec.stages.length, 2);
    expect(spec.puzzles.length, 6);
  });

  test('a v2 adventure is upgraded into one stage and is solvable', () {
    final spec = AdventureLoader.load(v2());
    expect(spec.stages.length, 1);
    // p2 required the spot id "p1"; it is rewritten to the puzzle id.
    expect(spec.entityById('p2')!.requires, ['lock']);
  });

  test('unsupported mechanic is rejected', () {
    final json = sample();
    (json['puzzles'] as List)[0]['type'] = 'jumping';
    expect(() => AdventureLoader.load(json),
        throwsA(isA<SpecValidationException>()));
  });

  test('a hidden entity without revealedBy is rejected', () {
    final json = sample();
    entity(json, 'battery').remove('revealedBy');
    expect(() => AdventureLoader.load(json),
        throwsA(isA<SpecValidationException>()));
  });

  test('a requirement from a later stage is rejected', () {
    final json = sample();
    entity(json, 'ev_tray')['requires'] = ['exp'];
    expect(() => AdventureLoader.load(json),
        throwsA(isA<SpecValidationException>()));
  });

  test('a deadlock is caught by the perfect-player simulation', () {
    final json = sample();
    // ev_tray needs the battery, but the battery appears only after the lock,
    // which needs ev_tray.
    entity(json, 'ev_tray')['requires'] = ['battery'];
    expect(() => AdventureLoader.load(json),
        throwsA(isA<SpecValidationException>()));
  });

  test('a target must name an item that exists', () {
    final json = sample();
    entity(json, 'robot_slot')['needsItem'] = 'nothing_here';
    expect(() => AdventureLoader.load(json),
        throwsA(isA<SpecValidationException>()));
  });

  test('a hidden item appears only after its puzzle is solved', () {
    final state = GameState(AdventureLoader.load(sample()));
    final battery = state.spec.entityById('battery')!;
    expect(state.isVisible(battery), isFalse);
    expect(state.interact('battery').kind, InteractKind.notFound);

    state.interact('ev_tray');
    state.submit('lock', '12');
    expect(state.isVisible(battery), isTrue);
    expect(state.interact('battery').kind, InteractKind.pickedUp);
    expect(state.inventory.contains('battery'), isTrue);
  });

  test('a blocker disappears when its trigger fires', () {
    final state = GameState(AdventureLoader.load(sample()));
    expect(state.activeBlockers.length, 1);

    state.interact('ev_manual');
    state.submit(
        'order', ['Plug in', 'Switch on', 'Wait for the light', 'Press start']);
    expect(state.activeBlockers, isEmpty);
  });

  test('the wrong item is a mistake and the right item is used up', () {
    final state = GameState(AdventureLoader.load(sample()));
    state.interact('ev_tray');
    state.submit('lock', '12');
    state.interact('battery');

    // Pretend we hold something else.
    state.inventory.add('not_the_battery');
    final wrong = state.useItem('robot_slot', 'not_the_battery');
    expect(wrong.correct, isFalse);
    expect(state.mistakes, 1);

    final right = state.useItem('robot_slot', 'battery');
    expect(right.correct, isTrue);
    expect(state.inventory.contains('battery'), isFalse);
    expect(state.done.contains('robot_slot'), isTrue);
  });

  test('a wrong choice shows its consequence', () {
    final state = stageTwo();
    final result = state.submit('why', 1);
    expect(result.correct, isFalse);
    expect(result.message, contains('nothing inside is broken'));
    expect(state.mistakes, 1);
  });

  test('experiment attempts are not mistakes', () {
    final state = stageTwo();
    final wrong = state.submit('exp', 0);
    expect(wrong.correct, isFalse);
    expect(wrong.message, contains('Only a little charge'));
    expect(state.mistakes, 0);

    expect(state.submit('exp', 1).correct, isTrue);
  });

  test('sort checks every item', () {
    final state = stageTwo();

    expect(
      state.submit('sorting', {
        'Copper wire': 'Does not carry electricity',
        'Iron nail': 'Carries electricity',
        'Rubber glove': 'Does not carry electricity',
        'Plastic spoon': 'Does not carry electricity',
      }).correct,
      isFalse,
    );

    expect(
      state.submit('sorting', {
        'Copper wire': 'Carries electricity',
        'Iron nail': 'Carries electricity',
        'Rubber glove': 'Does not carry electricity',
        'Plastic spoon': 'Does not carry electricity',
      }).correct,
      isTrue,
    );
  });

  test('door stays locked until its requirement is met', () {
    final state = GameState(AdventureLoader.load(sample()));
    expect(state.interact('door_1').kind, InteractKind.locked);
    expect(state.stageIndex, 0);
  });

  test('full playthrough across two stages completes with stars', () {
    final state = stageTwo();
    expect(state.stageIndex, 1);

    state.interact('ev_lab');
    state.interact('ev_mat');
    state.submit('exp', 1);
    state.submit('sorting', {
      'Copper wire': 'Carries electricity',
      'Iron nail': 'Carries electricity',
      'Rubber glove': 'Does not carry electricity',
      'Plastic spoon': 'Does not carry electricity',
    });
    state.submit('match', {
      'Battery': 'Stores energy',
      'Wire': 'Carries electricity',
      'Switch': 'Turns it on or off',
    });
    state.submit('why', 0);

    expect(state.interact('door_2').kind, InteractKind.completed);
    expect(state.completed, isTrue);
    expect(state.stars, 3);
    expect(state.assessment()['reasoning']!.correct, 1);
  });
}