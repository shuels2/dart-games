import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Tech/Neon background with circuit board pattern and pulsing concentric circles
/// Sits behind core screen content to create immersive arcade atmosphere
class TechNeonBackground extends StatefulWidget {
  const TechNeonBackground({super.key});

  @override
  State<TechNeonBackground> createState() => _TechNeonBackgroundState();
}

class _TechNeonBackgroundState extends State<TechNeonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for neon glow (repeats continuously)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Base background color
            Container(
              color: const Color(0xFF0D1B2A), // Deep navy blue
            ),

            // Circuit board grid pattern
            CustomPaint(
              size: Size.infinite,
              painter: CircuitBoardPainter(),
            ),

            // Neon concentric circles with offset pulsing glows
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(1200, 1200),
                    painter: NeonCirclesPainter(
                      animationValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // Target reticles positioned around the screen
            ..._buildTargetReticles(constraints),
          ],
        );
      },
    );
  }

  /// Build 5 target reticles of varying sizes positioned around the screen
  List<Widget> _buildTargetReticles(BoxConstraints constraints) {
    // Define reticle configurations: size, base position, and movement pattern
    final reticles = [
      {'size': 50.0, 'left': 0.15, 'top': 0.20, 'index': 0},
      {'size': 35.0, 'left': 0.80, 'top': 0.15, 'index': 1},
      {'size': 42.0, 'left': 0.10, 'top': 0.70, 'index': 2},
      {'size': 28.0, 'left': 0.75, 'top': 0.65, 'index': 3},
      {'size': 25.0, 'left': 0.50, 'top': 0.85, 'index': 4},
    ];

    return reticles.map((config) {
      return AnimatedReticle(
        size: config['size'] as double,
        baseLeft: constraints.maxWidth * (config['left'] as double),
        baseTop: constraints.maxHeight * (config['top'] as double),
        reticleIndex: config['index'] as int,
      );
    }).toList();
  }
}

/// Animated reticle that moves in a random pattern
class AnimatedReticle extends StatefulWidget {
  final double size;
  final double baseLeft;
  final double baseTop;
  final int reticleIndex;

  const AnimatedReticle({
    super.key,
    required this.size,
    required this.baseLeft,
    required this.baseTop,
    required this.reticleIndex,
  });

  @override
  State<AnimatedReticle> createState() => _AnimatedReticleState();
}

class _AnimatedReticleState extends State<AnimatedReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _moveController;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();

    // Each reticle has a different duration (30% slower than before)
    final baseDuration = 10400; // 10.4 seconds base (was 8 seconds)
    final durationVariation = widget.reticleIndex * 1300; // Add 0-5.2 seconds (was 1000ms)
    final duration = baseDuration + durationVariation;

    _moveController = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    )..repeat();

    _moveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _moveController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  /// Calculate offset based on reticle index to create unique patterns
  Offset _calculateOffset(double t) {
    // Add phase offset based on index to make each reticle start at different position
    final phaseOffset = widget.reticleIndex * 0.2;
    final adjustedT = (t + phaseOffset) % 1.0;

    // Different movement patterns for each reticle (larger paths - increased by ~25%)
    switch (widget.reticleIndex % 5) {
      case 0:
        // Circular pattern
        return Offset(
          math.cos(adjustedT * 2 * math.pi) * 150,
          math.sin(adjustedT * 2 * math.pi) * 150,
        );
      case 1:
        // Figure-8 pattern
        return Offset(
          math.sin(adjustedT * 2 * math.pi) * 140,
          math.sin(adjustedT * 4 * math.pi) * 115,
        );
      case 2:
        // Elliptical pattern
        return Offset(
          math.cos(adjustedT * 2 * math.pi) * 180,
          math.sin(adjustedT * 2 * math.pi) * 100,
        );
      case 3:
        // Drift pattern
        return Offset(
          math.sin(adjustedT * 2 * math.pi) * 130,
          math.cos(adjustedT * 2 * math.pi) * 145,
        );
      case 4:
        // Diagonal sweep pattern
        return Offset(
          math.cos(adjustedT * 2 * math.pi + math.pi / 4) * 165,
          math.sin(adjustedT * 2 * math.pi + math.pi / 4) * 165,
        );
      default:
        return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _moveAnimation,
      builder: (context, child) {
        final offset = _calculateOffset(_moveAnimation.value);
        return Positioned(
          left: widget.baseLeft + offset.dx,
          top: widget.baseTop + offset.dy,
          child: TargetReticle(size: widget.size),
        );
      },
    );
  }
}

