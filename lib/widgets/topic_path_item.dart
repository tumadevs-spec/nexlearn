import 'package:flutter/material.dart';

import '../models/curriculum_model.dart';

class TopicPathItem extends StatelessWidget {
  final int number;
  final CurriculumTopic topic;
  final bool isFirst;
  final bool isLast;

  const TopicPathItem({
    super.key,
    required this.number,
    required this.topic,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: const Color(0xFFBDB8E9),
                ),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8278E8),
                      Color(0xFF68C8EF),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              if (!isLast)
                Container(
                  width: 2,
                  height: 70,
                  color: const Color(0xFFBDB8E9),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOPIC $number',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: Color(0xFF8278E8),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF302C49),
                        ),
                      ),

                      if (topic.learningObjectives.isNotEmpty) ...[
                        const SizedBox(height: 7),

                        Text(
                          topic.learningObjectives.first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            color: Color(0xFF77738A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEAFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 17,
                    color: Color(0xFF8278E8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}