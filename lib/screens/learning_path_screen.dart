
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// NEXLEARN TYPOGRAPHY:
// Press Start 2P = game titles/labels
// DM Sans = readable body text

import '../models/curriculum_model.dart';
import '../services/curriculum_service.dart';
import 'action_game_screen.dart';
import 'mystery_game_screen.dart';

const String _nexImage = 'assets/images/robots/nex.png';

class LearningPathScreen extends StatefulWidget {
  final int classNumber;
  final String subject;
  final String assetPath;

  const LearningPathScreen({
    super.key,
    required this.classNumber,
    required this.subject,
    required this.assetPath,
  });

  @override
  State<LearningPathScreen> createState() =>
      _LearningPathScreenState();
}

class _LearningPathScreenState
    extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late Future<Curriculum> _curriculumFuture;
  late AnimationController _animationController;
  late AdventureWorldGame _game;

  @override
  void initState() {
    super.initState();

    _curriculumFuture =
        CurriculumService.loadCurriculum(widget.assetPath);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _game = AdventureWorldGame();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Stack(
        children: [
          // ----------------------------------------------------------
          // FLAME BACKGROUND
          // ----------------------------------------------------------
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(
                game: _game,
              ),
            ),
          ),

          // ----------------------------------------------------------
          // MAIN GRADIENT
          // ----------------------------------------------------------
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F3FF),
                    Color(0xFFEDE9FE),
                    Color(0xFFF3E8FF),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [
                    0.0,
                    0.32,
                    0.68,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ----------------------------------------------------------
          // GLOW BLOBS
          // ----------------------------------------------------------
          Positioned(
            top: -100,
            left: -80,
            child: _GlowBlob(
              size: 270,
              color: const Color(0xFFC4B5FD),
            ),
          ),

          Positioned(
            top: 230,
            right: -120,
            child: _GlowBlob(
              size: 300,
              color: const Color(0xFFA78BFA),
            ),
          ),

          Positioned(
            bottom: -130,
            left: -80,
            child: _GlowBlob(
              size: 300,
              color: const Color(0xFFEAF7FF),
            ),
          ),

          // ----------------------------------------------------------
          // CIRCUIT BACKGROUND
          // ----------------------------------------------------------
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CircuitBackgroundPainter(),
              ),
            ),
          ),

          // ----------------------------------------------------------
          // CONTENT
          // ----------------------------------------------------------
          SafeArea(
            child: FutureBuilder<Curriculum>(
              future: _curriculumFuture,
              builder: (context, snapshot) {
                // ----------------------------------------------------
                // LOADING
                // ----------------------------------------------------
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: _LoadingWorld(),
                  );
                }

                // ----------------------------------------------------
                // ERROR
                // ----------------------------------------------------
                if (snapshot.hasError) {
                  return _ErrorWorld(
                    message: snapshot.error.toString(),
                    onRetry: () {
                      setState(() {
                        _curriculumFuture =
                            CurriculumService.loadCurriculum(
                          widget.assetPath,
                        );
                      });
                    },
                  );
                }

                // ----------------------------------------------------
                // NO DATA
                // ----------------------------------------------------
                if (!snapshot.hasData) {
                  return const Center(
                    child: _EmptyWorld(
                      message: 'Your adventure is empty.',
                    ),
                  );
                }

                final curriculum = snapshot.data!;

                // ----------------------------------------------------
                // NO CLASSES
                // ----------------------------------------------------
                if (curriculum.classes.isEmpty) {
                  return const Center(
                    child: _EmptyWorld(
                      message: 'No missions found yet.',
                    ),
                  );
                }

                // ----------------------------------------------------
                // SELECT CLASS
                // ----------------------------------------------------
                final selectedClass =
                    curriculum.classes.firstWhere(
                  (item) =>
                      item.classNumber ==
                      widget.classNumber,
                  orElse: () =>
                      curriculum.classes.first,
                );

                final topics = selectedClass.allTopics;

                // ----------------------------------------------------
                // NO TOPICS
                // ----------------------------------------------------
                if (topics.isEmpty) {
                  return const Center(
                    child: _EmptyWorld(
                      message: 'No missions found yet.',
                    ),
                  );
                }

                return _buildWorld(
                  context,
                  topics,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
Widget _buildWorld(
  BuildContext context,
  List<CurriculumTopic> topics,
) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          0,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.76),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.95),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED)
                        .withOpacity(0.09),
                    blurRadius: 13,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF3B0764),
                size: 22,
              ),
            ),
          ),
        ),
      ),

      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            34,
          ),
          child: Column(
            children: [
              _buildHero(),

              const SizedBox(height: 22),

              _buildAdventureMap(
                context,
                topics,
              ),

              const SizedBox(height: 22),

              _buildDestination(),
            ],
          ),
        ),
      ),
    ],
  );
}
  
  // ==================================================================
  // HERO
  // ==================================================================

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            -3 * _animationController.value,
          ),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.80),
              const Color(0xFFF5F3FF)
                  .withOpacity(0.76),
              const Color(0xFFEDE9FE)
                  .withOpacity(0.80),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.92),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED)
                  .withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSION MAP',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.subject.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.7,
                      color: const Color(0xFF6B21A8),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Your AI Adventure',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      height: 1.35,
                      color: const Color(0xFF3B0764),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'NEX is ready to guide you. '
                    'Follow the path and unlock each mission.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B21A8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            const _NexHeroRobot(),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // ADVENTURE MAP
  // ==================================================================

 
