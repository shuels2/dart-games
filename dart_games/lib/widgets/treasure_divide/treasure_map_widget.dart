import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Island coordinate tables ─────────────────────────────────────────────────

/// Island positions as (x%, y%) percentages of the canvas size.
/// Each list defines the winding path for that round count.
typedef _IslandCoord = ({double x, double y});

/// Each list is hand-tuned to spread islands across the full map and
/// land the LAST island on the treasure chest at (~85, 85).
///
/// Constraints honored by all three layouts:
/// - x is monotonically non-decreasing until the very last waypoint, so
///   the rope between adjacent islands never crosses earlier segments.
/// - The compass-rose area (roughly x in [0, 28], y in [68, 100]) in
///   the bottom-left is kept fully clear — no island lands there and
///   no rope segment passes through.
/// - First island stays at x ≥ 8 (out of the Island counter pill / map
///   border area).
/// - Y values vary across each layout (not just two rows) so the trail
///   doesn't read as a strict zigzag. The pattern alternates direction
///   but the amplitude and offset shift along the way.
const Map<int, List<_IslandCoord>> _islandCoordsByRoundCount = {
  // Successive y values intentionally avoid strict alternation —
  // some neighbors barely move, others jump hard across the map so
  // the trail reads as a wandering path rather than a stair-step.
  // Left-side islands (x < 28) stay at y ≤ 55 so the marker halo
  // doesn't bleed into the bottom-left compass rose (y > 65).
  // Right-side islands inside the chest x-band (x > 76) stay at
  // y ≤ 60 so they don't overlap the chest sprite. Everywhere else
  // we push y as deep as 70-72 to use the bottom of the map.
  7: [
    (x: 11.9, y: 36.7),
    (x: 32.8, y: 18.3),
    (x: 36.0, y: 62.0),
    (x: 59.5, y: 78.7),
    (x: 58.9, y: 36.1),
    (x: 82.1, y: 22.0),
    (x: 87.9, y: 62.7),
  ],
  9: [
    (x: 10.9, y: 24.0),
    (x: 23.9, y: 48.0),
    (x: 39.9, y: 25.0),
    (x: 32.3, y: 80.5),
    (x: 61.0, y: 77.0),
    (x: 46.3, y: 48.3),
    (x: 69.2, y: 47.5),
    (x: 80.5, y: 19.8),
    (x: 87.1, y: 62.9),
  ],
  12: [
    (x: 11.3, y: 23.6),
    (x: 20.5, y: 48.5),
    (x: 35.4, y: 21.0),
    (x: 32.8, y: 82.7),
    (x: 44.0, y: 40.1),
    (x: 62.4, y: 20.8),
    (x: 44.3, y: 65.8),
    (x: 58.8, y: 83.1),
    (x: 71.8, y: 65.9),
    (x: 71.9, y: 38.3),
    (x: 87.7, y: 16.6),
    (x: 88.8, y: 63.4),
  ],
};

// ─── Public coord lookup (used by the layout editor) ────────────────────────

