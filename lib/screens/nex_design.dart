
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ================================================================
// NEXLEARN — IMMERSIVE 3D GAME WORLD DESIGN SYSTEM
//
// Visual direction:
// 1. Purple atmospheric world backgrounds
// 2. Layered 3D game surfaces and dimensional shadows
// 3. Purple energy glow for interactive elements
// 4. Glass panels for AI-related components
// 5. Bold purple game badges
//
// No blue palette. No heavy dark-mode appearance.
// ================================================================

class NexColors {
  NexColors._();

  // Core brand
  static const Color ink = Color(0xFF2E1065);
  static const Color inkSoft = Color(0xFF5B21B6);

  static const Color violetDeep = Color(0xFF5B21B6);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetMid = Color(0xFF8B5CF6);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color lavender = Color(0xFFC4B5FD);
  static const Color lilac = Color(0xFFEDE9FE);
  static const Color mist = Color(0xFFF7F4FF);
  static const Color white = Color(0xFFFFFFFF);

  // Game-world surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF5F0FF);
  static const Color surfaceRaised = Color(0xFFFAF8FF);

  // Purple depth and outlines
  static const Color outline = Color(0xFF4C1D95);
  static const Color shadow = Color(0xFF6D28D9);
  static const Color glow = Color(0xFFB794F6);

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA78BFA),
      Color(0xFF8B5CF6),
      Color(0xFF6D28D9),
    ],
  );

  static const LinearGradient worldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF7FF),
      Color(0xFFF0E9FF),
      Color(0xFFE9DDFF),
      Color(0xFFF9F6FF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient raisedSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF7FF),
      Color(0xFFF0E8FF),
    ],
  );

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC4B5FD),
      Color(0xFF9F7AEA),
      Color(0xFF7C3AED),
    ],
  );
}

extension NexAlpha on Color {
  Color op(double opacity) => withOpacity(opacity);
}

// ================================================================
// 1. IMMERSIVE GAME-WORLD BACKGROUND
//
// Layered purple atmosphere, ambient light and optional isometric
// grid. Designed to sit behind normal Flutter screen content.
// ================================================================

class NexBackground extends StatelessWidget {
  const NexBackground({
    super.key,
    this.showGrid = false,
  });

  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NexColors.worldGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Large ambient light at the top.
          const _AuroraBlob(
            alignment: Alignment(-1.15, -1.0),
            size: 420,
            color: Color(0xFFC4B5FD),
            opacity: 0.42,
          ),

          // Purple light behind the main game content.
          const _AuroraBlob(
            alignment: Alignment(1.15, -0.25),
            size: 360,
            color: Color(0xFFA78BFA),
            opacity: 0.30,
          ),

          // Soft lower-world glow.
          const _AuroraBlob(
            alignment: Alignment(0.75, 1.1),
            size: 430,
            color: Color(0xFFD8B4FE),
            opacity: 0.35,
          ),

          // Very subtle central illumination.
          const _AuroraBlob(
            alignment: Alignment(-0.1, 0.2),
            size: 300,
            color: Color(0xFFFFFFFF),
            opacity: 0.72,
          ),

          if (showGrid)
            const Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GameWorldGridPainter(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  const _AuroraBlob({
    required this.alignment,
    required this.size,
    required this.color,
    this.opacity = 0.35,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double opacity;

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
            gradient: RadialGradient(
              colors: [
                color.op(opacity),
                color.op(opacity * 0.45),
                color.op(0),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ),
    );
  }
}

// A subtle perspective grid instead of a dotted or starry background.

class _GameWorldGridPainter extends CustomPainter {
  const _GameWorldGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = NexColors.violet.op(0.055)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double horizon = size.height * 0.57;

    // Horizontal lines become closer together near the horizon.
    for (int i = 1; i <= 12; i++) {
      final double progress = i / 12;
      final double y =
          horizon + (size.height - horizon) * progress * progress;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Perspective lines converge toward a central vanishing point.
    final Offset vanishingPoint = Offset(size.width * 0.5, horizon);

    for (int i = -8; i <= 8; i++) {
      final double x = size.width * 0.5 + i * size.width * 0.12;

      canvas.drawLine(
        vanishingPoint,
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// 2. DIMENSIONAL 3D GAME SURFACE
//
// Keeps the original ClayContainer API, but gives surfaces a more
// polished game-card appearance instead of a heavy clay effect.
// ================================================================

class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.gradient,
    this.color = Colors.white,
    this.radius = 24,
    this.borderRadius,
    this.depth = 8,
    this.pressed = false,
    this.padding,
    this.width,
    this.height,
    this.shadowColor = NexColors.violet,
  });

  final Widget child;
  final Gradient? gradient;
  final Color color;
  final double radius;
  final BorderRadius? borderRadius;
  final double depth;
  final bool pressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r =
        borderRadius ?? BorderRadius.circular(radius);

    final double effectiveDepth = pressed ? depth * 0.25 : depth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: r,
        border: Border.all(
          color: Colors.white.op(0.95),
          width: 1.4,
        ),
        boxShadow: [
          // Main dimensional shadow.
          BoxShadow(
            color: shadowColor.op(pressed ? 0.17 : 0.25),
            blurRadius: effectiveDepth * 2.2,
            offset: Offset(0, effectiveDepth),
          ),

          // Subtle purple ambient shadow.
          BoxShadow(
            color: NexColors.violet.op(pressed ? 0.04 : 0.09),
            blurRadius: effectiveDepth * 3.5,
            offset: Offset(0, effectiveDepth * 1.7),
          ),

          // Upper-left reflected light.
          BoxShadow(
            color: Colors.white.op(0.9),
            blurRadius: effectiveDepth * 0.9,
            offset: Offset(-effectiveDepth * 0.25, -effectiveDepth * 0.25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Glossy top lighting.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.op(pressed ? 0.10 : 0.42),
                        Colors.white.op(0.07),
                        Colors.white.op(0),
                      ],
                      stops: const [0, 0.18, 0.65],
                    ),
                  ),
                ),
              ),
            ),