Widget _buildAdventureMap(
  BuildContext context,
  List<CurriculumTopic> topics,
) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.76),
          const Color(0xFFEAF7FF).withOpacity(0.76),
          const Color(0xFFEDE9FE).withOpacity(0.82),
        ],
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.92),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7C3AED).withOpacity(0.12),
          blurRadius: 28,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Stack(
        children: [
          // Adventure map background decoration.
          Positioned.fill(
            child: CustomPaint(
              painter: _WorldDecorationPainter(),
            ),
          ),

          // All missions are temporarily unlocked.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              25,
              15,
              30,
            ),
            child: Column(
              children: [
                for (int i = 0; i < topics.length; i++) ...[
                  _GameMission(
                    number: i + 1,
                    topicName: topics[i].name,
                    // Only the first mission is unlocked for now.
                    unlocked: i == 0,
                    alignment: i.isEven
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    // Later missions unlock after progression is implemented.
                    onTap: i == 0
                        ? () {
                            _showGameChoice(
                              context,
                              topics[i].name,
                            );
                          }
                        : null,
                  ),

                  // Connect each mission to the next one.
                  if (i < topics.length - 1)
                    _buildConnection(i.isEven),
                ],

                const SizedBox(height: 18),

                // Adventure completion gate.
                _buildEndGate(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==================================================================
  // CONNECTION PATH
  // ==================================================================

  Widget _buildConnection(bool leftToRight) {
    return SizedBox(
      height: 82,
      child: CustomPaint(
        painter: _AdventurePathPainter(
          leftToRight: leftToRight,
        ),
        size: Size.infinite,
      ),
    );
  }

  // ==================================================================
  // END GATE
  // ==================================================================

  Widget _buildEndGate() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC4B5FD)
                    .withOpacity(0.30),
              ),
            ),

            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFA78BFA),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFF7C3AED),
                size: 29,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Text(
          'NEXT AREA',
          style: GoogleFonts.pressStart2p(
            fontSize: 7.5,
            color: const Color(0xFF6B21A8),
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // DESTINATION
  // ==================================================================

  Widget _buildDestination() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFEAF7FF),
            Color(0xFFEDE9FE),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED)
                .withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFEDE9FE),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF8072D7),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'MORE MISSIONS AHEAD',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: const Color(0xFF3B0764),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Complete your missions to open new areas.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B21A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // GAME MODE SELECTOR
  // ==================================================================

  void _showGameChoice(
    BuildContext context,
    String topicName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GameModeSheet(
          topicName: topicName,
          classNumber: widget.classNumber,
          subject: widget.subject,
          assetPath: widget.assetPath,
        );
      },
    );
  }
}

// ======================================================================
// GAME MISSION
// ======================================================================

class _GameMission extends StatelessWidget {
  final int number;
  final String topicName;
  final bool unlocked;
  final Alignment alignment;
  final VoidCallback? onTap;

