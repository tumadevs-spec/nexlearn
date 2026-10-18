import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/debug/sample_spec.dart';
import '../game/engine/game_state.dart';
import '../game/spec/adventure_loader.dart';
import '../game/spec/adventure_spec.dart';
import '../game/ui/inventory_bar.dart';
import '../game/ui/item_sheet.dart';
import '../game/ui/puzzle_sheet.dart';
import '../game/ui/virtual_joystick.dart';
import '../game/world/mystery_world.dart';
import '../services/adventure_service.dart';
import '../services/progress_service.dart';

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
  static const violet = Color(0xFF7C3AED);
  static const deepViolet = Color(0xFF3B0764);

  MysteryWorld? _world;
  GameState? _state;

  bool _isLoading = true;
  String? _loadError;
  String _message = 'Explore your world and find the clues.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAdventure();
  }

  @override
  void dispose() {
    _world?.nearby.dispose();
    _state?.dispose();
    super.dispose();
  }

  void _say(String text) {
    if (mounted && text.isNotEmpty) setState(() => _message = text);
  }

  // ------------------------------------------------------------- loading

  Future<void> _loadAdventure() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
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

      final adventure = await AdventureService().generateAdventure(
        subject: widget.subject,
        topicName: widget.topicName,
        classNumber: widget.classNumber,
        age: age,
        learningObjectives: objectives,
      );

      if (!mounted) return;
      _start(adventure);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Validates untrusted data, proves it can be finished, then builds the
  /// game. Throws on invalid data.
  void _start(Map<String, dynamic> json) {
    final AdventureSpec spec = AdventureLoader.load(json);

    _world?.nearby.dispose();
    _state?.dispose();

    final state = GameState(spec);
    final world = MysteryWorld(state: state);

    setState(() {
      _state = state;
      _world = world;
      _isLoading = false;
      _loadError = null;
      _message = spec.stages.first.intro;
    });
  }

  void _startDebugSample() {
    try {
      _start(debugSampleSpec());
    } catch (error) {
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _restart() {
    final state = _state;
    final world = _world;
    if (state == null || world == null) {
      _loadAdventure();
      return;
    }
    state.reset();
    world.resetWorld();
    _say(state.spec.stages.first.intro);
  }

  // ---------------------------------------------------------- interaction

  Future<void> _interact() async {
    final world = _world;
    final state = _state;
    if (world == null || state == null || _busy || state.completed) return;

    final target = world.nearby.value;
    if (target == null) {
      _say('Walk closer to something glowing, then press the button.');
      return;
    }

    final result = state.interact(target.id);

    switch (result.kind) {
      case InteractKind.collected:
        HapticFeedback.selectionClick();
        world.burstEntity(target);
        _say('Clue found! ${result.message}');
        break;
      case InteractKind.pickedUp:
        HapticFeedback.selectionClick();
        world.burstEntity(target, color: const Color(0xFF14B8A6));
        _say('You picked up: ${target.name}. ${result.message}');
        break;
      case InteractKind.alreadyDone:
        _say(result.message);
        break;
      case InteractKind.locked:
        world.shake();
        HapticFeedback.mediumImpact();
        _say(result.message);
        break;
      case InteractKind.openPuzzle:
        await _openPuzzle(target, result.puzzle!);
        break;
      case InteractKind.needsItem:
        await _openItemSheet(target);
        break;
      case InteractKind.nextStage:
        world.celebrate();
        HapticFeedback.heavyImpact();
        _say(state.stage.intro);
        break;
      case InteractKind.completed:
        world.celebrate();
        HapticFeedback.heavyImpact();
        _say(result.message);
        ProgressService.markCompleted(
          subject: widget.subject,
          classNumber: widget.classNumber,
          topicName: widget.topicName,
        );
        break;
      case InteractKind.notFound:
        break;
    }

    if (mounted) setState(() {});
  }

  Future<void> _openPuzzle(EntitySpec host, PuzzleSpec puzzle) async {
    final world = _world!;
    final state = _state!;

    _busy = true;
    world.inputEnabled = false;
    world.joystick = Offset.zero;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F3FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PuzzleSheet(
        puzzle: puzzle,
        onSubmit: (answer) => state.submit(puzzle.id, answer),
      ),
    );

    _busy = false;
    world.inputEnabled = true;

    if (!mounted) return;

    if (state.solved.contains(puzzle.id)) {
      world.burstEntity(host, color: const Color(0xFF22C55E));
      _say(puzzle.feedbackCorrect);
    } else {
      _say('Puzzle closed. Come back when you are ready.');
    }
  }

  Future<void> _openItemSheet(EntitySpec target) async {
    final world = _world!;
    final state = _state!;

    final items = state.spec.allEntities
        .where((e) => e.type == EntityType.item && state.inventory.contains(e.id))
        .toList();

    if (items.isEmpty) {
      _say('You have nothing to use here yet. ${target.text}');
      return;
    }

    _busy = true;
    world.inputEnabled = false;
    world.joystick = Offset.zero;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F3FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ItemSheet(
        title: target.name,
        text: target.text,
        items: items,
        onUse: (itemId) => state.useItem(target.id, itemId),
      ),
    );

    _busy = false;
    world.inputEnabled = true;

    if (!mounted) return;

    if (state.done.contains(target.id)) {
      world.burstEntity(target, color: const Color(0xFF22C55E));
      _say(target.successText.isEmpty ? 'It works!' : target.successText);
    }
  }

  // ----------------------------------------------------------------- UI

  Widget _progressRow() {
    final state = _state;
    if (state == null) {
      return const Text(
        'Preparing your adventure...',
        style: TextStyle(color: deepViolet, fontWeight: FontWeight.w700),
      );
    }

    return ListenableBuilder(
      listenable: state,
      builder: (_, __) => Text(
        '⭐ ${state.score}',
        style: const TextStyle(
          color: deepViolet,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_isLoading && _loadError == null && _world != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                          _state?.spec.title ?? widget.topicName,
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: _progressRow(),
              ),
            ),
            const SizedBox(height: 6),
            if (_state != null) InventoryBar(state: _state!),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_world != null)
                        GameWidget<MysteryWorld>(game: _world!)
                      else
                        Container(color: const Color(0xFFEDE9FE)),
                      if (_isLoading) _loadingOverlay(),
                      if (_loadError != null) _errorOverlay(),
                      if (ready) _completionLayer(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: deepViolet,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  VirtualJoystick(
                    onChanged: (v) => _world?.joystick = v,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ready
                        ? ValueListenableBuilder<EntitySpec?>(
                            valueListenable: _world!.nearby,
                            builder: (_, near, __) => _interactButton(near),
                          )
                        : _interactButton(null, enabled: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _interactButton(EntitySpec? near, {bool enabled = true}) {
    final active = enabled && near != null;

    String label = 'INTERACT';
    if (active) {
      switch (near.type) {
        case EntityType.item:
          label = 'Take ${near.name}';
          break;
        case EntityType.target:
          label = 'Use item: ${near.name}';
          break;
        default:
          label = near.name;
      }
    }

    return SizedBox(
      height: 72,
      child: ElevatedButton(
        onPressed: enabled ? _interact : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? violet : Colors.white,
          foregroundColor: active ? Colors.white : deepViolet,
          disabledBackgroundColor: const Color(0xFFD8CCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_rounded),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: const Color(0xFFF5F3FF),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: violet),
            SizedBox(height: 18),
            Text(
              'Creating your adventure...',
              style: TextStyle(color: deepViolet, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorOverlay() {
    return Container(
      color: const Color(0xFFF5F3FF),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46, color: violet),
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
                style: const TextStyle(color: Color(0xFF665477)),
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
              if (kDebugMode) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _startDebugSample,
                  child: const Text('DEBUG: load engine test sample'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _completionLayer() {
    final state = _state!;
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        if (!state.completed) return const SizedBox.shrink();
        return _completionOverlay(state);
      },
    );
  }

  Widget _completionOverlay(GameState state) {
    final skills = state.assessment();

    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8CCF7), width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 4),
              const Text(
                '⭐',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mission complete!',
                style: TextStyle(
                  color: deepViolet,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.spec.learningSummary,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF665477)),
              ),
              const SizedBox(height: 10),
              Text(
                '${state.score} points  •  ${state.mistakes} mistakes',
                style: const TextStyle(
                  color: deepViolet,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final entry in skills.entries)
                  Text(
                    '${entry.key}: ${entry.value.correct} right, '
                    '${entry.value.wrong} to practise',
                    style: const TextStyle(
                      color: Color(0xFF665477),
                      fontSize: 13,
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _restart,
                    child: const Text('Play again'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violet,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}