/// Returns a mutable copy of the canonical island coordinates for the
/// given round count. Used by the in-game layout editor as the
/// starting point before any drag-driven mutations are applied.
List<({double x, double y})> defaultIslandCoordsFor(int rounds) {
  final base =
      _islandCoordsByRoundCount[rounds] ?? _islandCoordsByRoundCount[9]!;
  return base
      .map<({double x, double y})>((c) => (x: c.x, y: c.y))
      .toList();
}

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
      ..strokeWidth = 10.0
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

      _addDashesTo(dashedPath, segPath, dashLen: 12, gapLen: 20);
    }
    canvas.drawPath(dashedPath, paint);
  }

  /// Walk [source]'s contour and append every dash-length sub-segment
  /// into [target] as a plain moveTo + lineTo pair. Caller is then
  /// responsible for a single drawPath on the accumulated target.
  ///
  /// Uses [getTangentForOffset] to read just the start and end
  /// positions of each dash. The previous implementation used
  /// [extractPath] which allocates a fresh Skia [Path] for every dash
  /// — at ~400 dashes per paint on a wider map that allocation churn
  /// trips CanvasKit's wasm heap and the engine aborts inside
  /// PictureRecorder. moveTo/lineTo writes into the existing target
  /// path with no Skia object creation per dash.
  ///
  /// The dashes render as straight chords between two points on the
  /// underlying Bezier rather than tracing the curve exactly. With
  /// dashLen=3 px the chord/curve deviation is well under a pixel.
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
          final start = metric.getTangentForOffset(distance);
          final end = metric.getTangentForOffset(segEnd);
          if (start != null && end != null) {
            target.moveTo(start.position.dx, start.position.dy);
            target.lineTo(end.position.dx, end.position.dy);
          }
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

  /// When true, render a "QUARTER IT" pill next to the Island counter
  /// in the top-left corner of the map. The badge sits inline on the
  /// same row so the two read as one HUD strip.
  final bool quarterItEnabled;

  /// Optional widget key for the QUARTER IT pill. Used by tests that
  /// previously found the badge in the game screen's top badge row.
  final Key? quarterItBadgeKey;

  /// Optional override for the island coordinate list. When provided
  /// AND its length matches [numberOfRounds], the map uses these
  /// coords instead of the canonical [_islandCoordsByRoundCount]
  /// entry. Lets a host screen (e.g. the layout editor) preview
  /// dragged positions without modifying the constants.
  final List<({double x, double y})>? coordsOverride;

  /// When true, each island marker becomes draggable. As the user
  /// drags, [onIslandDragged] fires with the new (x%, y%) for that
  /// island, allowing the host screen to update its override list
  /// and re-render the map with the new positions.
  final bool editMode;

  /// Fires during a drag with the dragged island's index and its new
  /// (x%, y%) coordinates (in the 0..100 percentage space the
  /// coordinate constants use).
  final void Function(int index, double xPercent, double yPercent)?
      onIslandDragged;

  // ── Color params (all have sensible defaults) ─────────────────────────────
  final Color treasureGold;
  final Color plankBrown;
  final Color sailWhite;
  final Color islandGreen;
  final Color bloodRed;

  const TreasureMapWidget({
    super.key,
    required this.targetSequence,
    required this.currentRoundIndex,
    required this.numberOfRounds,
    this.chestImagePath,
    this.floaterText,
    this.quarterItEnabled = false,
    this.quarterItBadgeKey,
    this.coordsOverride,
    this.editMode = false,
    this.onIslandDragged,
    this.customTargetsEnabled = false,
    this.treasureGold = const Color(0xFFFFD700),
    this.plankBrown = const Color(0xFF8B6914),
    this.sailWhite = const Color(0xFFFFF8E7),
    this.islandGreen = const Color(0xFF228B22),
    this.bloodRed = const Color(0xFFC41E3A),
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

  // Layout editor drag tracking. The key is attached to the inner
  // SizedBox so we can convert the touch's global position into the
  // canvas's local coordinate space on every drag event. Using
  // absolute position (instead of the per-event delta) means the
  // marker tracks the mouse pointer one-to-one even when multiple
  // gesture events fire between rebuilds.
  final GlobalKey _canvasKey = GlobalKey();
  // Offset from the touch start to the marker's center, in canvas
  // pixels. Captured in onPanStart so the marker doesn't snap to the
  // cursor — it keeps the same relative position throughout the drag.
  Offset _dragStartOffset = Offset.zero;

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
    // Layout editor override — only honored when its length matches
    // the current numberOfRounds (so a stale override from a different
    // game configuration can't render misaligned markers).
    final override = widget.coordsOverride;
    if (override != null && override.length == widget.numberOfRounds) {
      return override;
    }
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
          // Cap raised from 1200x900 → 2400x1600. The HUD layout was
          // updated so the map row gets the bulk of the screen's
          // vertical space; the prior 1200×900 cap was preventing the
          // aspect-locked map from filling that newly-recovered area
          // on typical desktop / tablet viewports.
          final maxW =
              constraints.maxWidth > 2400.0 ? 2400.0 : constraints.maxWidth;
          final maxH =
              constraints.maxHeight > 1600.0 ? 1600.0 : constraints.maxHeight;
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
          // HUD elements (Island pill, QUARTER IT pill, target circles,
          // target labels) are sized against a 1200 px map baseline.
          // When the map fits into a smaller viewport we shrink them
          // proportionally so they don't dominate the map graphic on
          // tablets / small windows. Clamp keeps the HUD legible on
          // very small viewports and prevents oversizing on very
          // large ones.
          final mapScale = (w / 1200.0).clamp(0.5, 1.2);

          return Center(
            child: SizedBox(
            key: _canvasKey,
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

                // ── Layer 3: Optional chest image (lower-right) ───────────
                // Painted BEFORE the island markers so the final island
                // (which lands on the chest) draws over it instead of
                // being hidden behind it. ResizeImage caps the decoded
                // bitmap: chest PNGs ship at ~957×927 (≈3.5 MB RGBA
                // decoded each) and three variants can sit in the cache;
                // 512 px keeps each bounded to ~1 MB while still giving
                // 2× hi-DPI headroom at the ~264 px display size.
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

                // ── Layer 4: Island markers ───────────────────────────────
                ...List.generate(widget.numberOfRounds, (i) {
                  if (i >= coords.length) return const SizedBox.shrink();

                  final cx = coords[i].x / 100 * w;
                  final cy = coords[i].y / 100 * h;

                  final isCurrent = i == safeIndex;
                  final isCompleted = i < safeIndex;
                  final isFinal = i == widget.numberOfRounds - 1;

                  // Marker radius — 73 (current) / 56 (other) baseline,
                  // scaled with the map so circles shrink proportionally
                  // when the viewport shrinks. Floor 20 keeps them
                  // legible on very small screens; ceiling 80 keeps
                  // them from swamping the map on large ones.
                  double radius = (isCurrent ? 73.0 : 56.0) * mapScale;
                  radius = radius.clamp(20.0, 80.0);

                  final markerColor = isCurrent
                      ? widget.treasureGold
                      : widget.sailWhite;
                  final borderColor = isFinal && !isCurrent
                      ? widget.treasureGold
                      : widget.plankBrown;
                  final borderWidth = isCurrent ? 3.5 : 2.5;

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

                  // Font multipliers bumped from 0.45 / 0.6 → 0.515 /
                  // 0.686. Combined with the 40% radius bump, the
                  // labels render ~60% larger than before. The flat
                  // +6 px is follow-up tuning for legibility at the
                  // new marker size.
                  //
                  // Threshold is `length > 4` so 'Bull' (4 chars) joins
                  // the standard branch and renders at the same size
                  // as the number labels — only true overflow labels
                  // (5+ chars, not currently used) would fall back to
                  // the smaller formula.
                  final fontSize = (label.length > 4)
                      ? math.max(6.0, radius * 0.515 + 6.0)
                      : math.max(7.0, radius * 0.686 + 6.0);

                  // The final island lands ON the chest sprite, so it
                  // gets a sail-white halo to keep it legible against
                  // the chest's warm wood/gold tones. The active-island
                  // gold glow is additive — both fire when the final
                  // island is also the current turn.
                  final boxShadows = <BoxShadow>[
                    if (isFinal)
                      BoxShadow(
                        color: widget.sailWhite.withOpacity(0.7),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    if (isCurrent)
                      BoxShadow(
                        color: widget.treasureGold.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ];

                  Widget marker = Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markerColor,
                      border:
                          Border.all(color: borderColor, width: borderWidth),
                      boxShadow: boxShadows.isEmpty ? null : boxShadows,
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

                  // Pulse animation only for current island.
                  // Suppressed in edit mode so the scaling doesn't fight
                  // the drag gesture (the marker would shrink/grow under
                  // the finger and the hit box would shift).
                  if (isCurrent && !widget.editMode) {
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

                  // Edit mode: drag follows the mouse pointer 1:1.
                  // Uses globalToLocal on the canvas SizedBox (via
                  // _canvasKey) to convert the absolute touch position
                  // into canvas-local coords. Reading the touch's
                  // absolute position is unaffected by stale state
                  // between events (which is what the previous
                  // delta-based implementation tripped on, causing
                  // fractional movement when multiple onPanUpdate
                  // events fired between rebuilds).
                  if (widget.editMode) {
                    marker = GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        // Capture the offset from the touch to the
                        // marker center so the marker doesn't snap to
                        // the cursor at the start of the drag.
                        final box = _canvasKey.currentContext
                            ?.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final localTouch =
                            box.globalToLocal(details.globalPosition);
                        _dragStartOffset = Offset(cx, cy) - localTouch;
                      },
                      onPanUpdate: (details) {
                        if (widget.onIslandDragged == null) return;
                        final box = _canvasKey.currentContext
                            ?.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final localTouch =
                            box.globalToLocal(details.globalPosition);
                        final newCenter = localTouch + _dragStartOffset;
                        final newX = (newCenter.dx / w * 100.0)
                            .clamp(0.0, 100.0);
                        final newY = (newCenter.dy / h * 100.0)
                            .clamp(0.0, 100.0);
                        widget.onIslandDragged!(i, newX, newY);
                      },
                      child: marker,
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

                // ── Layer 5: Round counter pill + QUARTER IT badge ────────
                // Both elements sit on the same row in the top-left of
                // the map. Baseline sizes (18h/7v padding, 25pt font)
                // are multiplied by [mapScale] so the pills shrink with
                // the map on smaller viewports.
                Positioned(
                  top: 8 * mapScale,
                  left: 8 * mapScale,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18 * mapScale,
                            vertical: 7 * mapScale),
                        decoration: BoxDecoration(
                          color: widget.plankBrown,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              color: widget.treasureGold, width: 2.5),
                        ),
                        child: Text(
                          'Island ${(safeIndex + 1)} / ${widget.numberOfRounds}',
                          style: GoogleFonts.pirataOne(
                            fontSize: 25 * mapScale,
                            color: widget.treasureGold,
                          ),
                        ),
                      ),
                      if (widget.quarterItEnabled) ...[
                        SizedBox(width: 12 * mapScale),
                        Container(
                          key: widget.quarterItBadgeKey,
                          // Padding, border radius, font size and border
                          // width all match the Island counter pill so
                          // the two read as a single HUD strip. Border
                          // color uses sail white to match the badge's
                          // text color (mirrors the Island pill, where
                          // the border color matches its text color).
                          padding: EdgeInsets.symmetric(
                              horizontal: 18 * mapScale,
                              vertical: 7 * mapScale),
                          decoration: BoxDecoration(
                            color: widget.bloodRed,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: widget.sailWhite, width: 2.5),
                          ),
                          child: Text(
                            'QUARTER IT',
                            style: GoogleFonts.pirataOne(
                              fontSize: 25 * mapScale,
                              color: widget.sailWhite,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Layer 6: Target banner (top-center) ───────────────────
                // Centered across the full map width — previously the
                // Positioned slot left-anchored at w*0.25 and right-
                // anchored at w*0.05 to dodge the top-left pill, which
                // pulled the text right of center. Pure 0/0 + Center
                // puts the banner in the actual map midline; the
                // Island + QUARTER IT pills sit slightly above (top: 8
                // vs banner top: 6) so any overlap is negligible.
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
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
                          // Banner sizing is map-width-relative (~4.5%
                          // of map width), clamped at 24 / 56 — bumped
                          // 8 pt across the board for legibility at the
                          // current HUD scale.
                          fontSize: (w * 0.045 + 8.0).clamp(24.0, 56.0),
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

              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