  const _GameMission({
    required this.number,
    required this.topicName,
    required this.unlocked,
    required this.alignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 270,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: unlocked
                        ? [
                            Colors.white.withOpacity(0.95),
                            const Color(0xFFF5F3FF)
                                .withOpacity(0.92),
                          ]
                        : [
                            const Color(0xFFF3E8FF),
                            const Color(0xFFEDE9FE),
                          ],
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color: unlocked
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFEDE9FE),
                    width: unlocked ? 1.6 : 1.2,
                  ),
                  boxShadow: [
                    if (unlocked)
                      BoxShadow(
                        color: const Color(0xFF7C3AED)
                            .withOpacity(0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    _MissionOrb(
                      number: number,
                      unlocked: unlocked,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MISSION ${number.toString().padLeft(2, '0')}',
                            style:
                                GoogleFonts.pressStart2p(
                              fontSize: 7.5,
                              color: unlocked
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF9B98A7),
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            topicName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13.5,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              color: unlocked
                                  ? const Color(0xFF343575)
                                  : const Color(0xFF8B5CF6),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFFEDE9FE,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    8,
                                  ),
                                ),
                                child: Text(
                                  unlocked
                                      ? 'READY'
                                      : 'LOCKED',
                                  style:
                                      GoogleFonts.dmSans(
                                    fontSize: 7,
                                    fontWeight:
                                        FontWeight.w900,
                                    letterSpacing: 0.7,
                                    color: unlocked
                                        ? const Color(
                                            0xFF7468CC,
                                          )
                                        : const Color(
                                            0xFF8C8997,
                                          ),
                                  ),
                                ),
                              ),

                              if (unlocked) ...[
                                const SizedBox(width: 7),

                                Text(
                                  'TAP TO PLAY',
                                  style:
                                      GoogleFonts.dmSans(
                                    fontSize: 7.5,
                                    fontWeight:
                                        FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: const Color(
                                      0xFF8880D8,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Play indicator on unlocked mission
              if (unlocked)
                Positioned(
                  right: -7,
                  top: -8,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(0xFF8075E3),
                          Color(0xFFA78BFA),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF776ED4)
                              .withOpacity(0.22),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
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

// ======================================================================
// MISSION ORB
// ======================================================================

class _MissionOrb extends StatelessWidget {
  final int number;
  final bool unlocked;

  const _MissionOrb({
    required this.number,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (unlocked)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFCFC8FF)
                  .withOpacity(0.25),
            ),
          ),

        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: unlocked
                  ? const [
                      Color(0xFFE3DEFF),
                      Color(0xFFBEB6F2),
                    ]
                  : const [
                      Color(0xFFEDE9FE),
                      Color(0xFFD8D4F5),
                    ],
            ),
            border: Border.all(
              color: unlocked
                  ? const Color(0xFF9C90E2)
                  : const Color(0xFFC4B5FD),
              width: 2,
            ),
            boxShadow: [
              if (unlocked)
                BoxShadow(
                  color: const Color(0xFF8175D8)
                      .withOpacity(0.15),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Center(
            child: unlocked
                ? Text(
                    '$number',
                    style:
                        GoogleFonts.pressStart2p(
                      fontSize: 17,
                      color: const Color(0xFF6D28D9),
                    ),
                  )
                : const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 21,
                  ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// GAME MODE SHEET
// ======================================================================

class _GameModeSheet extends StatelessWidget {
  final String topicName;
  final int classNumber;
  final String subject;
  final String assetPath;

  const _GameModeSheet({
    required this.topicName,
    required this.classNumber,
    required this.subject,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        26,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F3FF),
            Color(0xFFF3E8FF),
            Color(0xFFF5F1FF),
          ],
        ),
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(34),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 45,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFB9B5D3),
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            // NEX + TITLE
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.82),
                    borderRadius:
                        BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white,
                    ),
                  ),
                  child: Image.asset(
                    _nexImage,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xFF7C3AED),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                  'NEX MODE SELECT',
                  style:
                      GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: const Color(0xFF3B0764),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'CHOOSE YOUR MODE',
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                height: 1.4,
                color: const Color(0xFF3B0764),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              topicName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B21A8),
              ),
            ),

            const SizedBox(height: 21),

