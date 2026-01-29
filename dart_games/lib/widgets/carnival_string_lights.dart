import 'package:flutter/material.dart';
import 'dart:math' as math;

class CarnivalStringLights extends StatefulWidget {
  const CarnivalStringLights({super.key});

  @override
  State<CarnivalStringLights> createState() => _CarnivalStringLightsState();
}

class _CarnivalStringLightsState extends State<CarnivalStringLights>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<double>> _glowAnimations;

  @override
  void initState() {
    super.initState();

    // Create 11 controllers (6 for left + 5 for right) with different delays
    _controllers = List.generate(11, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      // Start each bulb with a different delay for desynchronization (150ms offset each)
      Future.delayed(Duration(milliseconds: index * 150), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });

      return controller;
    });

    // Create opacity animations (pulse between 0.9 and 1.0 for 20% brighter)
    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Create glow animations (pulse the shadow spread - brighter)
    _glowAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 2.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        _opacityAnimations[index],
        _glowAnimations[index],
      ]),
      builder: (context, child) {
        final opacity = _opacityAnimations[index].value;
        final glowMultiplier = _glowAnimations[index].value;

        return Opacity(
          opacity: opacity,
          child: Container(
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
          ),
        );
      },
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
