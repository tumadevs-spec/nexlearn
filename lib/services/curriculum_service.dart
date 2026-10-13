import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/curriculum_model.dart';

class CurriculumService {
  static Future<Curriculum> loadCurriculum(
    String assetPath,
  ) async {
    final jsonString = await rootBundle.loadString(assetPath);

    final Map<String, dynamic> jsonData =
        json.decode(jsonString) as Map<String, dynamic>;

    return Curriculum.fromJson(jsonData);
  }
}