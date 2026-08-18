import 'package:flutter/material.dart';

import 'pulse_animation.dart';
import 'dart:math' as math;

class CarnivalStringLights extends StatefulWidget {
  const CarnivalStringLights({super.key});

  @override
  State<CarnivalStringLights> createState() => _CarnivalStringLightsState();
}

class _CarnivalStringLightsState extends State<CarnivalStringLights>
    with TickerProviderStateMixin {
  /// Number of bulbs (6 on the left string, 5 on the right).
  static const int _bulbCount = 11;

  /// Phase offset between adjacent bulbs, as a fraction of one cycle.
  ///
  /// The original used a 150ms `Future.delayed` per bulb against a 2000ms
  /// cycle; 150/2000 = 0.075 reproduces the same visual stagger exactly,
  /// but as a curve offset instead of eleven independently-started tickers.
  static const double _phaseStep = 150 / 2000;

  /// ONE controller drives all eleven bulbs (WS04 4.8).
  ///
  /// There used to be eleven `AnimationController`s, each with its own ticker
  /// registered with the scheduler, each rebuilding its own subtree every
  /// frame — on a decorative background element that is never interacted
  /// with. The stagger came from starting them at 150ms intervals, which also
  /// meant eleven pending `Future.delayed` callbacks racing widget disposal.
  ///
  /// Now: one ticker, and each bulb reads it through a phase-shifted curve.
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnimations;
  late final List<Animation<double>> _glowAnimations;

  /// A 0..1 sawtooth for [index], phase-shifted then folded into a
  /// there-and-back ramp so it matches the old `repeat(reverse: true)`.
  Animation<double> _phased(int index, {required double begin, required double end}) {
    return PulseAnimation(
      parent: _controller,
      phase: (index * _phaseStep) % 1.0,
    ).drive(
      Tween<double>(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOut)),
    );
  }

  @override
  void initState() {
    super.initState();

    // reverse:true is not used — _PhaseShiftedAnimation folds the ramp
    // itself, so every bulb can share one monotonically repeating cycle.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _opacityAnimations = List.generate(
        _bulbCount, (i) => _phased(i, begin: 0.9, end: 1.0));
    _glowAnimations = List.generate(
        _bulbCount, (i) => _phased(i, begin: 1.0, end: 2.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, // Start at the very top with the AppBar
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: 310,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _WirePainter(),
                child: Stack(
                  children: [
                    // Left side bulbs (6 bulbs)
                    ...List.generate(6, (index) {
                      final position = _calculateLeftBulbPosition(index, 6, constraints.maxWidth);
                      return Positioned(
                        left: position.dx,
                        top: position.dy,
                        child: _buildBulb(index),
                      );
                    }),
                    // Right side bulbs (5 bulbs)
                    ...List.generate(5, (index) {
                      final position = _calculateRightBulbPosition(index, 5, constraints.maxWidth);
                      return Positioned(
                        left: position.dx,
                        top: position.dy,
                        child: _buildBulb(index + 6),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Offset _calculateLeftBulbPosition(int index, int total, double screenWidth) {
    // Left side: from 150px right of center to left edge
    final double centerX = screenWidth / 2;
    final double startX = centerX + 150; // Start 150px right of center
    final double progress = index / (total - 1); // 0.0 at start to 1.0 at edge
    final double x = startX - (startX * progress); // startX to 0

    // Start at top (y=0) and sag DOWN with smooth convex curve
    final double appBarHeight = 0.0;
    final double maxSag = 125.0;
    // Use sine for smooth curve without sharp angles
    final double sag = appBarHeight + (maxSag * math.sin(progress * math.pi / 2));

    return Offset(x, sag);
  }

  Offset _calculateRightBulbPosition(int index, int total, double screenWidth) {
    // Right side: from 20px left of center to right edge
    final double centerX = screenWidth / 2;
    final double startX = centerX - 20; // Start 20px left of center
    final double endX = screenWidth;
    final double progress = index / (total - 1); // 0.0 at start to 1.0 at edge
    final double x = startX + ((endX - startX) * progress); // startX to width

    // Start at top (y=0) and sag DOWN with smooth convex curve - endpoint 200px lower
    final double appBarHeight = 0.0;
    final double maxSag = 295.0; // Increased from 95 to 295 (200px lower)
    // Use sine for smooth curve without sharp angles
    final double sag = appBarHeight + (maxSag * math.sin(progress * math.pi / 2));

    return Offset(x, sag);
  }

  Widget _buildBulb(int index) {
    // RepaintBoundary isolates per-bulb repaints from the wider tree.
    // FadeTransition replaces the per-frame Opacity-saveLayer; an inner
    // AnimatedBuilder still drives the glow's BoxShadow since blur/spread
    // depend on the controller value.
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacityAnimations[index],
        child: AnimatedBuilder(
          animation: _glowAnimations[index],
          builder: (context, child) {
            final glowMultiplier = _glowAnimations[index].value;
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.8,
                  colors: [
                    Colors.white,
                    Color(0xFFFFD700),
                    Color(0xFFFFD700),
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700),
                    blurRadius: 15 * glowMultiplier,
                    spreadRadius: 2 * glowMultiplier,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 30 * glowMultiplier,
                    spreadRadius: 4 * glowMultiplier,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    blurRadius: 45 * glowMultiplier,
                    spreadRadius: 6 * glowMultiplier,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final double appBarHeight = 0.0;

    // Draw left wire (150px right of center to left edge) - sagging DOWN with smooth convex curve
    final double leftStartX = centerX + 150;
    final leftPath = Path();
    leftPath.moveTo(leftStartX, appBarHeight); // Start 150px right of center

    final int leftSegments = 30;
    for (int i = 0; i <= leftSegments; i++) {
      final double progress = i / leftSegments;
      final double x = leftStartX - (leftStartX * progress); // startX to 0
      final double maxSag = 125.0;
      // Smooth sine curve - no sharp angles
      final double y = appBarHeight + (maxSag * math.sin(progress * math.pi / 2));
      leftPath.lineTo(x, y);
    }

    canvas.drawPath(leftPath, paint);

    // Draw right wire (20px left of center to right edge) - sagging DOWN with smooth convex curve
    final double rightStartX = centerX - 20;
    final rightPath = Path();
    rightPath.moveTo(rightStartX, appBarHeight); // Start 20px left of center

    final int rightSegments = 30;
    for (int i = 0; i <= rightSegments; i++) {
      final double progress = i / rightSegments;
      final double x = rightStartX + ((size.width - rightStartX) * progress); // startX to width
      final double maxSag = 295.0; // Increased from 95 to 295 (200px lower)
      // Smooth sine curve - no sharp angles
      final double y = appBarHeight + (maxSag * math.sin(progress * math.pi / 2));
      rightPath.lineTo(x, y);
    }

    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
