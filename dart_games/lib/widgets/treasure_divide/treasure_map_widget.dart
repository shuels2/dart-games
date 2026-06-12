import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Island coordinate tables ─────────────────────────────────────────────────

/// Island positions as (x%, y%) percentages of the canvas size.
/// Each list defines the winding path for that round count.
typedef _IslandCoord = ({double x, double y});

const Map<int, List<_IslandCoord>> _islandCoordsByRoundCount = {
  7: [
    (x: 10, y: 55),
    (x: 24, y: 30),
    (x: 40, y: 50),
    (x: 54, y: 22),
    (x: 68, y: 45),
    (x: 80, y: 25),
    (x: 90, y: 55),
  ],
  9: [
    (x: 13, y: 62),
    (x: 25, y: 38),
    (x: 37, y: 58),
    (x: 50, y: 30),
    (x: 62, y: 55),
    (x: 50, y: 72),
    (x: 62, y: 85),
    (x: 75, y: 62),
    (x: 88, y: 78),
  ],
  12: [
    (x: 10, y: 65),
    (x: 20, y: 42),
    (x: 32, y: 60),
    (x: 44, y: 30),
    (x: 55, y: 50),
    (x: 44, y: 68),
    (x: 55, y: 80),
    (x: 67, y: 55),
    (x: 78, y: 72),
    (x: 67, y: 85),
    (x: 78, y: 55),
    (x: 90, y: 70),
  ],
};

// ─── Public helpers ───────────────────────────────────────────────────────────

/// Returns the short display label for a target value.
/// Used in island markers.
///   20 → "20", -1 → "AD", -2 → "AT", 25 → "Bull"
String _shortLabel(int target) {
  if (target == -1) return 'AD';
  if (target == -2) return 'AT';
  if (target == 25) return 'Bull';
  return target.toString();
}

/// Returns the full banner label for the "Target: X" header.
///   20 → "20", -1 → "Any Double", -2 → "Any Triple", 25 → "Bull"
String _fullLabel(int target) {
  if (target == -1) return 'Any Double';
  if (target == -2) return 'Any Triple';
  if (target == 25) return 'Bull';
  return target.toString();
}

// ─── Rope path painter ────────────────────────────────────────────────────────

class _RopePainter extends CustomPainter {
  final List<_IslandCoord> coords;
  final int currentRoundIndex;
  final Color ropeColor;

  const _RopePainter({
    required this.coords,
    required this.currentRoundIndex,
    required this.ropeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (coords.length < 2) return;

    final paint = Paint()
      ..color = ropeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Build ONE combined dashed path across all segments and issue a
    // single canvas.drawPath. The original code did ~200 separate
    // canvas.drawPath calls per paint (one per dash, 25-ish dashes per
    // segment × 8 segments) which flooded CanvasKit's wasm Skia
    // bindings — each call round-trips through the Dart/wasm bridge
    // and allocates Skia objects that aren't deterministically released
    // in wasm. Cumulative heap pressure surfaced as
    // `RuntimeError: Aborted()` inside PictureRecorder. Consolidating
    // into one drawPath drops that pressure dramatically.
    final dashedPath = Path();
    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = Offset(
        coords[i].x / 100 * size.width,
        coords[i].y / 100 * size.height,
      );
      final p2 = Offset(
        coords[i + 1].x / 100 * size.width,
        coords[i + 1].y / 100 * size.height,
      );

      // Control points: perpendicular offset that alternates left/right per
      // segment for a meandering "drawn on parchment" feel.
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final chordLen = math.sqrt(dx * dx + dy * dy);
      if (chordLen < 1) continue;

      // Perpendicular unit vector
      final perpX = -dy / chordLen;
      final perpY = dx / chordLen;

      // Alternate bend direction per segment
      final sign = (i % 2 == 0) ? 1.0 : -1.0;
      final bendAmt = chordLen * 0.22 * sign;

      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final ctrl = Offset(
        mid.dx + perpX * bendAmt,
        mid.dy + perpY * bendAmt,
      );

      final segPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);

      _addDashesTo(dashedPath, segPath, dashLen: 3, gapLen: 5);
    }
    canvas.drawPath(dashedPath, paint);
  }

  /// Walk [source]'s contour and append every dash-length sub-segment
  /// into [target]. Caller is then responsible for a single drawPath
  /// on the accumulated target — instead of one drawPath per dash.
  void _addDashesTo(
    Path target,
    Path source, {
    required double dashLen,
    required double gapLen,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segEnd = math.min(
          distance + (drawing ? dashLen : gapLen),
          metric.length,
        );
        if (drawing) {
          target.addPath(
            metric.extractPath(distance, segEnd),
            Offset.zero,
          );
        }
        distance = segEnd;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_RopePainter old) =>
      old.coords != coords ||
      old.currentRoundIndex != currentRoundIndex ||
      old.ropeColor != ropeColor;
}

// ─── TreasureMapWidget ────────────────────────────────────────────────────────

