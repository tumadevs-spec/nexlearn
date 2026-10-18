import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/game_state.dart';
import '../spec/adventure_spec.dart';

class PuzzleSheet extends StatefulWidget {
  const PuzzleSheet({
    super.key,
    required this.puzzle,
    required this.onSubmit,
  });

  final PuzzleSpec puzzle;
  final PuzzleResult Function(Object? answer) onSubmit;

  @override
  State<PuzzleSheet> createState() => _PuzzleSheetState();
}

class _PuzzleSheetState extends State<PuzzleSheet> {
  static const violet = Color(0xFF7C3AED);
  static const deepViolet = Color(0xFF3B0764);
  static const _palette = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF10B981),
  ];

  String? _feedback;
  bool _correct = false;
  int _wrong = 0;
  bool _showHint = false;

  // codeLock
  String _code = '';

  // sequence
  List<String> _pool = [];
  final List<String> _picked = [];
  int _sequenceLength = 0;

  // matching
  List<String> _lefts = [];
  List<String> _rights = [];
  final Map<String, String> _pairs = {};
  String? _selectedLeft;

  // choice
  final Set<int> _tried = {};

  // sort
  List<String> _sortItems = [];
  List<String> _bins = [];
  final Map<String, String> _assigned = {};
  String? _selectedItem;

  // experiment
  int? _chosenTrial;

  PuzzleSpec get _p => widget.puzzle;
  bool get _isExperiment => _p.type == 'experiment';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final random = math.Random();

    if (_p.type == 'sequence') {
      final items = (_p.config['items'] as List)
          .map((e) => e.toString().trim())
          .toList();
      _sequenceLength = items.length;
      _pool = List<String>.of(items);
      for (var i = 0; i < 6; i++) {
        _pool.shuffle(random);
        var same = true;
        for (var j = 0; j < items.length; j++) {
          if (_pool[j] != items[j]) same = false;
        }
        if (!same) break;
      }
    }

    if (_p.type == 'matching') {
      final pairs = _p.config['pairs'] as List;
      _lefts = pairs.map((e) => (e as Map)['left'].toString().trim()).toList();
      _rights =
          pairs.map((e) => (e as Map)['right'].toString().trim()).toList()
            ..shuffle(random);
    }

    if (_p.type == 'sort') {
      _bins = (_p.config['bins'] as List).map((e) => e.toString().trim()).toList();
      _sortItems = (_p.config['items'] as List)
          .map((e) => (e as Map)['text'].toString().trim())
          .toList()
        ..shuffle(random);
    }
  }

  void _submit(Object? answer) {
    final result = widget.onSubmit(answer);

    setState(() {
      _feedback = result.message;
      _correct = result.correct;
      if (!result.correct) {
        _wrong++;
        _code = '';
        _pool = [..._pool, ..._picked];
        _picked.clear();
        _pairs.clear();
        _selectedLeft = null;
        _assigned.clear();
        _selectedItem = null;
        if (_p.hint.isNotEmpty) _showHint = true;
      }
    });

    if (result.correct) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  // ------------------------------------------------------------- widgets

  Widget _chip(
    String text, {
    required VoidCallback? onTap,
    Color? color,
    bool wide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? double.infinity : null,
        alignment: wide ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color ?? violet, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color == null ? deepViolet : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _checkButton(String label, bool enabled, VoidCallback onPressed,
      {IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon ?? Icons.check_rounded),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }

  Widget _codeBody() {
    final length = (_p.config['answer'] as String).length;

    Widget key(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 72,
            height: 46,
            child: ElevatedButton(
              onPressed: _correct ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: deepViolet,
                padding: EdgeInsets.zero,
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++)
              Container(
                width: 46,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: violet, width: 2),
                ),
                child: Text(
                  i < _code.length ? _code[i] : '',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: deepViolet),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['⌫', '0', 'OK'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final label in row)
                key(label, () {
                  if (label == '⌫') {
                    if (_code.isNotEmpty) {
                      setState(
                          () => _code = _code.substring(0, _code.length - 1));
                    }
                  } else if (label == 'OK') {
                    if (_code.length == length) _submit(_code);
                  } else if (_code.length < length) {
                    setState(() => _code += label);
                  }
                }),
            ],
          ),
      ],
    );
  }

  Widget _sequenceBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_picked.isEmpty)
                const Text('Tap the pieces in the right order',
                    style: TextStyle(color: Color(0xFF7C6A99))),
              for (var i = 0; i < _picked.length; i++)
                _chip(
                  '${i + 1}. ${_picked[i]}',
                  color: violet,
                  onTap: _correct
                      ? null
                      : () => setState(() => _pool.add(_picked.removeAt(i))),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _pool)
              _chip(
                item,
                onTap: _correct
                    ? null
                    : () => setState(() {
                          _pool.remove(item);
                          _picked.add(item);
                        }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _checkButton('CHECK', !_correct && _picked.length == _sequenceLength,
            () => _submit(List<String>.of(_picked))),
      ],
    );
  }

  Color? _pairColor(String? left, String? right) {
    final lefts = _pairs.keys.toList();
    if (left != null) {
      final i = lefts.indexOf(left);
      return i < 0 ? null : _palette[i % _palette.length];
    }
    if (right != null) {
      for (var i = 0; i < lefts.length; i++) {
        if (_pairs[lefts[i]] == right) return _palette[i % _palette.length];
      }
    }
    return null;
  }

  Widget _matchingBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final left in _lefts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _chip(
                        left,
                        wide: true,
                        color: _pairColor(left, null) ??
                            (_selectedLeft == left ? deepViolet : null),
                        onTap: _correct
                            ? null
                            : () => setState(() {
                                  if (_pairs.containsKey(left)) {
                                    _pairs.remove(left);
                                  } else {
                                    _selectedLeft = left;
                                  }
                                }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (final right in _rights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _chip(
                        right,
                        wide: true,
                        color: _pairColor(null, right),
                        onTap: _correct
                            ? null
                            : () => setState(() {
                                  final used = _pairs.entries
                                      .where((e) => e.value == right)
                                      .map((e) => e.key)
                                      .toList();
                                  if (used.isNotEmpty) {
                                    _pairs.remove(used.first);
                                  } else if (_selectedLeft != null) {
                                    _pairs[_selectedLeft!] = right;
                                    _selectedLeft = null;
                                  }
                                }),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _checkButton('CHECK', !_correct && _pairs.length == _lefts.length,
            () => _submit(Map<String, String>.of(_pairs))),
      ],
    );
  }

  Widget _choiceBody() {
    final options =
        (_p.config['options'] as List).map((e) => e.toString().trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: _correct || _tried.contains(i)
                  ? null
                  : () {
                      _tried.add(i);
                      _submit(i);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: deepViolet,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(options[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  Widget _sortBody() {
    final unassigned =
        _sortItems.where((t) => !_assigned.containsKey(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (unassigned.isEmpty)
              const Text('All sorted! Check your answer.',
                  style: TextStyle(color: Color(0xFF7C6A99))),
            for (final t in unassigned)
              _chip(
                t,
                color: _selectedItem == t ? deepViolet : null,
                onTap: _correct ? null : () => setState(() => _selectedItem = t),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _bins.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _correct || _selectedItem == null
                  ? null
                  : () => setState(() {
                        _assigned[_selectedItem!] = _bins[i];
                        _selectedItem = null;
                      }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _palette[i].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _palette[i], width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bins[i],
                        style: const TextStyle(
                            color: deepViolet, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in _assigned.entries
                            .where((e) => e.value == _bins[i]))
                          _chip(
                            e.key,
                            color: _palette[i],
                            onTap: _correct
                                ? null
                                : () => setState(() => _assigned.remove(e.key)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        _checkButton('CHECK', !_correct && _assigned.length == _sortItems.length,
            () => _submit(Map<String, String>.of(_assigned))),
      ],
    );
  }

  Widget _experimentBody() {
    final trials = (_p.config['trials'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('🎯 Goal: ${_p.config['goal']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: deepViolet, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Change: ${_p.config['variable']}',
                  style: const TextStyle(color: Color(0xFF665477))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < trials.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _chip(
              trials[i]['setting'].toString(),
              wide: true,
              color: _chosenTrial == i ? violet : null,
              onTap: _correct ? null : () => setState(() => _chosenTrial = i),
            ),
          ),
        _checkButton(
          'RUN EXPERIMENT',
          !_correct && _chosenTrial != null,
          () => _submit(_chosenTrial),
          icon: Icons.science_rounded,
        ),
      ],
    );
  }

  Widget _body() {
    switch (_p.type) {
      case 'codeLock':
        return _codeBody();
      case 'sequence':
        return _sequenceBody();
      case 'matching':
        return _matchingBody();
      case 'choice':
        return _choiceBody();
      case 'sort':
        return _sortBody();
      case 'experiment':
        return _experimentBody();
      default:
        return const Text('This puzzle type is not supported.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final warn = !_correct && _isExperiment;

    final Color feedbackBg = _correct
        ? const Color(0xFFDCFCE7)
        : (warn ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
    final Color feedbackFg = _correct
        ? const Color(0xFF166534)
        : (warn ? const Color(0xFF92400E) : const Color(0xFF991B1B));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CCF7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _p.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: deepViolet,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _body(),
              if (_feedback != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: feedbackBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${warn ? '🔬 ' : ''}$_feedback',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: feedbackFg,
                    ),
                  ),
                ),
              ],
              if (_showHint && !_correct) ...[
                const SizedBox(height: 8),
                Text(
                  '💡 ${_p.hint}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF665477)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}