/// Small neon targeting reticle with yellow crosshairs and magenta/cyan ring
class TargetReticle extends StatelessWidget {
  final double size;

  const TargetReticle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ReticlePainter(size: size),
      ),
    );
  }
}

/// Painter for target reticle
class ReticlePainter extends CustomPainter {
  final double size;

  ReticlePainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final innerCircleRadius = size * 0.15; // Inner yellow circle radius
    final crosshairGap = innerCircleRadius + 3; // Gap between crosshair and inner circle

    // Colors with higher opacity than background circles
    const neonMagenta = Color(0xFFFF007F);
    const neonCyan = Color(0xFF00F2FF);
    const brightYellow = Color(0xFFFFFF00);

    // Draw dual-tone ring (magenta and cyan) with higher opacity
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw magenta half (top half)
    ringPaint.color = neonMagenta.withOpacity(0.5); // Increased from 1.0
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2, // Start at top
      math.pi, // 180 degrees
      false,
      ringPaint,
    );

    // Draw cyan half (bottom half)
    ringPaint.color = neonCyan.withOpacity(0.5); // Increased from 1.0
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi / 2, // Start at bottom
      math.pi, // 180 degrees
      false,
      ringPaint,
    );

    // Add stronger glow to rings
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    glowPaint.color = neonMagenta.withOpacity(0.4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      math.pi,
      false,
      glowPaint,
    );

    glowPaint.color = neonCyan.withOpacity(0.4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi / 2,
      math.pi,
      false,
      glowPaint,
    );

    // Draw inner yellow circle (solid)
    final innerCircleFillPaint = Paint()
      ..color = brightYellow.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerCircleRadius, innerCircleFillPaint);

    // Add stroke to inner circle
    final innerCircleStrokePaint = Paint()
      ..color = brightYellow.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, innerCircleRadius, innerCircleStrokePaint);

    // Add glow to inner circle
    final innerCircleGlowPaint = Paint()
      ..color = brightYellow.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(center, innerCircleRadius, innerCircleGlowPaint);

    // Draw yellow crosshairs with gap around inner circle
    final crosshairPaint = Paint()
      ..color = brightYellow.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontal line (left side)
    canvas.drawLine(
      Offset(-2, center.dy),
      Offset(center.dx - crosshairGap, center.dy),
      crosshairPaint,
    );

    // Horizontal line (right side)
    canvas.drawLine(
      Offset(center.dx + crosshairGap, center.dy),
      Offset(size + 2, center.dy),
      crosshairPaint,
    );

    // Vertical line (top side)
    canvas.drawLine(
      Offset(center.dx, -2),
      Offset(center.dx, center.dy - crosshairGap),
      crosshairPaint,
    );

    // Vertical line (bottom side)
    canvas.drawLine(
      Offset(center.dx, center.dy + crosshairGap),
      Offset(center.dx, size + 2),
      crosshairPaint,
    );

    // Add glow to crosshairs
    final crosshairGlowPaint = Paint()
      ..color = brightYellow.withOpacity(0.35)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Horizontal glow (left)
    canvas.drawLine(
      Offset(-2, center.dy),
      Offset(center.dx - crosshairGap, center.dy),
      crosshairGlowPaint,
    );

    // Horizontal glow (right)
    canvas.drawLine(
      Offset(center.dx + crosshairGap, center.dy),
      Offset(size + 2, center.dy),
      crosshairGlowPaint,
    );

    // Vertical glow (top)
    canvas.drawLine(
      Offset(center.dx, -2),
      Offset(center.dx, center.dy - crosshairGap),
      crosshairGlowPaint,
    );

    // Vertical glow (bottom)
    canvas.drawLine(
      Offset(center.dx, center.dy + crosshairGap),
      Offset(center.dx, size + 2),
      crosshairGlowPaint,
    );

    // Draw 4 corner dots at 12, 3, 6, 9 o'clock positions
    final dotPaint = Paint()
      ..color = brightYellow.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final dotSize = size * 0.08; // 8% of reticle size
    final dotDistance = radius + 4; // Just outside the ring

    // 12 o'clock (top)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - dotDistance),
        width: dotSize,
        height: dotSize,
      ),
      dotPaint,
    );

    // 3 o'clock (right)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + dotDistance, center.dy),
        width: dotSize,
        height: dotSize,
      ),
      dotPaint,
    );

    // 6 o'clock (bottom)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + dotDistance),
        width: dotSize,
        height: dotSize,
      ),
      dotPaint,
    );

    // 9 o'clock (left)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - dotDistance, center.dy),
        width: dotSize,
        height: dotSize,
      ),
      dotPaint,
    );

    // Add glow to dots
    final dotGlowPaint = Paint()
      ..color = brightYellow.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - dotDistance),
        width: dotSize + 2,
        height: dotSize + 2,
      ),
      dotGlowPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + dotDistance, center.dy),
        width: dotSize + 2,
        height: dotSize + 2,
      ),
      dotGlowPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + dotDistance),
        width: dotSize + 2,
        height: dotSize + 2,
      ),
      dotGlowPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - dotDistance, center.dy),
        width: dotSize + 2,
        height: dotSize + 2,
      ),
      dotGlowPaint,
    );
  }

  @override
  bool shouldRepaint(ReticlePainter oldDelegate) => false;
}