/// Custom widget that renders the Treasure Divide treasure map.
///
/// Shows a winding path of island markers (one per round), the current-round
/// island glowing in Treasure Gold, completed islands with a green check,
/// a "Target: X" banner, an "Island X/Y" pill, and optional chest image
/// and score floater.
class TreasureMapWidget extends StatefulWidget {
  /// Ordered list of target values for each round.
  /// Length must equal [numberOfRounds].
  /// Sentinel values: -1 = AnyDouble, -2 = AnyTriple, 25 = Bull
  final List<int> targetSequence;

  /// 0-based index of the current/glowing island.
  final int currentRoundIndex;

  /// Total number of rounds (7, 9, or 12).
  final int numberOfRounds;

  /// Optional treasure chest image path shown at lower-right of map.
  final String? chestImagePath;

  /// Optional "+XX" floater text shown near the current island.
  final String? floaterText;

  /// When true, future islands show "???" instead of their target number.
  final bool customTargetsEnabled;

  // ── Color params (all have sensible defaults) ─────────────────────────────
  final Color treasureGold;
  final Color plankBrown;
  final Color sailWhite;
  final Color islandGreen;

  const TreasureMapWidget({
    super.key,
    required this.targetSequence,
    required this.currentRoundIndex,
    required this.numberOfRounds,
    this.chestImagePath,
    this.floaterText,
    this.customTargetsEnabled = false,
    this.treasureGold = const Color(0xFFFFD700),
    this.plankBrown = const Color(0xFF8B6914),
    this.sailWhite = const Color(0xFFFFF8E7),
    this.islandGreen = const Color(0xFF228B22),
  });

  // ─── Static public helpers ─────────────────────────────────────────────────

  /// Short label for a target value.
  /// e.g. 20 → "20", -1 → "AD", -2 → "AT", 25 → "Bull"
  static String targetLabel(
    int target, {
    bool custom = false,
    bool short = false,
  }) {
    if (custom) return short ? '???' : '???';
    if (short) return _shortLabel(target);
    return _fullLabel(target);
  }

  /// Full banner label for "Target: X" display.
  /// e.g. 20 → "20", -1 → "Any Double", -2 → "Any Triple", 25 → "Bull"
  static String fullTargetLabel(int target) => _fullLabel(target);

  @override
  State<TreasureMapWidget> createState() => _TreasureMapWidgetState();
}

