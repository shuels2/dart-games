import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A self-contained stone tablet button with optional lightning effect.
/// Used in Monster Mash dialogs and menus.
class StoneDialogButton extends StatefulWidget {
  final Key? buttonKey;
  final VoidCallback onPressed;
  final String label;
  final TextStyle? textStyle;
  final bool showLightning;
  final Color lightningColor;
  final bool showStoneFill;
  final bool showShadow;
  final Color? borderColor;
  final double height;
  final int seed;

  const StoneDialogButton({
    super.key,
    this.buttonKey,
    required this.onPressed,
    required this.label,
    this.textStyle,
    this.showLightning = false,
    this.lightningColor = const Color(0xFFF5F5DC),
    this.showStoneFill = true,
    this.showShadow = true,
    this.borderColor,
    this.height = 48,
    this.seed = 0,
  });

  @override
  State<StoneDialogButton> createState() => _StoneDialogButtonState();
}

class _StoneDialogButtonState extends State<StoneDialogButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _lightningController;

  @override
  void initState() {
    super.initState();
    if (widget.showLightning) {
      _lightningController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _lightningController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jaggedClipper = _JaggedEdgeClipper(
      seed: widget.seed,
      jagAmount: 3.0,
      segmentsPerSide: 20,
    );

    final defaultTextStyle = GoogleFonts.pirataOne(
      fontSize: 24,
      color: widget.showStoneFill ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5DC),
      shadows: widget.showStoneFill
          ? [
              Shadow(color: Colors.white.withOpacity(0.5), offset: const Offset(1, 1), blurRadius: 0),
              const Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 0),
            ]
          : null,
    );

    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _StoneTabletPainter(
          jaggedClipper: jaggedClipper,
          borderColor: widget.borderColor,
          showShadow: widget.showShadow,
        ),
        child: ClipPath(
          clipper: jaggedClipper,
          child: Stack(
            children: [
              if (widget.showStoneFill) ...[
                // Stone gradient fill
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.4, -0.4),
                        radius: 1.2,
                        colors: [
                          Color(0xFFa8a8a8),
                          Color(0xFF888888),
                          Color(0xFF707070),
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner bevel: top/bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.0, 0.15, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),
                // Inner bevel: left/right
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.25),
                        ],
                        stops: const [0.0, 0.08, 0.92, 1.0],
                      ),
                    ),
                  ),
                ),
                // Stone texture
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/games/monster_mash/images/stone-texture.png'),
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
              ] else
                // Transparent fill for inverse/outline style
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              // Lightning effect
              if (widget.showLightning && _lightningController != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _lightningController!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LightningPainter(
                          animationValue: _lightningController!.value,
                          lightningColor: widget.lightningColor,
                        ),
                      );
                    },
                  ),
                ),
              // Button content
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: widget.buttonKey,
                    onTap: widget.onPressed,
                    child: Center(
                      child: Text(
                        widget.label,
                        style: widget.textStyle ?? defaultTextStyle,
                      ),
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

class _JaggedEdgeClipper extends CustomClipper<Path> {
  final int seed;
  final double jagAmount;
  final int segmentsPerSide;

  _JaggedEdgeClipper({
    this.seed = 0,
    this.jagAmount = 3.5,
    this.segmentsPerSide = 20,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(jagAmount, jagAmount);

    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (w - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      final y = (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(0, jagAmount * 2));
    }

    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = (h - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      path.lineTo(x.clamp(w - jagAmount * 2, w), y);
    }

    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (w - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      final y = h - (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(h - jagAmount * 2, h));
    }

    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = h - (h - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      path.lineTo(x.clamp(0, jagAmount * 2), y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _StoneTabletPainter extends CustomPainter {
  final _JaggedEdgeClipper jaggedClipper;
  final Color? borderColor;
  final bool showShadow;

  _StoneTabletPainter({required this.jaggedClipper, this.borderColor, this.showShadow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final path = jaggedClipper.getClip(size);

    if (showShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.save();
      canvas.translate(5, 5);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = borderColor ?? const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightningPainter extends CustomPainter {
  final double animationValue;
  final Color lightningColor;

  _LightningPainter({required this.animationValue, required this.lightningColor});

  @override
  void paint(Canvas canvas, Size size) {
    _maybeDrawBolt(canvas, size, phase: 0.0, duration: 0.08, seed: 42);
    _maybeDrawBolt(canvas, size, phase: 0.05, duration: 0.04, seed: 43);
    _maybeDrawBolt(canvas, size, phase: 0.45, duration: 0.06, seed: 77);
    _maybeDrawBolt(canvas, size, phase: 0.50, duration: 0.03, seed: 78);

    final flashOpacity = _getFlashOpacity();
    if (flashOpacity > 0) {
      final flashPaint = Paint()
        ..color = lightningColor.withOpacity(flashOpacity * 0.15);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  double _getFlashOpacity() {
    for (final window in [(0.0, 0.08), (0.05, 0.04), (0.45, 0.06), (0.50, 0.03)]) {
      final start = window.$1;
      final dur = window.$2;
      if (animationValue >= start && animationValue <= start + dur) {
        final t = (animationValue - start) / dur;
        return 1.0 - (2.0 * (t - 0.5)).abs();
      }
    }
    return 0.0;
  }

  void _maybeDrawBolt(Canvas canvas, Size size, {
    required double phase,
    required double duration,
    required int seed,
  }) {
    if (animationValue < phase || animationValue > phase + duration) return;

    final t = (animationValue - phase) / duration;
    final opacity = t < 0.3 ? t / 0.3 : 1.0 - ((t - 0.3) / 0.7);

    final rng = Random(seed);
    final startX = size.width * (0.15 + rng.nextDouble() * 0.7);
    final segments = 5 + rng.nextInt(4);

    final path = Path();
    path.moveTo(startX, 0);

    double x = startX;
    double y = 0;
    final segHeight = size.height / segments;

    for (int i = 0; i < segments; i++) {
      x += (rng.nextDouble() - 0.5) * size.width * 0.3;
      x = x.clamp(4.0, size.width - 4.0);
      y += segHeight;
      path.lineTo(x, y);
    }

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);

    final glowPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final ambientPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, ambientPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