            // GAME MODE CARDS
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ModeCard(
                    title: 'MYSTERY',
                    subtitle:
                        'Search for clues and solve the challenge.',
                    icon:
                        Icons.manage_search_rounded,
                    background:
                        const Color(0xFFEDE9FE),
                    iconColor:
                        const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MysteryGameScreen(
                            topicName: topicName,
                            classNumber:
                                classNumber,
                            subject: subject,
                            curriculumPath: assetPath,
                            mode: 'mystery',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _ModeCard(
                    title: 'ACTION',
                    subtitle:
                        'Move through the world and complete the challenge.',
                    icon: Icons.bolt_rounded,
                    background:
                        const Color(0xFFEAF7FF),
                    iconColor:
                        const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActionGameScreen(
                            topicName: topicName,
                            classNumber:
                                classNumber,
                            subject: subject,
                          ),
                        ),
                      );
                    },
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

// ======================================================================
// MODE CARD
// ======================================================================

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.94),
              background.withOpacity(0.48),
            ],
          ),
          borderRadius:
              BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED)
                  .withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: background,
                borderRadius:
                    BorderRadius.circular(17),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.9),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 29,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: const Color(0xFF3B0764),
              ),
            ),

            const SizedBox(height: 9),

            Text(
              subtitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10.5,
                height: 1.38,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B21A8),
              ),
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Text(
                  'PLAY',
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: 4),

                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ADVENTURE PATH PAINTER
// ======================================================================