class _TreasureMapWidgetState extends State<TreasureMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Build helpers ─────────────────────────────────────────────────────────

  List<_IslandCoord> _getCoords() {
    // Use the exact round count if in the table; otherwise use 9 as fallback.
    return _islandCoordsByRoundCount[widget.numberOfRounds] ??
        _islandCoordsByRoundCount[9]!;
  }

  // Native pixel dimensions of TreasureMap.png. The Stack is sized to match
  // this aspect ratio so the BoxFit.contain image fills the Stack edge to
  // edge with no letterboxing — that's what keeps target markers and the
  // rope path on the visible map at any screen size.
  static const double _kMapImageWidth = 1245.0;
  static const double _kMapImageHeight = 702.0;
  static const double _kMapAspect = _kMapImageWidth / _kMapImageHeight;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cap available area at 1200x900 (matches prior behavior — keeps
          // the map from ballooning on very large screens).
          final maxW =
              constraints.maxWidth > 1200.0 ? 1200.0 : constraints.maxWidth;
          final maxH =
              constraints.maxHeight > 900.0 ? 900.0 : constraints.maxHeight;
          // Largest size that fits within (maxW, maxH) and matches the
          // map's native aspect ratio. With the Stack aspect-locked to the
          // image, the image fills the Stack without letterboxing, so the
          // percentage-based coords for islands and rope land where they
          // should on the actual map graphic.
          double w, h;
          if (maxW / maxH > _kMapAspect) {
            h = maxH;
            w = h * _kMapAspect;
          } else {
            w = maxW;
            h = w / _kMapAspect;
          }

          final coords = _getCoords();
          final safeIndex =
              widget.currentRoundIndex.clamp(0, widget.numberOfRounds - 1);

          return Center(
            child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Layer 1: Background map image ─────────────────────────
                // ResizeImage caps the decoded raster. The source is
                // 1245×702 (~3.5 MB RGBA decoded) and on hi-DPI displays
                // Flutter can hold an even larger upscaled bitmap. The
                // map fills at most ~1200×680 logical pixels, so 1024×576
                // (matching the source aspect) gives the engine just
                // enough resolution while keeping each map raster bounded
                // to ~2.4 MB. Provider is `const` so it's stable across
                // every parent rebuild (every dart throw fires setState).
                Positioned.fill(
                  child: Image(
                    image: const ResizeImage(
                      AssetImage(
                          'assets/games/treasure_divide/pieces/TreasureMap.png'),
                      width: 1024,
                      height: 576,
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: widget.plankBrown.withOpacity(0.15),
                        border:
                            Border.all(color: widget.plankBrown, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // ── Layer 2: Rope path (CustomPaint) ──────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RopePainter(
                      coords: coords,
                      currentRoundIndex: safeIndex,
                      ropeColor: const Color.fromARGB(242, 139, 105, 20),
                    ),
                  ),
                ),

                // ── Layer 3: Island markers ───────────────────────────────
                ...List.generate(widget.numberOfRounds, (i) {
                  if (i >= coords.length) return const SizedBox.shrink();

                  final cx = coords[i].x / 100 * w;
                  final cy = coords[i].y / 100 * h;

                  final isCurrent = i == safeIndex;
                  final isCompleted = i < safeIndex;
                  final isFinal = i == widget.numberOfRounds - 1;

                  // Marker radius
                  double radius = isCurrent ? 28.0 : 22.0;
                  // Clamp to a minimum at tiny viewports
                  radius = radius.clamp(12.0, 36.0);

                  final markerColor = isCurrent
                      ? widget.treasureGold
                      : widget.sailWhite;
                  final borderColor = isFinal && !isCurrent
                      ? widget.treasureGold
                      : widget.plankBrown;
                  final borderWidth = isCurrent ? 3.0 : 2.0;

                  // Label
                  String label;
                  if (widget.customTargetsEnabled && i > safeIndex) {
                    label = '???';
                  } else if (i < widget.targetSequence.length) {
                    label = _shortLabel(widget.targetSequence[i]);
                  } else {
                    label = '?';
                  }

                  final textColor = (isFinal && label == 'Bull')
                      ? const Color(0xFFC41E3A) // Blood Red
                      : widget.plankBrown;

                  final fontSize = (label.length > 3)
                      ? math.max(6.0, radius * 0.45)
                      : math.max(7.0, radius * 0.6);

                  Widget marker = Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markerColor,
                      border:
                          Border.all(color: borderColor, width: borderWidth),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: widget.treasureGold.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Target label
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pirataOne(
                            fontSize: fontSize,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                        // Green checkmark overlay for completed islands
                        if (isCompleted)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: radius * 0.7,
                              height: radius * 0.7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.islandGreen,
                                border: Border.all(
                                    color: widget.sailWhite, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  '✓',
                                  style: TextStyle(
                                    fontSize: radius * 0.4,
                                    color: widget.sailWhite,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );

                  // Pulse animation only for current island
                  if (isCurrent) {
                    marker = RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: marker,
                      ),
                    );
                  }

                  return Positioned(
                    left: cx - radius,
                    top: cy - radius,
                    child: marker,
                  );
                }),

                // ── Layer 4: Optional "+XX" floater near current island ───
                if (widget.floaterText != null &&
                    safeIndex < coords.length) ...[
                  Positioned(
                    left: (coords[safeIndex].x / 100 * w) + 30,
                    top: (coords[safeIndex].y / 100 * h) - 28,
                    child: RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.islandGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: widget.sailWhite, width: 1.5),
                        ),
                        child: Text(
                          widget.floaterText!,
                          style: GoogleFonts.pirataOne(
                            fontSize: 16,
                            color: widget.sailWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Layer 5: Round counter pill (top-left) ────────────────
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.plankBrown,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: widget.treasureGold, width: 1.5),
                    ),
                    child: Text(
                      'Island ${(safeIndex + 1)}/${widget.numberOfRounds}',
                      style: GoogleFonts.pirataOne(
                        fontSize: 14,
                        color: widget.treasureGold,
                      ),
                    ),
                  ),
                ),

                // ── Layer 6: Target banner (top-center) ───────────────────
                Positioned(
                  top: 6,
                  left: w * 0.25,
                  right: w * 0.05,
                  child: Center(
                    child: () {
                      final isCustom = widget.customTargetsEnabled &&
                          safeIndex > 0; // current island is already revealed
                      final targetStr = isCustom
                          ? '???'
                          : (safeIndex < widget.targetSequence.length
                              ? _fullLabel(widget.targetSequence[safeIndex])
                              : '?');
                      return Text(
                        'Target: $targetStr',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pirataOne(
                          fontSize: (w * 0.045).clamp(16.0, 48.0),
                          color: widget.treasureGold,
                          // Matches the signature Treasure Divide title
                          // effect used on the setup / menu screens: dark
                          // drop shadow + ocean-teal glow.
                          shadows: const [
                            Shadow(
                              color: Color(0xCC000000),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Color(0xAA008B8B),
                              offset: Offset(0, 0),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      );
                    }(),
                  ),
                ),

                // ── Layer 7: Optional chest image (lower-right) ───────────
                // ResizeImage caps the decoded bitmap. The chest PNGs ship
                // at ~957×927 (≈3.5 MB RGBA decoded each) and three
                // variants (Empty/Halved/Full) can sit in the image cache.
                // The display is `w * 0.22` (≈ 264 px for a 1200 px map),
                // so 512 px gives 2× hi-DPI headroom while keeping each
                // chest bounded to ~1 MB of pixel data.
                if (widget.chestImagePath != null)
                  Positioned(
                    right: w * 0.02,
                    bottom: h * 0.02,
                    width: w * 0.22,
                    height: h * 0.30,
                    child: Image(
                      image: ResizeImage(
                        AssetImage(widget.chestImagePath!),
                        width: 512,
                        height: 512,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