/// Painter for circuit board grid pattern
class CircuitBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFA3).withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    const gridSpacing = 40.0;
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Add random "traces" (diagonal lines) for PCB effect
    final tracePaint = Paint()
      ..color = const Color(0xFF00FFA3).withOpacity(0.08)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Fixed seed for consistency
    for (int i = 0; i < 20; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = x1 + (random.nextDouble() - 0.5) * 200;
      final y2 = y1 + (random.nextDouble() - 0.5) * 200;

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        tracePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for neon concentric circles with offset pulsing glows
class NeonCirclesPainter extends CustomPainter {
  final double animationValue;

  NeonCirclesPainter({required this.animationValue});

  /// Calculate pulse value for a specific ring with offset
  double _calculateRingPulse(int ringIndex, int totalRings) {
    // Each ring has a phase offset based on its index
    final phaseOffset = (ringIndex / totalRings);

    // Calculate the pulse value for this ring (0.0 to 1.0 and back)
    final adjustedValue = (animationValue + phaseOffset) % 1.0;

    // Use a sine wave for smooth pulsing
    final pulse = (math.sin(adjustedValue * 2 * math.pi) + 1) / 2;

    // Scale from 0.5 to 1.0 (so glow varies but never fully dims)
    return 0.5 + (pulse * 0.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Colors for alternating rings
    const neonPink = Color(0xFFFF007A);
    const neonCyan = Color(0xFF00FFA3);

    // Draw 10 concentric circles to fill the screen
    const ringCount = 10;
    const baseRadius = 80.0;
    const ringSpacing = 65.0;

    for (int i = 0; i < ringCount; i++) {
      // Static radius at max size
      final radius = baseRadius + (i * ringSpacing);
      final color = i % 2 == 0 ? neonPink : neonCyan;

      // Get the pulse value for this specific ring
      final ringPulse = _calculateRingPulse(i, ringCount);

      // Main ring stroke (constant)
      final ringPaint = Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius, ringPaint);

      // Outer glow (pulsing) - this is what creates the pulsing effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.1 * ringPulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * ringPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0;

      canvas.drawCircle(center, radius, glowPaint);

      // Inner glow (pulsing)
      final innerGlowPaint = Paint()
        ..color = color.withOpacity(0.15 * ringPulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * ringPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0;

      canvas.drawCircle(center, radius, innerGlowPaint);
    }

    // Central bright spot (also pulsing with its own offset)
    final centralPulse = _calculateRingPulse(0, ringCount);
    final centralGlow = Paint()
      ..color = neonPink.withOpacity(0.35 * centralPulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25 * centralPulse)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 40, centralGlow);
  }

  @override
  bool shouldRepaint(NeonCirclesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
