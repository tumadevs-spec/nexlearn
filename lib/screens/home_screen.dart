import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'age_screen.dart';

const String _nexImage = 'assets/images/robots/nex.png';

// ----------------------------------------------------------------
// Palette
// ----------------------------------------------------------------

const Color _violetDark = Color(0xFF3B0764);
const Color _violet = Color(0xFF7C3AED);
const Color _violetMid = Color(0xFF8B5CF6);
const Color _violetLight = Color(0xFFA78BFA);

extension _Alpha on Color {
  Color op(double o) => withOpacity(o);
}

// ================================================================
// MOTION BUNDLE
// ================================================================

class _Motion {
  const _Motion({
    required this.float,
    required this.pulse,
    required this.orbit,
    required this.intro,
  });

  final Animation<double> float;
  final Animation<double> pulse;
  final Animation<double> orbit;
  final Animation<double> intro;
}

// ================================================================
// HOME SCREEN
// ================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final AnimationController _introController;

  late final List<_Particle> _particles;
  late final _Motion _motion;

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

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _motion = _Motion(
      float: _floatController,
      pulse: _pulseController,
      orbit: _orbitController,
      intro: _introController,
    );
  }

  // Respect the system "reduce motion" setting.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bool reduce = MediaQuery.disableAnimationsOf(context);

    if (reduce) {
      _floatController.stop();
      _pulseController.stop();
      _particleController.stop();
      _orbitController.stop();
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

      if (!_orbitController.isAnimating) {
        _orbitController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _introController.dispose();

    super.dispose();
  }

  void _openPlay() {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => const AgeScreen(),
        transitionsBuilder: (_, animation, __, child) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool mobile = width < 700;
          final bool smallHeight = height < 650;

          return Stack(
            fit: StackFit.expand,
            children: [
              const _AIBackground(),

              // Floating particles
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

              const Positioned.fill(
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProfessionalDecorationPainter(),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 18 : 38,
                    vertical: mobile ? 12 : 20,
                  ),
                  child: Column(
                    children: [
                      // TOP BAR REMOVED
                      //
                      // No NEXLEARN logo
                      // No AI GAME WORLD
                      // No robot icon

                      Expanded(
                        child: mobile
                            ? _MobileHero(
                                motion: _motion,
                                onPlay: _openPlay,
                                smallHeight: smallHeight,
                              )
                            : _DesktopHero(
                                motion: _motion,
                                onPlay: _openPlay,
                                smallHeight: smallHeight,
                              ),
                      ),

                      if (!smallHeight || mobile)
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
// REVEAL
// ================================================================

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.dy = 20,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final double dy;
  final Widget child;

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
        final double t = interval.transform(animation.value);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

// ================================================================
// BACKGROUND
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
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(
            alignment: Alignment(-1.15, -0.85),
            size: 320,
            color: Color(0xFFC4B5FD),
          ),
          _GlowBlob(
            alignment: Alignment(1.1, -0.55),
            size: 300,
            color: Color(0xFFA78BFA),
          ),
          _GlowBlob(
            alignment: Alignment(0.9, 1.0),
            size: 360,
            color: Color(0xFFE9D5FF),
          ),
        ],
      ),
    );
  }
}

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

class _CircuitBackgroundPainter extends CustomPainter {
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

    for (double x = 0; x < size.width; x += grid) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    for (double y = 0; y < size.height; y += grid) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    for (double x = grid; x < size.width; x += grid * 2) {
      for (double y = grid; y < size.height; y += grid * 2) {
        canvas.drawCircle(
          Offset(x, y),
          2.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// PROFESSIONAL DECORATION
// ================================================================

class _ProfessionalDecorationPainter extends CustomPainter {
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
    Offset at(int i) => Offset(
          size.width * p[i * 2],
          size.height * p[i * 2 + 1],
        );

    final Path path = Path()
      ..moveTo(at(0).dx, at(0).dy);

    for (int i = 1; i < 4; i++) {
      path.lineTo(at(i).dx, at(i).dy);
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

    for (final t in _bright) {
      _trace(
        canvas,
        size,
        t,
        brightLinePaint,
        dot: dotPaint,
        dotRadius: 2,
      );
    }

    _diamond(
      canvas,
      Offset(size.width * .075, size.height * .38),
      4,
      brightLinePaint,
    );

    _diamond(
      canvas,
      Offset(size.width * .935, size.height * .38),
      4,
      brightLinePaint,
    );

    _diamond(
      canvas,
      Offset(size.width * .08, size.height * .66),
      3,
      linePaint,
    );

    _diamond(
      canvas,
      Offset(size.width * .92, size.height * .68),
      3,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width * .055, size.height * .58),
      3,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(size.width * .95, size.height * .30),
      3,
      dotPaint,
    );
  }

  void _diamond(
    Canvas canvas,
    Offset c,
    double r,
    Paint paint,
  ) {
    final Path path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// PARTICLES
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

List<_Particle> _buildParticles() {
  final math.Random r = math.Random(21);

  return List.generate(38, (_) {
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      loops: 1 + r.nextInt(2),
      radius: .7 + r.nextDouble() * 1.8,
      opacity: .12 + r.nextDouble() * .12,
      phase: r.nextDouble() * math.pi * 2,
    );
  });
}

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

    for (final p in particles) {
      final double y =
          ((p.y - progress * p.loops) % 1.0) * size.height;

      final double x = p.x * size.width +
          math.sin(
                progress * 2 * math.pi * p.loops + p.phase,
              ) *
              6;

      paint.color = _violet.op(p.opacity);

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AIParticlePainter old) =>
      old.progress != progress;
}

// ================================================================
// DESKTOP / MOBILE HERO
// ================================================================

class _DesktopHero extends StatelessWidget {
  final _Motion motion;
  final VoidCallback onPlay;
  final bool smallHeight;

  const _DesktopHero({
    required this.motion,
    required this.onPlay,
    required this.smallHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 46,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _HeroText(
              intro: motion.intro,
              onPlay: onPlay,
              smallHeight: smallHeight,
              centered: false,
              verySmall: false,
            ),
          ),
        ),
        Expanded(
          flex: 54,
          child: _RobotScene(
            motion: motion,
            smallHeight: smallHeight,
          ),
        ),
      ],
    );
  }
}

class _MobileHero extends StatelessWidget {
  final _Motion motion;
  final VoidCallback onPlay;
  final bool smallHeight;

  const _MobileHero({
    required this.motion,
    required this.onPlay,
    required this.smallHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool verySmall = constraints.maxHeight < 520;

        return Column(
          children: [
            Expanded(
              flex: verySmall ? 52 : 57,
              child: _RobotScene(
                motion: motion,
                smallHeight: smallHeight || verySmall,
              ),
            ),
            Expanded(
              flex: verySmall ? 48 : 43,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: _HeroText(
                  intro: motion.intro,
                  onPlay: onPlay,
                  smallHeight: smallHeight || verySmall,
                  centered: true,
                  verySmall: verySmall,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// HERO TEXT
// ================================================================

class _HeroText extends StatelessWidget {
  final Animation<double> intro;
  final VoidCallback onPlay;
  final bool smallHeight;
  final bool centered;
  final bool verySmall;

  const _HeroText({
    required this.intro,
    required this.onPlay,
    required this.smallHeight,
    this.centered = false,
    this.verySmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = verySmall
        ? 16
        : smallHeight
            ? 19
            : 28;

    final double subtitleSize = verySmall
        ? 10
        : smallHeight
            ? 12
            : 14;

    final TextAlign align =
        centered ? TextAlign.center : TextAlign.left;

    final TextStyle titleStyle = GoogleFonts.pressStart2p(
      color: _violetDark,
      fontSize: titleSize,
      height: 1.25,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 490),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _Reveal(
            animation: intro,
            start: 0.0,
            end: 0.6,
            child: Semantics(
              header: true,
              label: 'Your AI adventure starts here.',
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  style: titleStyle,
                  children: const [
                    TextSpan(text: 'YOUR AI\n'),
                    TextSpan(
                      text: 'ADVENTURE\n',
                      style: TextStyle(
                        color: _violet,
                      ),
                    ),
                    TextSpan(
                      text: 'STARTS HERE.',
                    ),
                  ],
                ),
                textAlign: align,
              ),
            ),
          ),

          SizedBox(
            height: verySmall
                ? 5
                : smallHeight
                    ? 8
                    : 16,
          ),

          _Reveal(
            animation: intro,
            start: 0.15,
            end: 0.75,
            child: Text(
              'Meet NEXI — your little AI learning companion.',
              textAlign: align,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _violet,
                fontSize: subtitleSize,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),

          SizedBox(
            height: verySmall
                ? 7
                : smallHeight
                    ? 10
                    : 24,
          ),

          _Reveal(
            animation: intro,
            start: 0.3,
            end: 0.9,
            child: _PlayButton(
              onTap: onPlay,
              compact: smallHeight || verySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PLAY BUTTON
// ================================================================

class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;

  const _PlayButton({
    required this.onTap,
    required this.compact,
  });

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool hovered = false;
  bool pressed = false;
  bool focused = false;

  void _activate() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.compact ? 52 : 62;
    final double width = widget.compact ? 205 : 235;

    final bool active = hovered || focused;

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,

      onShowHoverHighlight: (v) {
        setState(() => hovered = v);
      },

      onShowFocusHighlight: (v) {
        setState(() => focused = v);
      },

      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },

      child: Semantics(
        button: true,
        label: "Let's play",
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => pressed = true);
          },
          onTapCancel: () {
            setState(() => pressed = false);
          },
          onTapUp: (_) {
            setState(() => pressed = false);
          },
          onTap: _activate,

          child: AnimatedScale(
            scale: pressed
                ? .97
                : active
                    ? 1.04
                    : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: width,
              height: height,

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6D28D9),
                    _violet,
                    _violetMid,
                  ],
                ),

                borderRadius: BorderRadius.circular(19),

                border: Border.all(
                  color: focused
                      ? _violetDark
                      : Colors.white.op(.6),
                  width: focused ? 2.5 : 1.2,
                ),

                boxShadow: [
                  BoxShadow(
                    color: _violet.op(.32),
                    blurRadius: active ? 32 : 23,
                    spreadRadius: active ? 3 : 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: widget.compact ? 34 : 39,
                    height: widget.compact ? 34 : 39,
                    decoration: BoxDecoration(
                      color: Colors.white.op(.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: widget.compact ? 22 : 25,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Text(
                    "LET'S PLAY",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white,
                      fontSize: widget.compact ? 8 : 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ROBOT SCENE
// ================================================================

class _RobotScene extends StatelessWidget {
  final _Motion motion;
  final bool smallHeight;

  const _RobotScene({
    required this.motion,
    required this.smallHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        final double robotWidth = math.min(
          math.min(
            availableWidth * .78,
            smallHeight ? 390.0 : 520.0,
          ),
          availableHeight * .95,
        );

        final double bubbleAlign =
            availableWidth < 400 ? .95 : .85;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // HALO
            AnimatedBuilder(
              animation: motion.pulse,
              builder: (context, _) {
                final double pulse =
                    1.0 +
                        math.sin(
                              motion.pulse.value * math.pi,
                            ) *
                            .025;

                return _RobotHalo(
                  width: robotWidth * 1.12,
                  height: math.min(
                    availableHeight * .68,
                    robotWidth * 1.12,
                  ),
                  pulse: pulse,
                );
              },
            ),

            // ORBIT
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: motion.orbit,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(
                      robotWidth * .86,
                      robotWidth * .86 * .62,
                    ),
                    painter: _OrbitPainter(
                      progress: motion.orbit.value,
                    ),
                  );
                },
              ),
            ),

            // NEX
            _Reveal(
              animation: motion.intro,
              start: 0.1,
              end: 0.85,
              dy: 28,
              child: AnimatedBuilder(
                animation: motion.float,
                child: Semantics(
                  label: 'NEX, the AI learning robot',
                  image: true,
                  child: SizedBox(
                    width: robotWidth,
                    child: Image.asset(
                      _nexImage,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _FallbackRobot(
                          size: robotWidth,
                        );
                      },
                    ),
                  ),
                ),
                builder: (context, child) {
                  final double floatOffset =
                      math.sin(
                            motion.float.value * math.pi,
                          ) *
                          (smallHeight ? 5.0 : 10.0);

                  return Transform.translate(
                    offset: Offset(0, -floatOffset),
                    child: child,
                  );
                },
              ),
            ),

            // SPEECH BUBBLE
            if (!smallHeight)
              Align(
                alignment: Alignment(
                  bubbleAlign,
                  -.78,
                ),
                child: _Reveal(
                  animation: motion.intro,
                  start: 0.6,
                  end: 1.0,
                  dy: 10,
                  child: const _SpeechBubble(),
                ),
              ),

            Positioned(
              top: availableHeight * .20,
              left: availableWidth * .14,
              child: const _TinyNode(),
            ),

            Positioned(
              bottom: availableHeight * .23,
              right: availableWidth * .13,
              child: const _TinyNode(),
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// SPEECH BUBBLE
// ================================================================

class _SpeechBubble extends StatefulWidget {
  const _SpeechBubble();

  @override
  State<_SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<_SpeechBubble> {
  static const List<String> _messages = [
    "Hi, I'm NEXI! 👋",
    'Ready to learn?',
    "Let's play a game!",
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (mounted) {
          setState(() {
            _index = (_index + 1) % _messages.length;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.op(.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _violetLight.op(.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _violet.op(.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _messages[_index],
                key: ValueKey<int>(_index),
                style: GoogleFonts.poppins(
                  color: _violetDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _BubbleTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * .3, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.op(.94),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}

// ================================================================
// ROBOT HALO
// ================================================================

class _RobotHalo extends StatelessWidget {
  final double width;
  final double height;
  final double pulse;

  const _RobotHalo({
    required this.width,
    required this.height,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFC4B5FD).op(.60),
              _violetLight.op(.30),
              Colors.transparent,
            ],
            stops: const [0, .58, 1],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ORBIT
// ================================================================

class _OrbitPainter extends CustomPainter {
  final double progress;

  _OrbitPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double rx = size.width / 2;
    final double ry = rx * .58;

    canvas.save();

    canvas.translate(
      size.width / 2,
      size.height / 2,
    );

    canvas.rotate(
      -.12 +
          math.sin(
                progress * 2 * math.pi,
              ) *
              .05,
    );

    // Ring
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _violet.op(.20),
    );

    // Dots
    for (int i = 0; i < 4; i++) {
      final bool small = i.isOdd;

      final double angle =
          progress * 2 * math.pi +
              i * math.pi / 2;

      final Offset pos = Offset(
        math.cos(angle) * rx,
        math.sin(angle) * ry,
      );

      final double r = small ? 2.75 : 4.5;

      canvas.drawCircle(
        pos,
        r * 1.9,
        Paint()
          ..color =
              _violet.op(small ? .25 : .35)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            small ? 4 : 6,
          ),
      );

      canvas.drawCircle(
        pos,
        r,
        Paint()..color = _violet,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _OrbitPainter old,
  ) =>
      old.progress != progress;
}

// ================================================================
// TINY DECORATIVE NODE
// ================================================================

class _TinyNode extends StatelessWidget {
  const _TinyNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _violetMid.op(.55),
        boxShadow: [
          BoxShadow(
            color: _violetMid.op(.28),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FALLBACK ROBOT
// ================================================================

class _FallbackRobot extends StatelessWidget {
  final double size;

  const _FallbackRobot({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double robotSize =
        math.min(size * .48, 220.0);

    return Center(
      child: Container(
        width: robotSize,
        height: robotSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(robotSize * .18),
          border: Border.all(
            color: const Color(0xFFD8B4FE),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _violet.op(.18),
              blurRadius: 35,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                _RobotEye(),
                SizedBox(width: 22),
                _RobotEye(),
              ],
            ),
            SizedBox(height: 18),
            Icon(
              Icons.smart_toy_rounded,
              color: _violet,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotEye extends StatelessWidget {
  const _RobotEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _violet,
      ),
    );
  }
}

// ================================================================
// BOTTOM DECORATION
// ================================================================

class _BottomDecoration extends StatelessWidget {
  const _BottomDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const _BottomDot(
            size: 5,
            opacity: 1,
          ),
          const SizedBox(width: 8),
          const _BottomLine(width: 38),
          const SizedBox(width: 8),
          const _BottomDot(
            size: 8,
            opacity: .65,
          ),
          const SizedBox(width: 8),
          const _BottomLine(width: 38),
          const SizedBox(width: 8),
          const _BottomDot(
            size: 5,
            opacity: 1,
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 1,
            color: _violetLight.op(.18),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: _violet.op(.35),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 1,
            color: _violetLight.op(.18),
          ),
        ],
      ),
    );
  }
}

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
        borderRadius:
            BorderRadius.circular(10),
      ),
    );
  }
}