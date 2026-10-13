class CurriculumTopic {
  final String id;
  final String name;
  final List<String> learningObjectives;

  CurriculumTopic({
    required this.id,
    required this.name,
    required this.learningObjectives,
  });

  factory CurriculumTopic.fromJson(Map<String, dynamic> json) {
    return CurriculumTopic(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Topic',
      learningObjectives:
          (json['learning_objectives'] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              [],
    );
  }
}

class CurriculumStrand {
  final String name;
  final List<CurriculumTopic> topics;

  CurriculumStrand({
    required this.name,
    required this.topics,
  });

  factory CurriculumStrand.fromJson(Map<String, dynamic> json) {
    return CurriculumStrand(
      name: json['name']?.toString() ?? 'Strand',
      topics:
          (json['topics'] as List?)
                  ?.map(
                    (topic) => CurriculumTopic.fromJson(
                      Map<String, dynamic>.from(topic),
                    ),
                  )
                  .toList() ??
              [],
    );
  }
}

class CurriculumClass {
  final int classNumber;
  final String level;
  final String stage;
  final List<CurriculumStrand> strands;

  CurriculumClass({
    required this.classNumber,
    required this.level,
    required this.stage,
    required this.strands,
  });

  factory CurriculumClass.fromJson(Map<String, dynamic> json) {
    return CurriculumClass(
      classNumber: int.tryParse(json['class'].toString()) ?? 1,
      level: json['level']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      strands:
          (json['strands'] as List?)
                  ?.map(
                    (strand) => CurriculumStrand.fromJson(
                      Map<String, dynamic>.from(strand),
                    ),
                  )
                  .toList() ??
              [],
    );
  }

  List<CurriculumTopic> get allTopics {
    return strands.expand((strand) => strand.topics).toList();
  }
}

class Curriculum {
  final String subject;
  final List<CurriculumClass> classes;

  Curriculum({
    required this.subject,
    required this.classes,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    return Curriculum(
      subject: json['subject']?.toString() ?? '',
      classes:
          (json['classes'] as List?)
                  ?.map(
                    (item) => CurriculumClass.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList() ??
              [],
    );
  }

  CurriculumClass? getClass(int classNumber) {
    try {
      return classes.firstWhere(
        (item) => item.classNumber == classNumber,
      );
    } catch (_) {
      return null;
    }
  }
}