typedef ConfigValidator = List<String> Function(Map<String, dynamic> config);
typedef AnswerEvaluator = bool Function(
    Map<String, dynamic> config, Object? answer);
typedef AnswerSolver = Object? Function(Map<String, dynamic> config);
typedef DetailBuilder = String? Function(
    Map<String, dynamic> config, Object? answer, bool correct);

class PuzzleMechanic {
  const PuzzleMechanic({
    required this.validate,
    required this.evaluate,
    required this.solve,
    this.detail,
    this.countsMistakes = true,
  });

  final ConfigValidator validate;
  final AnswerEvaluator evaluate;

  /// Returns a correct answer. Used by the perfect-player simulation.
  final AnswerSolver solve;

  /// Optional story text for an answer (a consequence, an experiment result).
  final DetailBuilder? detail;

  /// Experiments let the child try things, so wrong runs are not mistakes.
  final bool countsMistakes;
}

/// Only mechanics listed here can ever run. Unknown types are rejected.
class MechanicRegistry {
  MechanicRegistry._();

  static final Map<String, PuzzleMechanic> _mechanics = {
    'codeLock': PuzzleMechanic(
      validate: _validateCodeLock,
      evaluate: _evalCodeLock,
      solve: _solveCodeLock,
    ),
    'sequence': PuzzleMechanic(
      validate: _validateSequence,
      evaluate: _evalSequence,
      solve: _solveSequence,
    ),
    'matching': PuzzleMechanic(
      validate: _validateMatching,
      evaluate: _evalMatching,
      solve: _solveMatching,
    ),
    'choice': PuzzleMechanic(
      validate: _validateChoice,
      evaluate: _evalChoice,
      solve: _solveChoice,
      detail: _detailChoice,
    ),
    'sort': PuzzleMechanic(
      validate: _validateSort,
      evaluate: _evalSort,
      solve: _solveSort,
    ),
    'experiment': PuzzleMechanic(
      validate: _validateExperiment,
      evaluate: _evalExperiment,
      solve: _solveExperiment,
      detail: _detailExperiment,
      countsMistakes: false,
    ),
  };

  static Set<String> get supportedTypes => _mechanics.keys.toSet();

  static PuzzleMechanic? lookup(String type) => _mechanics[type];
}

// ---------------------------------------------------------------- helpers

List<String> _strings(dynamic value) => value is List
    ? value.map((s) => s is String ? s.trim() : '').toList()
    : <String>[];

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return null;
}

// ---- codeLock: {"answer": "428"} ----------------------------------------
List<String> _validateCodeLock(Map<String, dynamic> c) {
  final a = c['answer'];
  if (a is! String || !RegExp(r'^\d{1,6}$').hasMatch(a)) {
    return ['codeLock.answer must be 1-6 digits written as text'];
  }
  return [];
}

bool _evalCodeLock(Map<String, dynamic> c, Object? answer) =>
    answer is String && answer.trim() == c['answer'];

Object? _solveCodeLock(Map<String, dynamic> c) => c['answer'];

// ---- sequence: {"items": [...]} in the CORRECT order ---------------------
List<String> _validateSequence(Map<String, dynamic> c) {
  final raw = c['items'];
  final items = _strings(raw);
  if (raw is! List ||
      items.length != raw.length ||
      items.length < 2 ||
      items.length > 6) {
    return ['sequence.items must be 2-6 strings'];
  }
  if (items.any((s) => s.isEmpty) || items.toSet().length != items.length) {
    return ['sequence.items must be unique and non-empty'];
  }
  return [];
}

bool _evalSequence(Map<String, dynamic> c, Object? answer) {
  if (answer is! List) return false;
  final expected = _strings(c['items']);
  if (answer.length != expected.length) return false;
  for (var i = 0; i < expected.length; i++) {
    if (answer[i] != expected[i]) return false;
  }
  return true;
}

Object? _solveSequence(Map<String, dynamic> c) => _strings(c['items']);

// ---- matching: {"pairs": [{"left": "..", "right": ".."}]} ----------------
List<Map<String, String>> _pairs(dynamic value) {
  final out = <Map<String, String>>[];
  if (value is! List) return out;
  for (final item in value) {
    if (item is Map && item['left'] is String && item['right'] is String) {
      out.add({
        'left': (item['left'] as String).trim(),
        'right': (item['right'] as String).trim(),
      });
    }
  }
  return out;
}

List<String> _validateMatching(Map<String, dynamic> c) {
  final raw = c['pairs'];
  final pairs = _pairs(raw);
  if (raw is! List ||
      pairs.length != raw.length ||
      pairs.length < 2 ||
      pairs.length > 5) {
    return ['matching.pairs must be 2-5 {left,right} text pairs'];
  }
  final lefts = pairs.map((p) => p['left']!).toList();
  final rights = pairs.map((p) => p['right']!).toList();
  if (lefts.any((s) => s.isEmpty) ||
      rights.any((s) => s.isEmpty) ||
      lefts.toSet().length != lefts.length ||
      rights.toSet().length != rights.length) {
    return ['matching pairs must be non-empty and unique on both sides'];
  }
  return [];
}

bool _evalMatching(Map<String, dynamic> c, Object? answer) {
  if (answer is! Map) return false;
  final pairs = _pairs(c['pairs']);
  if (answer.length != pairs.length) return false;
  for (final p in pairs) {
    if (answer[p['left']] != p['right']) return false;
  }
  return true;
}

Object? _solveMatching(Map<String, dynamic> c) =>
    {for (final p in _pairs(c['pairs'])) p['left']!: p['right']!};

