
import 'package:flutter/material.dart';

class MysteryGameScreen extends StatelessWidget {
  final int classNumber;
  final String subject;
  final String topicName;
  final String mode;

  const MysteryGameScreen({
    super.key,
    required this.classNumber,
    required this.subject,
    required this.topicName,
    required this.mode,
  });

  static const Color sky = Color(0xFFEAF9FF);
    
  static const Color purple = Color(0xFF8B7CF6);
  static const Color darkPurple = Color(0xFF302C49);
  static const Color lightPurple = Color(0xFFE9E5FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sky,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MYSTERY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: darkPurple,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ICON
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: lightPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: purple.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          size: 65,
                          color: purple,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // COMING SOON
                      const Text(
                        'COMING SOON!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: darkPurple,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Mystery Adventure',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: purple,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'This adventure is still being created.\n'
                        'Get ready to investigate clues,\n'
                        'solve puzzles, and uncover the mystery!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: darkPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // TOPIC CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDCD7FF),
                              Color(0xFFE9F8FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: purple,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'YOUR ADVENTURE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: purple,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              topicName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: darkPurple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // BACK BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'BACK TO MISSIONS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
