import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Interactive dartboard widget that detects clicks on different segments
class InteractiveDartboard extends StatefulWidget {
  final Function(int score, String multiplier, int baseScore, Offset position) onDartThrow;
  final double size;
  final VoidCallback? onRemoveDarts;

  const InteractiveDartboard({
    super.key,
    required this.onDartThrow,
    this.size = 300,
    this.onRemoveDarts,
  });

  @override
  State<InteractiveDartboard> createState() => InteractiveDartboardState();
}

class InteractiveDartboardState extends State<InteractiveDartboard> {
  // Store normalized positions (0.0-1.0) so they scale with dartboard size
  final List<Offset> dartPositions = [];

  // Standard dartboard number sequence (clockwise from top)
  static const List<int> dartboardNumbers = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  void removeDarts() {
    setState(() {
      dartPositions.clear();
    });
    widget.onRemoveDarts?.call();
  }

  /// Remove a single dart from the board
  /// Returns true if a dart was removed, false if board is empty
  bool removeSingleDart() {
    if (dartPositions.isEmpty) {
      return false;
    }
    setState(() {
      dartPositions.removeLast();
    });
    return true;
  }

  /// Get the current number of darts on the board
  int get dartCount => dartPositions.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the actual rendered size (might be smaller than widget.size)
        final actualSize = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          widget.size,
        );

        return GestureDetector(
          onTapDown: (details) => _handleTap(details.localPosition, actualSize),
          child: SizedBox(
            width: actualSize,
            height: actualSize,
            child: CustomPaint(
              size: Size(actualSize, actualSize),
              painter: DartboardPainter(
                dartPositions: List.from(dartPositions),
                dartboardSize: actualSize,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset position, double actualSize) {
    final center = Offset(actualSize / 2, actualSize / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = actualSize / 2;

    // Add dart position to the list (normalized to 0.0-1.0 range)
    setState(() {
      dartPositions.add(Offset(position.dx / actualSize, position.dy / actualSize));
    });

    // Calculate angle from center (atan2 gives angle in radians)
    // In Flutter canvas: 0 = right, π/2 = down, π = left, 3π/2 = up
    // Angles increase clockwise
    double angle = math.atan2(dy, dx);

    // Determine which segment was hit
    // Segment i is centered at: i * segmentAngle - π/2
    // So: i = (angle + π/2) / segmentAngle
    final segmentAngle = (2 * math.pi) / 20;
    int segmentIndex = (((angle + math.pi / 2) / segmentAngle).round()) % 20;
    if (segmentIndex < 0) segmentIndex += 20;

    int baseScore = dartboardNumbers[segmentIndex];
    int finalScore;
    String multiplier;

    // Determine multiplier and calculate final score based on distance from center
    // Triple and double rings are now 2x wider
    if (distance < radius * 0.037) {
      // Bullseye / Inner bull (50 points)
      multiplier = 'bullseye';
      finalScore = 50;
      baseScore = 50; // For bullseye
    } else if (distance < radius * 0.094) {
      // Outer bull (25 points)
      multiplier = 'outer_bull';
      finalScore = 25;
      baseScore = 25; // For outer bull
    } else if (distance < radius * 0.582) {
      // Inner single
      multiplier = 'single';
      finalScore = baseScore;
    } else if (distance < radius * 0.676) {
      // Triple ring (2x width: 0.094 instead of 0.047)
      multiplier = 'triple';
      finalScore = baseScore * 3;
    } else if (distance < radius * 0.906) {
      // Outer single
      multiplier = 'single';
      finalScore = baseScore;
    } else if (distance < radius) {
      // Double ring (2x width: 0.094 instead of 0.047)
      multiplier = 'double';
      finalScore = baseScore * 2;
    } else {
      // Miss (outside board)
      multiplier = 'miss';
      finalScore = 0;
      baseScore = 0; // For miss
    }

    widget.onDartThrow(finalScore, multiplier, baseScore, position);
  }
}

/// Custom painter for the dartboard
class DartboardPainter extends CustomPainter {
  final List<Offset> dartPositions; // Normalized positions (0.0-1.0)
  final double dartboardSize;

  const DartboardPainter({
    this.dartPositions = const [],
    required this.dartboardSize,
  });

  static const List<int> dartboardNumbers = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle (wire/frame)
    final framePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, framePaint);

    // Draw 20 segments
    for (int i = 0; i < 20; i++) {
      final startAngle = (i * 2 * math.pi / 20) - math.pi / 2 - (math.pi / 20);
      final sweepAngle = 2 * math.pi / 20;

      // Alternate colors for segments (black and white/cream)
      final bool isDark = i % 2 == 0;
      final segmentColor = isDark ? Colors.black : const Color(0xFFF5F5DC);
      final tripleColor = isDark ? Colors.red : Colors.green;
      final doubleColor = isDark ? Colors.red : Colors.green;

      // Draw double ring (outer edge: 0.906-1.0, 2x width)
      final doublePaint = Paint()
        ..color = doubleColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        doublePaint,
      );

      // Cover inner part with outer single segment color (0.676-0.906)
      final outerSinglePaint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.906),
        startAngle,
        sweepAngle,
        true,
        outerSinglePaint,
      );

      // Draw triple ring (0.582-0.676, 2x width)
      final triplePaint = Paint()
        ..color = tripleColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.676),
        startAngle,
        sweepAngle,
        true,
        triplePaint,
      );

      // Cover inner single (0.094-0.582)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.582),
        startAngle,
        sweepAngle,
        true,
        outerSinglePaint,
      );

      // Draw numbers and scores in each area
      final textAngle = startAngle + sweepAngle / 2;
      final number = dartboardNumbers[i];

      // Helper function to draw text at a specific radius
      void drawText(String text, double textRadius, Color color, double fontSize) {
        final textOffset = Offset(
          center.dx + textRadius * math.cos(textAngle),
          center.dy + textRadius * math.sin(textAngle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      // Draw number in outer single area (between triple and double)
      drawText(number.toString(), radius * 0.79, isDark ? Colors.white : Colors.black, 18);

      // Draw double score in double ring
      drawText((number * 2).toString(), radius * 0.953, Colors.white, 14);

      // Draw triple score in triple ring
      drawText((number * 3).toString(), radius * 0.629, Colors.white, 14);

      // Draw single score in inner single area
      drawText(number.toString(), radius * 0.38, isDark ? Colors.white : Colors.black, 16);
    }

    // Draw outer bull (25) - radius 0.094 (15.9mm on standard board)
    final outerBullPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.094, outerBullPaint);

    // Draw bullseye (50) - radius 0.037 (6.35mm on standard board)
    final bullseyePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.037, bullseyePaint);

    // Draw outer bull score label (25)
    final outerBullTextPainter = TextPainter(
      text: const TextSpan(
        text: '25',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    outerBullTextPainter.layout();
    outerBullTextPainter.paint(
      canvas,
      Offset(
        center.dx - outerBullTextPainter.width / 2,
        center.dy + radius * 0.055,
      ),
    );

    // Draw bullseye score label (50)
    final bullseyeTextPainter = TextPainter(
      text: const TextSpan(
        text: '50',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    bullseyeTextPainter.layout();
    bullseyeTextPainter.paint(
      canvas,
      Offset(
        center.dx - bullseyeTextPainter.width / 2,
        center.dy - bullseyeTextPainter.height / 2,
      ),
    );

    // Draw darts on the board
    for (final normalizedDartPos in dartPositions) {
      // Denormalize position (convert from 0.0-1.0 to actual pixel coordinates)
      final dartPos = Offset(
        normalizedDartPos.dx * dartboardSize,
        normalizedDartPos.dy * dartboardSize,
      );

      // Draw dart shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(dartPos + const Offset(2, 2), 6, shadowPaint);

      // Draw dart outer circle (metal tip)
      final dartOuterPaint = Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dartPos, 6, dartOuterPaint);

      // Draw dart inner circle (colored)
      final dartInnerPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dartPos, 4, dartInnerPaint);

      // Draw dart center point
      final dartCenterPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dartPos, 1.5, dartCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DartboardPainter oldDelegate) {
    // Repaint if dartboard size changed (for proper dart scaling)
    if (dartboardSize != oldDelegate.dartboardSize) {
      return true;
    }
    // Always repaint if dart positions have changed
    if (dartPositions.length != oldDelegate.dartPositions.length) {
      return true;
    }
    // Check if any positions changed
    for (int i = 0; i < dartPositions.length; i++) {
      if (dartPositions[i] != oldDelegate.dartPositions[i]) {
        return true;
      }
    }
    return false;
  }
}
