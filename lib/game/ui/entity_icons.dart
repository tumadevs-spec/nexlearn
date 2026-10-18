/// Picks an emoji for a clue from its name, so every clue does not look the
/// same. Falls back to a magnifying glass.
///
/// Order matters: the first emoji with a matching word wins.
const Map<String, List<String>> _clueIcons = {
  '🔋': ['battery', 'power', 'charge', 'energy'],
  '🔌': ['cable', 'wire', 'plug', 'cord', 'socket'],
  '📖': ['manual', 'book', 'guide', 'instruction', 'recipe'],
  '📝': ['note', 'log', 'list', 'label', 'sign', 'report', 'diary', 'card'],
  '🗺️': ['map', 'plan', 'chart', 'diagram', 'blueprint'],
  '🔧': ['tool', 'wrench', 'spanner', 'screw', 'hammer'],
  '⚙️': ['gear', 'motor', 'machine', 'part', 'engine', 'wheel'],
  '💻': ['computer', 'screen', 'console', 'laptop', 'monitor', 'code'],
  '🌱': ['plant', 'seed', 'soil', 'flower', 'leaf', 'garden'],
  '💧': ['water', 'rain', 'drop', 'puddle'],
  '☀️': ['sun', 'light', 'lamp', 'window', 'torch'],
  '🧪': ['chemical', 'jar', 'bottle', 'flask', 'potion'],
  '🔑': ['key', 'lock'],
  '📦': ['box', 'tray', 'crate', 'parcel'],
  '🍎': ['food', 'fruit', 'apple', 'snack'],
  '🐾': ['footprint', 'track', 'paw', 'animal'],
};

String clueEmoji(String name) {
  final lower = name.toLowerCase();
  for (final entry in _clueIcons.entries) {
    for (final word in entry.value) {
      if (lower.contains(word)) return entry.key;
    }
  }
  return '🔍';
}