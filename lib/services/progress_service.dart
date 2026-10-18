import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static String _key(String subject, int classNumber) =>
      'completed_missions_${subject}_$classNumber';

  static Future<Set<String>> loadCompleted(
    String subject,
    int classNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(subject, classNumber)) ?? <String>[])
        .toSet();
  }

  static Future<void> markCompleted({
    required String subject,
    required int classNumber,
    required String topicName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(subject, classNumber);
    final list = prefs.getStringList(key) ?? <String>[];
    if (!list.contains(topicName)) {
      list.add(topicName);
      await prefs.setStringList(key, list);
    }
  }
}