class _AdventurePathPainter
    extends CustomPainter {
  final bool leftToRight;

  const _AdventurePathPainter({
    required this.leftToRight,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final glowPaint = Paint()
      ..color = const Color(0xFFBEB7F1)
          .withOpacity(0.25)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
          .withOpacity(0.78)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (leftToRight) {
      path.moveTo(
        size.width * 0.24,
        0,
      );

      path.cubicTo(
        size.width * 0.24,
        size.height * 0.35,
        size.width * 0.76,
        size.height * 0.65,
        size.width * 0.76,
        size.height,
      );
    } else {
      path.moveTo(
        size.width * 0.76,
        0,
      );

      path.cubicTo(
        size.width * 0.76,
        size.height * 0.35,
        size.width * 0.24,
        size.height * 0.65,
        size.width * 0.24,
        size.height,
      );
    }

    // Glow
    canvas.drawPath(
      path,
      glowPaint,
    );

    // Dashed line
    for (final metric
        in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = math.min(
          distance + 8,
          metric.length,
        );

        canvas.drawPath(
          metric.extractPath(
            distance,
            end,
          ),
          paint,
        );

        distance += 16;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _AdventurePathPainter
        oldDelegate,
  ) {
    return oldDelegate.leftToRight !=
        leftToRight;
  }
}

// ======================================================================
// WORLD DECORATION
// ======================================================================

class _WorldDecorationPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final gridPaint = Paint()
      ..color = const Color(0xFF7C3AED)
          .withOpacity(0.045)
      ..strokeWidth = 1;

    const gridSize = 30.0;

    for (double x = 0;
        x < size.width;
        x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0;
        y < size.height;
        y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
          .withOpacity(0.14);

    final glowPaint = Paint()
      ..color = const Color(0xFFC4B5FD)
          .withOpacity(0.10);

    final positions = [
      Offset(
        size.width * 0.12,
        size.height * 0.18,
      ),
      Offset(
        size.width * 0.84,
        size.height * 0.12,
      ),
      Offset(
        size.width * 0.11,
        size.height * 0.72,
      ),
      Offset(
        size.width * 0.89,
        size.height * 0.70,
      ),
    ];

    for (final position in positions) {
      canvas.drawCircle(
        position,
        44,
        glowPaint,
      );

      canvas.drawCircle(
        position,
        3,
        dotPaint,
      );
    }

    final smallDots = [
      Offset(
        size.width * 0.25,
        size.height * 0.10,
      ),
      Offset(
        size.width * 0.73,
        size.height * 0.28,
      ),
      Offset(
        size.width * 0.17,
        size.height * 0.48,
      ),
      Offset(
        size.width * 0.81,
        size.height * 0.53,
      ),
      Offset(
        size.width * 0.35,
        size.height * 0.87,
      ),
      Offset(
        size.width * 0.70,
        size.height * 0.88,
      ),
    ];

    for (final dot in smallDots) {
      canvas.drawCircle(
        dot,
        2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WorldDecorationPainter
        oldDelegate,
  ) {
    return false;
  }
}

// ======================================================================
// CIRCUIT BACKGROUND
// ======================================================================

class _CircuitBackgroundPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final linePaint = Paint()
      ..color = const Color(0xFF7C3AED)
          .withOpacity(0.035)
      ..strokeWidth = 1;

    final nodePaint = Paint()
      ..color = const Color(0xFF7C3AED)
          .withOpacity(0.08)
      ..style = PaintingStyle.fill;

    const gap = 42.0;

    for (double x = 0;
        x <= size.width;
        x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    for (double y = 0;
        y <= size.height;
        y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    final nodes = [
      Offset(
        size.width * 0.08,
        size.height * 0.16,
      ),
      Offset(
        size.width * 0.90,
        size.height * 0.23,
      ),
      Offset(
        size.width * 0.12,
        size.height * 0.76,
      ),
      Offset(
        size.width * 0.88,
        size.height * 0.80,
      ),
    ];

    for (final node in nodes) {
      canvas.drawCircle(
        node,
        3,
        nodePaint,
      );

      canvas.drawCircle(
        node,
        8,
        Paint()
          ..color = const Color(0xFF8B5CF6)
              .withOpacity(0.025),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _CircuitBackgroundPainter
        oldDelegate,
  ) {
    return false;
  }
}

// ======================================================================
// FLAME GAME
// ======================================================================

class AdventureWorldGame extends FlameGame {
  final math.Random _random =
      math.Random();

  @override
  Color backgroundColor() =>
      const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (int i = 0; i < 24; i++) {
      add(
        _FloatingOrb(
          position: Vector2(
            _random.nextDouble() * 900,
            _random.nextDouble() * 1600,
          ),
          radius:
              1.5 +
              _random.nextDouble() * 3,
          speed:
              0.3 +
              _random.nextDouble() * 0.7,
        ),
      );
    }
  }
}

// ======================================================================
// FLOATING ORB
// ======================================================================

class _FloatingOrb
    extends PositionComponent {
  final double radius;
  final double speed;

  double time = 0;

  _FloatingOrb({
    required Vector2 position,
    required this.radius,
    required this.speed,
  }) : super(
          position: position,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);

    time += dt * speed;

    position.y +=
        math.sin(time) * 0.10;

    position.x +=
        math.cos(time * 0.7) * 0.04;

    if (position.y > 1700) {
      position.y = -20;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
          .withOpacity(0.18);

    canvas.drawCircle(
      Offset.zero,
      radius,
      paint,
    );
  }
}

// ======================================================================
// NEX HERO ROBOT
// ======================================================================

class _NexHeroRobot
    extends StatelessWidget {
  const _NexHeroRobot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC4B5FD)
                  .withOpacity(0.40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA)
                      .withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          Positioned(
            top: 2,
            right: 3,
            child: Container(
              width: 13,
              height: 13,
              decoration:
                  const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(8),
            child: Image.asset(
              _nexImage,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 42,
                    color: Color(0xFF7C3AED),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// GLOW BLOB
// ======================================================================

class _GlowBlob
    extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.25),
        ),
      ),
    );
  }
}

// ======================================================================
// LOADING
// ======================================================================

class _LoadingWorld
    extends StatelessWidget {
  const _LoadingWorld();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5F3FF),
            Color(0xFFF3E8FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED)
                .withOpacity(0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF8275D8),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            'LOADING WORLD',
            style:
                GoogleFonts.pressStart2p(
              fontSize: 8,
              color: const Color(
                0xFF3B0764,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// EMPTY WORLD
// ======================================================================

class _EmptyWorld
    extends StatelessWidget {
  final String message;

  const _EmptyWorld({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.all(24),
      padding:
          const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.85),
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Text(
        message,
        textAlign:
            TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight:
              FontWeight.w700,
          color: const Color(
            0xFF3B0764,
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// ERROR WORLD
// ======================================================================

class _ErrorWorld
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWorld({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Container(
          padding:
              const EdgeInsets.all(24),
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFFF5F3FF),
                Color(0xFFF3E8FF),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              28,
            ),
            border: Border.all(
              color: Colors.white,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF7C3AED,
                ).withOpacity(0.12),
                blurRadius: 22,
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFFEDE9FE,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 30,
                  color: Color(
                    0xFF8175D8,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'WORLD OFFLINE',
                textAlign:
                    TextAlign.center,
                style:
                    GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: const Color(
                    0xFF3B0764,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                maxLines: 4,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style:
                    GoogleFonts.dmSans(
                  fontSize: 10.5,
                  height: 1.4,
                  color: const Color(
                    0xFF6B21A8,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(
                          0xFF7C3AED,
                        ).withOpacity(0.22),
                        blurRadius: 12,
                        offset:
                            const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
                  ),
                  child: Text(
                    'TRY AGAIN',
                    style:
                        GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: Colors.white,
                    ),
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