            // Content stays above the decorative sheen.
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 3. INTERACTIVE GAME CONTROL
//
// Shared press, hover, keyboard activation, focus, haptics,
// semantics and subtle scale animation.
// ================================================================

class NexPressable extends StatefulWidget {
  const NexPressable({
    super.key,
    required this.onTap,
    required this.label,
    required this.builder,
    this.radius = 20,
    this.selected,
  });

  final VoidCallback onTap;
  final String label;
  final double radius;
  final bool? selected;

  final Widget Function(
    BuildContext context,
    bool pressed,
    bool active,
  ) builder;

  @override
  State<NexPressable> createState() => _NexPressableState();
}

class _NexPressableState extends State<NexPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _activate() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (value) {
        if (_hovered != value) {
          setState(() => _hovered = value);
        }
      },
      onShowFocusHighlight: (value) {
        if (_focused != value) {
          setState(() => _focused = value);
        }
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
        selected: widget.selected,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTap: _activate,
          child: AnimatedScale(
            scale: _pressed
                ? 0.965
                : _hovered
                    ? 1.025
                    : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: _focused
                    ? Border.all(
                        color: NexColors.violetDeep,
                        width: 2.2,
                      )
                    : null,
              ),
              child: widget.builder(
                context,
                _pressed,
                _hovered || _focused,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 4. AI GLASS PANEL
//
// Purple-tinted glass for NEX dialogue, AI suggestions, progress
// overlays and floating interface elements.
// ================================================================

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 22,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.blur = 16,
    this.tint = Colors.white,
  });

  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r =
        borderRadius ?? BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: NexColors.violetDeep.op(0.08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.op(0.82),
                  tint.op(0.60),
                  NexColors.lilac.op(0.35),
                ],
              ),
              border: Border.all(
                color: Colors.white.op(0.90),
                width: 1.3,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 5. PURPLE GAME BADGE
//
// Preserves BrutalTag's existing API while using a cleaner,
// dimensional purple sticker style.
// ================================================================

class BrutalTag extends StatelessWidget {
  const BrutalTag(
    this.text, {
    super.key,
    this.color = NexColors.lilac,
    this.rotate = -0.025,
    this.fontSize = 8,
  });

  final String text;
  final Color color;
  final double rotate;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize + 5,
          vertical: fontSize * 1.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: NexColors.violetDeep,
            width: 1.7,
          ),
          boxShadow: [
            BoxShadow(
              color: NexColors.violetDeep.op(0.75),
              offset: const Offset(3, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color: NexColors.violet.op(0.10),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.pressStart2p(
            fontSize: fontSize,
            color: NexColors.ink,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 6. REUSABLE PURPLE ENERGY BUTTON
//
// Optional new component for primary actions such as ENTER THE
// WORLD, START ADVENTURE and CONTINUE.
// ================================================================

class NexEnergyButton extends StatelessWidget {
  const NexEnergyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
    this.height = 58,
    this.fontSize = 11,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return NexPressable(
      onTap: onTap,
      label: label,
      radius: 19,
      builder: (context, pressed, active) {
        return ClayContainer(
          width: width,
          height: height,
          radius: 19,
          depth: 7,
          pressed: pressed,
          gradient: NexColors.violetGradient,
          shadowColor: NexColors.violetDeep,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white,
                    fontSize: fontSize,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// END OF NEXLEARN DESIGN SYSTEM
// ================================================================
