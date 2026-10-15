
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/learning_path_screen.dart';

// ================================================================
// PALETTE
// ================================================================

const Color _violetDark = Color(0xFF3B0764);
const Color _violet = Color(0xFF7C3AED);
const Color _violetMid = Color(0xFF8B5CF6);
const Color _violetLight = Color(0xFFA78BFA);

extension _Alpha on Color {
  Color op(double opacity) => withValues(alpha: opacity);
}

// ================================================================
// SUBJECT / WORLD SCREEN
// ================================================================

class SubjectScreen extends StatefulWidget {
  final int classNumber;

  const SubjectScreen({
    super.key,
    required this.classNumber,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _introController;

  late final List<_Particle> _particles;

  int _selectedWorld = -1;

  @override
  void initState() {
    super.initState();

    _particles = _buildParticles();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bool reduce = MediaQuery.disableAnimationsOf(context);

    if (reduce) {
      _floatController.stop();
      _pulseController.stop();
      _particleController.stop();
      _introController.value = 1;
    } else {
      if (!_floatController.isAnimating) {
        _floatController.repeat(reverse: true);
      }

      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }

      if (!_particleController.isAnimating) {
        _particleController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _introController.dispose();

    super.dispose();
  }

  // ==============================================================
  // CURRICULUM NAVIGATION
  //
  // SubjectScreen
  //      ↓
  // LearningPathScreen
  //      ↓
  // CurriculumService
  //      ↓
  // curriculum JSON
  //
  // IMPORTANT:
  // `assetPath` here is the CURRICULUM JSON path.
  // The robot image is stored separately in _WorldData.
  // ==============================================================

  void _openWorld({
    required String subject,
    required String curriculumPath,
  }) {
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, secondaryAnimation) {
          return LearningPathScreen(
            classNumber: widget.classNumber,
            subject: subject,
            assetPath: curriculumPath,
          );
        },
        transitionsBuilder: (
          _,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool mobile = width < 700;
          final bool verySmall = height < 620;

          return Stack(
            fit: StackFit.expand,
            children: [
              const _AIBackground(),

              // ----------------------------------------------------
              // PARTICLES
              // ----------------------------------------------------

              RepaintBoundary(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _AIParticlePainter(
                          particles: _particles,
                          progress: _particleController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ----------------------------------------------------
              // CIRCUIT GRID
              // ----------------------------------------------------

              if (!mobile)
                const Positioned.fill(
                  child: RepaintBoundary(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CircuitBackgroundPainter(),
                      ),
                    ),
                  ),
                ),

              // ----------------------------------------------------
              // DECORATIONS
              // ----------------------------------------------------

              const Positioned.fill(
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProfessionalDecorationPainter(),
                    ),
                  ),
                ),
              ),

              // ----------------------------------------------------
              // MAIN UI
              // ----------------------------------------------------

              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 14 : 30,
                    mobile ? 10 : 18,
                    mobile ? 14 : 30,
                    mobile ? 8 : 12,
                  ),
                  child: Column(
                    children: [
                      _SubjectTopBar(
                        classNumber: widget.classNumber,
                        onBack: () => Navigator.pop(context),
                      ),

                      SizedBox(
                        height: mobile
                            ? (verySmall ? 5 : 9)
                            : 10,
                      ),

                      _Reveal(
                        animation: _introController,
                        start: 0.0,
                        end: 0.55,
                        dy: 15,
                        child: _WorldHeading(
                          mobile: mobile,
                          verySmall: verySmall,
                        ),
                      ),

                      SizedBox(
                        height: mobile
                            ? (verySmall ? 5 : 9)
                            : 12,
                      ),

                      Expanded(
                        child: _WorldGrid(
                          selectedWorld: _selectedWorld,
                          floatAnimation: _floatController,
                          pulseAnimation: _pulseController,
                          introAnimation: _introController,
                          mobile: mobile,
                          verySmall: verySmall,
                          onSelect: (index) {
                            setState(() {
                              _selectedWorld = index;
                            });
                          },
                          onOpen: _openWorld,
                        ),
                      ),

                      SizedBox(
                        height: mobile
                            ? (verySmall ? 2 : 5)
                            : 5,
                      ),

                      const _BottomDecoration(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================================================
// TOP BAR
// ================================================================

class _SubjectTopBar extends StatelessWidget {
  final int classNumber;
  final VoidCallback onBack;

  const _SubjectTopBar({
    required this.classNumber,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool mobile = width < 700;

    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
          size: mobile ? 40 : 44,
        ),

        const Spacer(),

        const _MiniLogo(),

        const Spacer(),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 10 : 14,
            vertical: mobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.op(.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _violetLight.op(.35),
            ),
            boxShadow: [
              BoxShadow(
                color: _violet.op(.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: _violet,
                size: mobile ? 15 : 17,
              ),
              const SizedBox(width: 5),
              Text(
                'LEVEL $classNumber',
                style: GoogleFonts.pressStart2p(
                  color: _violetDark,
                  fontSize: mobile ? 6.5 : 7.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// MINI LOGO
// ================================================================

class _MiniLogo extends StatelessWidget {
  const _MiniLogo();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool mobile = width < 700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NEXLEARN',
          style: GoogleFonts.pressStart2p(
            color: _violetDark,
            fontSize: mobile ? 9 : 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI GAME WORLD',
          style: GoogleFonts.pressStart2p(
            color: _violet,
            fontSize: mobile ? 4.5 : 5.5,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// GLASS ICON BUTTON
// ================================================================

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            hovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            hovered = false;
          });
        },
        child: AnimatedScale(
          scale: pressed
              ? .93
              : hovered
                  ? 1.05
                  : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white.op(.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hovered
                    ? _violet.op(.45)
                    : _violetLight.op(.30),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _violet.op(
                    hovered ? .16 : .08,
                  ),
                  blurRadius: hovered ? 20 : 13,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: _violetDark,
              size: widget.size * .48,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// HEADING
// ================================================================

class _WorldHeading extends StatelessWidget {
  final bool mobile;
  final bool verySmall;

  const _WorldHeading({
    required this.mobile,
    required this.verySmall,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = mobile
        ? (verySmall ? 12 : 15)
        : 21;

    final double subtitleSize = mobile
        ? (verySmall ? 6 : 7)
        : 8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CHOOSE YOUR WORLD',
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(
            color: _violetDark,
            fontSize: titleSize,
            height: 1.3,
          ),
        ),
        SizedBox(height: mobile ? 4 : 7),
        Text(
          'YOUR NEXT ADVENTURE AWAITS',
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(
            color: _violet,
            fontSize: subtitleSize,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// WORLD GRID
// ================================================================

class _WorldGrid extends StatelessWidget {
  final int selectedWorld;

  final Animation<double> floatAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> introAnimation;

  final bool mobile;
  final bool verySmall;

  final ValueChanged<int> onSelect;

  final void Function({
    required String subject,
    required String curriculumPath,
  }) onOpen;

  const _WorldGrid({
    required this.selectedWorld,
    required this.floatAnimation,
    required this.pulseAnimation,
    required this.introAnimation,
    required this.mobile,
    required this.verySmall,
    required this.onSelect,
    required this.onOpen,
  });

  // ==============================================================
  // WORLD + CURRICULUM DATA
  //
  // robotPath:
  //     visual PNG displayed on the world card
  //
  // curriculumPath:
  //     JSON passed to LearningPathScreen
  //
  // DO NOT confuse these two.
  // ==============================================================

  static const List<_WorldData> worlds = [
    _WorldData(
      name: 'PIXEL WORLD',
      curriculumSubject: 'Pixel World',
      curriculumPath:
          'assets/curriculum/computer_science.json',
      robotPath:
          'assets/images/subjects/computer_robot.png',
      icon: Icons.memory_rounded,
    ),

    _WorldData(
      name: 'HEART WORLD',
      curriculumSubject: 'Heart World',
      curriculumPath:
          'assets/curriculum/wellbeing_curriculum.json',
      robotPath:
          'assets/images/subjects/wellbeing_robot.png',
      icon: Icons.favorite_rounded,
    ),

    _WorldData(
      name: 'NOVA WORLD',
      curriculumSubject: 'Nova World',
      curriculumPath:
          'assets/curriculum/science_curriculum.json',
      robotPath:
          'assets/images/subjects/sciencerobot.png',
      icon: Icons.auto_awesome_rounded,
    ),

    _WorldData(
      name: 'MONEY WORLD',
      curriculumSubject: 'Money World',
      curriculumPath:
          'assets/curriculum/math_curriculum.json',
      robotPath:
          'assets/images/subjects/mathrobot.png',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double gap = mobile ? 8 : 12;

    return Column(
      children: [
        // ==========================================================
        // TOP ROW
        // ==========================================================

        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _Reveal(
                  animation: introAnimation,
                  start: .15,
                  end: .70,
                  dy: 18,
                  child: _WorldCard(
                    data: worlds[0],
                    index: 0,
                    selected: selectedWorld == 0,
                    floatAnimation: floatAnimation,
                    pulseAnimation: pulseAnimation,
                    mobile: mobile,
                    verySmall: verySmall,
                    onSelect: onSelect,
                    onOpen: onOpen,
                  ),
                ),
              ),

              SizedBox(width: gap),

              Expanded(
                child: _Reveal(
                  animation: introAnimation,
                  start: .22,
                  end: .77,
                  dy: 18,
                  child: _WorldCard(
                    data: worlds[1],
                    index: 1,
                    selected: selectedWorld == 1,
                    floatAnimation: floatAnimation,
                    pulseAnimation: pulseAnimation,
                    mobile: mobile,
                    verySmall: verySmall,
                    onSelect: onSelect,
                    onOpen: onOpen,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: gap),

        // ==========================================================
        // BOTTOM ROW
        // ==========================================================

        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _Reveal(
                  animation: introAnimation,
                  start: .29,
                  end: .84,
                  dy: 18,
                  child: _WorldCard(
                    data: worlds[2],
                    index: 2,
                    selected: selectedWorld == 2,
                    floatAnimation: floatAnimation,
                    pulseAnimation: pulseAnimation,
                    mobile: mobile,
                    verySmall: verySmall,
                    onSelect: onSelect,
                    onOpen: onOpen,
                  ),
                ),
              ),

              SizedBox(width: gap),

              Expanded(
                child: _Reveal(
                  animation: introAnimation,
                  start: .36,
                  end: .91,
                  dy: 18,
                  child: _WorldCard(
                    data: worlds[3],
                    index: 3,
                    selected: selectedWorld == 3,
                    floatAnimation: floatAnimation,
                    pulseAnimation: pulseAnimation,
                    mobile: mobile,
                    verySmall: verySmall,
                    onSelect: onSelect,
                    onOpen: onOpen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// WORLD DATA
// ================================================================

class _WorldData {
  final String name;

  // Display name passed to LearningPathScreen.
  final String curriculumSubject;

  // JSON curriculum file.
  final String curriculumPath;

  // Robot PNG shown on card.
  final String robotPath;

  final IconData icon;

  const _WorldData({
    required this.name,
    required this.curriculumSubject,
    required this.curriculumPath,
    required this.robotPath,
    required this.icon,
  });
}

// ================================================================
// WORLD CARD
// ================================================================

class _WorldCard extends StatefulWidget {
  final _WorldData data;
  final int index;
  final bool selected;

  final Animation<double> floatAnimation;
  final Animation<double> pulseAnimation;

  final bool mobile;
  final bool verySmall;

  final ValueChanged<int> onSelect;

  final void Function({
    required String subject,
    required String curriculumPath,
  }) onOpen;

  const _WorldCard({
    required this.data,
    required this.index,
    required this.selected,
    required this.floatAnimation,
    required this.pulseAnimation,
    required this.mobile,
    required this.verySmall,
    required this.onSelect,
    required this.onOpen,
  });

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool hovered = false;
  bool pressed = false;

  // ==============================================================
  // OPEN CURRICULUM WORLD
  // ==============================================================

  void _tap() {
    HapticFeedback.lightImpact();

    widget.onSelect(widget.index);

    Future.delayed(
      const Duration(milliseconds: 80),
      () {
        if (!mounted) return;

        widget.onOpen(
          subject: widget.data.curriculumSubject,
          curriculumPath: widget.data.curriculumPath,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        final double imageSize = math.min(
          cardWidth * .90,
          cardHeight * (widget.verySmall ? .80 : .88),
        );

        final double titleSize = widget.mobile
            ? (widget.verySmall ? 6 : 7)
            : 8;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() {
              hovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              hovered = false;
            });
          },
          child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                pressed = true;
              });
            },
            onTapCancel: () {
              setState(() {
                pressed = false;
              });
            },
            onTapUp: (_) {
              setState(() {
                pressed = false;
              });
            },
            onTap: _tap,
            child: AnimatedScale(
              scale: pressed
                  ? .975
                  : hovered
                      ? 1.015
                      : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.op(.86),
                      const Color(0xFFF5F0FF).op(.90),
                      const Color(0xFFEDE9FE).op(.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.mobile ? 18 : 24,
                  ),
                  border: Border.all(
                    color: widget.selected || hovered
                        ? _violet.op(.55)
                        : _violetLight.op(.27),
                    width: widget.selected || hovered
                        ? 1.7
                        : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.op(
                        widget.selected || hovered
                            ? .18
                            : .08,
                      ),
                      blurRadius:
                          widget.selected || hovered
                              ? 28
                              : 18,
                      spreadRadius:
                          widget.selected || hovered
                              ? 2
                              : 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // =================================================
                    // GLOW
                    // =================================================

                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: widget.pulseAnimation,
                          builder: (context, _) {
                            final double pulse =
                                1 +
                                math.sin(
                                      widget.pulseAnimation.value *
                                          math.pi,
                                    ) *
                                    .035;

                            return Transform.scale(
                              scale: pulse,
                              child: Center(
                                child: Container(
                                  width: imageSize * 1.02,
                                  height: imageSize * .82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _violetLight.op(.32),
                                        _violetMid.op(.15),
                                        Colors.transparent,
                                      ],
                                      stops: const [
                                        0,
                                        .55,
                                        1,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // =================================================
                    // ORBIT
                    // =================================================

                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: widget.floatAnimation,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: Size(
                                    imageSize * 1.05,
                                    imageSize * .60,
                                  ),
                                  painter: _MiniOrbitPainter(
                                    progress:
                                        widget.floatAnimation.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // MAIN CHARACTER PNG
                    // =================================================

                    Positioned.fill(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: widget.floatAnimation,
                          child: Image.asset(
                            widget.data.robotPath,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _CharacterFallback(
                                size: imageSize,
                                icon: widget.data.icon,
                              );
                            },
                          ),
                          builder: (context, child) {
                            final double movement =
                                math.sin(
                                      widget.floatAnimation.value *
                                          math.pi,
                                    ) *
                                    (widget.mobile ? 3.5 : 7);

                            return Transform.translate(
                              offset: Offset(0, -movement),
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),

                    // =================================================
                    // WORLD NAME
                    // =================================================

                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: widget.mobile
                          ? (widget.verySmall ? 9 : 11)
                          : 15,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                widget.mobile ? 9 : 13,
                            vertical:
                                widget.mobile ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.op(.88),
                            borderRadius:
                                BorderRadius.circular(11),
                            border: Border.all(
                              color: _violetLight.op(.28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _violet.op(.09),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.data.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.pressStart2p(
                              color: _violetDark,
                              fontSize: titleSize,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // WORLD NODE
                    // =================================================

                    Positioned(
                      top: widget.mobile ? 10 : 14,
                      right: widget.mobile ? 10 : 15,
                      child: _WorldNode(
                        icon: widget.data.icon,
                        active:
                            hovered || widget.selected,
                      ),
                    ),

                    // =================================================
                    // CORNER MARK
                    // =================================================

                    Positioned(
                      top: 12,
                      left: 12,
                      child: _CornerMark(
                        active:
                            hovered || widget.selected,
                      ),
                    ),

                    // =================================================
                    // TECH LINE
                    // =================================================

                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _SmallTechLine(
                        active:
                            hovered || widget.selected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// WORLD NODE
// ================================================================

class _WorldNode extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _WorldNode({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active
            ? _violet.op(.12)
            : Colors.white.op(.72),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? _violet.op(.40)
              : _violetLight.op(.25),
        ),
        boxShadow: [
          BoxShadow(
            color: _violet.op(
              active ? .18 : .07,
            ),
            blurRadius: active ? 15 : 9,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 15,
        color: _violet,
      ),
    );
  }
}

// ================================================================
// CORNER MARK
// ================================================================

class _CornerMark extends StatelessWidget {
  final bool active;

  const _CornerMark({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: active
                ? _violet
                : _violetLight.op(.55),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 5 : 4,
          height: active ? 5 : 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? _violet
                : _violetMid.op(.55),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// SMALL TECH LINE
// ================================================================

class _SmallTechLine extends StatelessWidget {
  final bool active;

  const _SmallTechLine({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 28 : 20,
          height: 2,
          decoration: BoxDecoration(
            color: active
                ? _violet
                : _violetLight.op(.40),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _violetMid.op(.45),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// CHARACTER FALLBACK
// ================================================================

class _CharacterFallback extends StatelessWidget {
  final double size;
  final IconData icon;

  const _CharacterFallback({
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double boxSize = math.min(
      size * .45,
      130,
    );

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white.op(.75),
        borderRadius:
            BorderRadius.circular(boxSize * .20),
        border: Border.all(
          color: _violetLight.op(.40),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _violet.op(.15),
            blurRadius: 25,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: _violet,
        size: boxSize * .38,
      ),
    );
  }
}

// ================================================================
// MINI ORBIT
// ================================================================

class _MiniOrbitPainter extends CustomPainter {
  final double progress;

  const _MiniOrbitPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double rx = size.width / 2;
    final double ry = size.height / 2;

    canvas.save();

    canvas.translate(
      size.width / 2,
      size.height / 2,
    );

    canvas.rotate(
      -.12 +
          math.sin(progress * math.pi) * .04,
    );

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _violet.op(.17);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      ),
      ringPaint,
    );

    for (int i = 0; i < 3; i++) {
      final double angle =
          progress * math.pi * 2 +
          i * math.pi * 2 / 3;

      final Offset position = Offset(
        math.cos(angle) * rx,
        math.sin(angle) * ry,
      );

      canvas.drawCircle(
        position,
        6,
        Paint()
          ..color = _violet.op(.13)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            5,
          ),
      );

      canvas.drawCircle(
        position,
        i == 0 ? 2.8 : 2,
        Paint()..color = _violet,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _MiniOrbitPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ================================================================
// REVEAL ANIMATION
// ================================================================

class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final double start;
  final double end;
  final double dy;
  final Widget child;

  const _Reveal({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.dy = 20,
  });

  @override
  Widget build(BuildContext context) {
    final Interval interval = Interval(
      start,
      end,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t =
            interval.transform(animation.value);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              0,
              dy * (1 - t),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ================================================================
// AI BACKGROUND
// ================================================================

class _AIBackground extends StatelessWidget {
  const _AIBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
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
            0.35,
            0.70,
            1.0,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(
            alignment: Alignment(-1.15, -.85),
            size: 320,
            color: Color(0xFFC4B5FD),
          ),
          _GlowBlob(
            alignment: Alignment(1.1, -.55),
            size: 300,
            color: Color(0xFFA78BFA),
          ),
          _GlowBlob(
            alignment: Alignment(.9, 1.0),
            size: 360,
            color: Color(0xFFE9D5FF),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// GLOW BLOB
// ================================================================

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.op(.24),
            boxShadow: [
              BoxShadow(
                color: color.op(.28),
                blurRadius: 100,
                spreadRadius: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CIRCUIT GRID
// ================================================================

class _CircuitBackgroundPainter
    extends CustomPainter {
  const _CircuitBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = _violet.op(.08);

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _violet.op(.15);

    const double grid = 55;

    for (
      double x = 0;
      x < size.width;
      x += grid
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    for (
      double y = 0;
      y < size.height;
      y += grid
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    for (
      double x = grid;
      x < size.width;
      x += grid * 2
    ) {
      for (
        double y = grid;
        y < size.height;
        y += grid * 2
      ) {
        canvas.drawCircle(
          Offset(x, y),
          2.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// PROFESSIONAL DECORATION
// ================================================================

class _ProfessionalDecorationPainter
    extends CustomPainter {
  const _ProfessionalDecorationPainter();

  static const List<List<double>> _dim = [
    [.025, .25, .065, .25, .08, .22, .14, .22],
    [.86, .17, .91, .17, .925, .20, .975, .20],
    [.03, .78, .07, .78, .085, .75, .125, .75],
    [.875, .80, .92, .80, .935, .77, .975, .77],
  ];

  static const List<List<double>> _bright = [
    [.015, .48, .055, .48, .07, .45, .10, .45],
    [.90, .55, .935, .55, .95, .52, .99, .52],
  ];

  void _trace(
    Canvas canvas,
    Size size,
    List<double> p,
    Paint paint, {
    required Paint? dot,
    required double dotRadius,
  }) {
    Offset at(int i) {
      return Offset(
        size.width * p[i * 2],
        size.height * p[i * 2 + 1],
      );
    }

    final Path path = Path()
      ..moveTo(
        at(0).dx,
        at(0).dy,
      );

    for (int i = 1; i < 4; i++) {
      path.lineTo(
        at(i).dx,
        at(i).dy,
      );
    }

    canvas.drawPath(path, paint);

    if (dot != null) {
      canvas.drawCircle(
        at(3),
        dotRadius,
        dot,
      );
    }
  }

  void _diamond(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final Path path = Path()
      ..moveTo(
        center.dx,
        center.dy - radius,
      )
      ..lineTo(
        center.dx + radius,
        center.dy,
      )
      ..lineTo(
        center.dx,
        center.dy + radius,
      )
      ..lineTo(
        center.dx - radius,
        center.dy,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _violetMid.op(.10);

    final Paint brightLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFA855F7).op(.16);

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _violetMid.op(.25);

    for (int i = 0; i < _dim.length; i++) {
      _trace(
        canvas,
        size,
        _dim[i],
        linePaint,
        dot: i < 2 ? dotPaint : null,
        dotRadius: 2.5,
      );
    }

    for (final trace in _bright) {
      _trace(
        canvas,
        size,
        trace,
        brightLinePaint,
        dot: dotPaint,
        dotRadius: 2,
      );
    }

    _diamond(
      canvas,
      Offset(
        size.width * .075,
        size.height * .38,
      ),
      4,
      brightLinePaint,
    );

    _diamond(
      canvas,
      Offset(
        size.width * .935,
        size.height * .38,
      ),
      4,
      brightLinePaint,
    );

    _diamond(
      canvas,
      Offset(
        size.width * .08,
        size.height * .66,
      ),
      3,
      linePaint,
    );

    _diamond(
      canvas,
      Offset(
        size.width * .92,
        size.height * .68,
      ),
      3,
      linePaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * .055,
        size.height * .58,
      ),
      3,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * .95,
        size.height * .30,
      ),
      3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// PARTICLE
// ================================================================

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.loops,
    required this.radius,
    required this.opacity,
    required this.phase,
  });

  final double x;
  final double y;
  final int loops;
  final double radius;
  final double opacity;
  final double phase;
}

// ================================================================
// BUILD PARTICLES
// ================================================================

List<_Particle> _buildParticles() {
  final math.Random random = math.Random(21);

  return List.generate(
    38,
    (_) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        loops: 1 + random.nextInt(2),
        radius: .7 + random.nextDouble() * 1.8,
        opacity: .12 + random.nextDouble() * .12,
        phase: random.nextDouble() * math.pi * 2,
      );
    },
  );
}

// ================================================================
// PARTICLE PAINTER
// ================================================================

class _AIParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _AIParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (final particle in particles) {
      final double y =
          ((particle.y -
                      progress * particle.loops) %
                  1.0) *
              size.height;

      final double x =
          particle.x * size.width +
              math.sin(
                    progress *
                            2 *
                            math.pi *
                            particle.loops +
                        particle.phase,
                  ) *
                  6;

      paint.color =
          _violet.op(particle.opacity);

      canvas.drawCircle(
        Offset(x, y),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _AIParticlePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ================================================================
// BOTTOM DECORATION
// ================================================================

class _BottomDecoration extends StatelessWidget {
  const _BottomDecoration();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool mobile = width < 700;

    return SizedBox(
      height: mobile ? 16 : 24,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          _BottomDot(
            size: mobile ? 4 : 5,
            opacity: 1,
          ),

          SizedBox(width: mobile ? 5 : 8),

          _BottomLine(
            width: mobile ? 22 : 38,
          ),

          SizedBox(width: mobile ? 5 : 8),

          _BottomDot(
            size: mobile ? 6 : 8,
            opacity: .65,
          ),

          SizedBox(width: mobile ? 5 : 8),

          _BottomLine(
            width: mobile ? 22 : 38,
          ),

          SizedBox(width: mobile ? 5 : 8),

          _BottomDot(
            size: mobile ? 4 : 5,
            opacity: 1,
          ),

          SizedBox(width: mobile ? 8 : 14),

          Container(
            width: mobile ? 25 : 42,
            height: 1,
            color: _violetLight.op(.18),
          ),

          SizedBox(width: mobile ? 6 : 10),

          Icon(
            Icons.auto_awesome_rounded,
            size: mobile ? 9 : 12,
            color: _violet.op(.35),
          ),

          SizedBox(width: mobile ? 6 : 10),

          Container(
            width: mobile ? 25 : 42,
            height: 1,
            color: _violetLight.op(.18),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BOTTOM DOT
// ================================================================

class _BottomDot extends StatelessWidget {
  final double size;
  final double opacity;

  const _BottomDot({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _violet.op(opacity),
      ),
    );
  }
}

// ================================================================
// BOTTOM LINE
// ================================================================

class _BottomLine extends StatelessWidget {
  final double width;

  const _BottomLine({
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: _violetLight.op(.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