// ---- choice: {"options": [...], "correctIndex": 1, "consequences": [...]} -
List<String> _validateChoice(Map<String, dynamic> c) {
  final raw = c['options'];
  final options = _strings(raw);
  final index = _asInt(c['correctIndex']);
  if (raw is! List ||
      options.length != raw.length ||
      options.length < 2 ||
      options.length > 4 ||
      options.any((s) => s.isEmpty)) {
    return ['choice.options must be 2-4 non-empty strings'];
  }
  if (index == null || index < 0 || index >= options.length) {
    return ['choice.correctIndex must point at one of the options'];
  }
  final consequences = c['consequences'];
  if (consequences != null &&
      (consequences is! List ||
          consequences.length != options.length ||
          consequences.any((e) => e is! String))) {
    return ['choice.consequences must be one text per option'];
  }
  return [];
}

bool _evalChoice(Map<String, dynamic> c, Object? answer) =>
    answer is int && answer == _asInt(c['correctIndex']);

Object? _solveChoice(Map<String, dynamic> c) => _asInt(c['correctIndex']);

String? _detailChoice(Map<String, dynamic> c, Object? answer, bool correct) {
  if (correct || answer is! int) return null;
  final consequences = c['consequences'];
  if (consequences is List && answer >= 0 && answer < consequences.length) {
    final text = consequences[answer];
    if (text is String && text.trim().isNotEmpty) return text.trim();
  }
  return null;
}

// ---- sort: {"bins": [...], "items": [{"text": "..", "bin": ".."}]} --------
List<Map<String, String>> _sortItems(dynamic value) {
  final out = <Map<String, String>>[];
  if (value is! List) return out;
  for (final item in value) {
    if (item is Map && item['text'] is String && item['bin'] is String) {
      out.add({
        'text': (item['text'] as String).trim(),
        'bin': (item['bin'] as String).trim(),
      });
    }
  }
  return out;
}

List<String> _validateSort(Map<String, dynamic> c) {
  final rawBins = c['bins'];
  final bins = _strings(rawBins);
  if (rawBins is! List ||
      bins.length != rawBins.length ||
      bins.length < 2 ||
      bins.length > 3 ||
      bins.any((s) => s.isEmpty) ||
      bins.toSet().length != bins.length) {
    return ['sort.bins must be 2-3 different names'];
  }

  final rawItems = c['items'];
  final items = _sortItems(rawItems);
  if (rawItems is! List ||
      items.length != rawItems.length ||
      items.length < 3 ||
      items.length > 8) {
    return ['sort.items must be 3-8 {text,bin} entries'];
  }

  final texts = items.map((i) => i['text']!).toList();
  if (texts.any((s) => s.isEmpty) || texts.toSet().length != texts.length) {
    return ['sort items must be unique and non-empty'];
  }
  if (items.any((i) => !bins.contains(i['bin']))) {
    return ['every sort item needs a bin that exists in sort.bins'];
  }
  if (bins.any((b) => !items.any((i) => i['bin'] == b))) {
    return ['every sort bin needs at least one item'];
  }
  return [];
}

bool _evalSort(Map<String, dynamic> c, Object? answer) {
  if (answer is! Map) return false;
  final items = _sortItems(c['items']);
  if (answer.length != items.length) return false;
  for (final item in items) {
    if (answer[item['text']] != item['bin']) return false;
  }
  return true;
}

Object? _solveSort(Map<String, dynamic> c) =>
    {for (final i in _sortItems(c['items'])) i['text']!: i['bin']!};

// ---- experiment: {"variable","goal","trials":[{"setting","result","success"}]}
List<Map<String, dynamic>> _trials(dynamic value) {
  final out = <Map<String, dynamic>>[];
  if (value is! List) return out;
  for (final item in value) {
    if (item is Map &&
        item['setting'] is String &&
        item['result'] is String &&
        item['success'] is bool) {
      out.add({
        'setting': (item['setting'] as String).trim(),
        'result': (item['result'] as String).trim(),
        'success': item['success'] as bool,
      });
    }
  }
  return out;
}

List<String> _validateExperiment(Map<String, dynamic> c) {
  final variable = c['variable'];
  final goal = c['goal'];
  if (variable is! String ||
      variable.trim().isEmpty ||
      goal is! String ||
      goal.trim().isEmpty) {
    return ['experiment needs a variable and a goal'];
  }

  final raw = c['trials'];
  final trials = _trials(raw);
  if (raw is! List ||
      trials.length != raw.length ||
      trials.length < 2 ||
      trials.length > 4) {
    return ['experiment.trials must be 2-4 {setting,result,success} entries'];
  }

  final settings = trials.map((t) => t['setting'] as String).toList();
  if (settings.any((s) => s.isEmpty) ||
      trials.any((t) => (t['result'] as String).isEmpty) ||
      settings.toSet().length != settings.length) {
    return ['experiment settings and results must be non-empty and unique'];
  }
  if (trials.where((t) => t['success'] == true).length != 1) {
    return ['experiment needs exactly one trial that reaches the goal'];
  }
  return [];
}

bool _evalExperiment(Map<String, dynamic> c, Object? answer) {
  final trials = _trials(c['trials']);
  return answer is int &&
      answer >= 0 &&
      answer < trials.length &&
      trials[answer]['success'] == true;
}

Object? _solveExperiment(Map<String, dynamic> c) =>
    _trials(c['trials']).indexWhere((t) => t['success'] == true);

String? _detailExperiment(
    Map<String, dynamic> c, Object? answer, bool correct) {
  final trials = _trials(c['trials']);
  if (answer is! int || answer < 0 || answer >= trials.length) return null;
  return trials[answer]['result'] as String;
}