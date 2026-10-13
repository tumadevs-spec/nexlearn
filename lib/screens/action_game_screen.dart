import 'package:flutter/material.dart';

class ActionGameScreen extends StatelessWidget {
  final String topicName;
  final int classNumber;
  final String subject;

  const ActionGameScreen({
    super.key,
    required this.topicName,
    required this.classNumber,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft background circles
            Positioned(
              top: -90,
              right: -70,
              child: _BackgroundCircle(
                size: 230,
                color: const Color(0xFFDDEBFF),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -80,
              child: _BackgroundCircle(
                size: 250,
                color: const Color(0xFFE7DFFF),
              ),
            ),

            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    0,
                  ),
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
                            border: Border.all(
                              color: const Color(0xFFE0DDF0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF514C70),
                            size: 23,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'ACTION',
                          style: TextStyle(
                            color: Color(0xFF302D4A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Color(0xFF6389B9),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 30,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Robot
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8A7FD0)
                                      .withOpacity(0.12),
                                  blurRadius: 35,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Image.asset(
                                'assets/images/robot.png',
                                fit: BoxFit.contain,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.smart_toy_rounded,
                                    size: 90,
                                    color: Color(0xFF8176D0),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'ACTION ADVENTURES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8176C7),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 9),

                          const Text(
                            'Coming Soon',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF302D4A),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Get ready for an exciting way to explore\n'
                            'your missions through action and adventure.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF77728F),
                              fontSize: 14,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Topic card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(
                                color: const Color(0xFFE1DDF2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.045),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F1FF),
                                    borderRadius:
                                        BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFF6796CE),
                                    size: 27,
                                  ),
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'YOUR MISSION',
                                        style: TextStyle(
                                          color: Color(0xFF9A94AE),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        topicName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF403B5B),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Back button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    const Color(0xFF8176D0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(17),
                                ),
                              ),
                              child: const Text(
                                'BACK TO MISSIONS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
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
          ],
        ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}