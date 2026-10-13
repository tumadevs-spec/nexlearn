import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  final int classNumber;
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.classNumber,
    required this.onTap,
  });

  static const List<String> levelNames = [
    'STARTER',
    'PLAYER',
    'RISING STAR',
    'PRO PLAYER',
    'SUPER PLAYER',
    'CHAMPION',
  ];

  static const List<String> descriptions = [
    "Let's begin!",
    'Ready to play?',
    'Level up!',
    'Show your skills!',
    'Take the challenge!',
    'Ready for the big leagues?',
  ];

  static const List<List<Color>> gradients = [
    [
      Color(0xFFE3F7FF),
      Color(0xFFBCEBFF),
    ],
    [
      Color(0xFFF0EDFF),
      Color(0xFFD8D0FF),
    ],
    [
      Color(0xFFDDF4FF),
      Color(0xFFAEDFFF),
    ],
    [
      Color(0xFFEDE9FF),
      Color(0xFFC8BEFF),
    ],
    [
      Color(0xFFE2F7FF),
      Color(0xFFAEDFFF),
    ],
    [
      Color(0xFFF0EDFF),
      Color(0xFFC8BEFF),
    ],
  ];

  static const List<Color> accents = [
    Color(0xFF5C9FE8),
    Color(0xFF897AF3),
    Color(0xFF5C9FE8),
    Color(0xFF897AF3),
    Color(0xFF5C9FE8),
    Color(0xFF897AF3),
  ];

  static const List<IconData> icons = [
    Icons.child_friendly_rounded,
    Icons.gamepad_rounded,
    Icons.trending_up_rounded,
    Icons.bolt_rounded,
    Icons.auto_awesome_rounded,
    Icons.workspace_premium_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final int index = classNumber - 1;

    final String levelName = levelNames[index];
    final String description = descriptions[index];
    final List<Color> gradient = gradients[index];
    final Color accent = accents[index];
    final IconData levelIcon = icons[index];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.16),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // =========================================================
              // MAIN BACKGROUND
              // =========================================================

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient.first,
                        gradient.last,
                        const Color(0xFFF9F8FF),
                      ],
                      stops: const [
                        0.0,
                        0.62,
                        1.0,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              // =========================================================
              // LARGE SOFT GLOW
              // =========================================================

              Positioned(
                top: -70,
                right: -65,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.30),
                  ),
                ),
              ),

              // =========================================================
              // BOTTOM SOFT GLOW
              // =========================================================

              Positioned(
                bottom: -70,
                left: -65,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
              ),

              // =========================================================
              // LEVEL BADGE
              // =========================================================

              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.90),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        levelIcon,
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LEVEL ${classNumber.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // SMALL AI ORB
              // =========================================================

              Positioned(
                top: 17,
                right: 17,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.48),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.72),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 17,
                    color: accent.withOpacity(0.75),
                  ),
                ),
              ),

              // =========================================================
              // ROBOT GLOW
              // =========================================================

              Positioned(
                top: 38,
                right: 20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.48),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // =========================================================
              // MAIN AI ROBOT
              // =========================================================

              Positioned(
                top: 38,
                right: 8,
                child: SizedBox(
                  width: 125,
                  height: 125,
                  child: Image.asset(
                    'assets/images/robot.png',
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Icon(
                        Icons.smart_toy_rounded,
                        size: 85,
                        color: accent.withOpacity(0.40),
                      );
                    },
                  ),
                ),
              ),

              // =========================================================
              // ROBOT FLOOR LIGHT
              // =========================================================

              Positioned(
                top: 145,
                right: 38,
                child: Container(
                  width: 75,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.24),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // BOTTOM GLASS PANEL
              // =========================================================

              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    15,
                    11,
                    10,
                    11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.73),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.92),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.07),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // -------------------------------------------------
                      // LEVEL NAME
                      // -------------------------------------------------

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              levelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: Color(0xFF3C3A5C),
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF85829C),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 9),

                      // -------------------------------------------------
                      // PLAY BUTTON
                      // -------------------------------------------------

                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent,
                              Color.lerp(
                                    accent,
                                    Colors.white,
                                    0.18,
                                  ) ??
                                  accent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // TOP LIGHT REFLECTION
              // =========================================================

              Positioned(
                top: 0,
                left: 28,
                right: 28,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}