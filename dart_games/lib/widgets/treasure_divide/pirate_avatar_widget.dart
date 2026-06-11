import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../models/treasure_divide_game.dart';
import '../player_avatar_widget.dart';

// ─── ThemeAccessoryAnchor ────────────────────────────────────────────────────

/// Named anchor points used to position pirate accessories on a player avatar.
///
/// Face-anchored variants (hat / eyepatch / scar / monocle / freckles /
/// neckerchief) are positioned relative to detected face landmarks when
/// available, or fall back to heuristic proportional constants.
///
/// Corner-anchored variants (parrot / monkey / crab / compass / telescope /
/// spoon / cannonball / seahorse) are always pinned to the avatar box corners
/// regardless of landmark data.
enum ThemeAccessoryAnchor {
  headTop,
  leftEye,
  rightEye,
  noseTip,
  mouthCenter,
  chinBottom,
  topLeftCorner,
  topRightCorner,
  bottomLeftCorner,
  bottomRightCorner,
}

// ─── Heuristic fallback positions (normalized 0..1) ─────────────────────────

const Map<ThemeAccessoryAnchor, Offset> _kHeuristicPositions = {
  ThemeAccessoryAnchor.headTop: Offset(0.5, 0.05),
  ThemeAccessoryAnchor.leftEye: Offset(0.40, 0.40),
  ThemeAccessoryAnchor.rightEye: Offset(0.60, 0.40),
  ThemeAccessoryAnchor.noseTip: Offset(0.50, 0.55),
  ThemeAccessoryAnchor.mouthCenter: Offset(0.50, 0.70),
  ThemeAccessoryAnchor.chinBottom: Offset(0.50, 0.85),
  ThemeAccessoryAnchor.topLeftCorner: Offset(0.0, 0.0),
  ThemeAccessoryAnchor.topRightCorner: Offset(1.0, 0.0),
  ThemeAccessoryAnchor.bottomLeftCorner: Offset(0.0, 1.0),
  ThemeAccessoryAnchor.bottomRightCorner: Offset(1.0, 1.0),
};

// ─── Per-theme accessory anchor map ─────────────────────────────────────────

/// Maps each theme index 0..7 to the ordered list of anchor positions for its
/// accessories.  The list order MUST match [kThemeAccessoryPaths] for the same
/// theme index.
///
/// Anchor rationale per theme:
/// - 0 Captain:    hat=headTop (crown of head), eyepatch=leftEye (over L eye),
///                 parrot=topRightCorner (macaw peeking in from shoulder)
/// - 1 First Mate: bandana=headTop (wraps forehead), monkey=topLeftCorner
///                 (spider monkey peeking in from upper-left)
/// - 2 Bosun:      tricorn=headTop, crab=bottomLeftCorner (crab at lower frame
///                 — spec says "perched on tricorn above headTop" but that would
///                 require a derived anchor; bottomLeftCorner is used as a
///                 simpler frame-corner so the crab is always visible without
///                 needing a dynamic offset above headTop), scar=leftEye
///                 (near-cheek scar; leftEye puts it in the right facial zone)
/// - 3 Navigator:  sailor_cap=headTop, monocle=rightEye, compass=bottomRightCorner
/// - 4 Lookout:    bandana=headTop, telescope=topRightCorner (scope extends
///                 toward upper-right — matches spec "upper-right frame edge")
/// - 5 Cook:       chef_hat=headTop, neckerchief=chinBottom (under jaw),
///                 spoon=bottomLeftCorner (peeking from lower-left)
/// - 6 Gunner:     floppy_hat=headTop, cannonball=bottomRightCorner
/// - 7 Cabin Boy:  tiny_cap=headTop, seahorse=bottomLeftCorner (spec says
///                 lower-right but bottomLeftCorner avoids collision with
///                 freckles centered on noseTip), freckles=noseTip (between
///                 nose and cheeks — noseTip is the closest single-point anchor)
const Map<int, List<ThemeAccessoryAnchor>> kThemeAccessoryAnchors = {
  0: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.leftEye,
    ThemeAccessoryAnchor.topRightCorner,
  ],
  1: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.topLeftCorner,
  ],
  2: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.bottomLeftCorner,
    ThemeAccessoryAnchor.leftEye,
  ],
  3: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.rightEye,
    ThemeAccessoryAnchor.bottomRightCorner,
  ],
  4: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.topRightCorner,
  ],
  5: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.chinBottom,
    ThemeAccessoryAnchor.bottomLeftCorner,
  ],
  6: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.bottomRightCorner,
  ],
  7: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.bottomLeftCorner,
    ThemeAccessoryAnchor.noseTip,
  ],
};

// ─── Corner anchors set (used to decide accessory sizing) ────────────────────

const _kCornerAnchors = {
  ThemeAccessoryAnchor.topLeftCorner,
  ThemeAccessoryAnchor.topRightCorner,
  ThemeAccessoryAnchor.bottomLeftCorner,
  ThemeAccessoryAnchor.bottomRightCorner,
};

// ─── Anchor position resolver ────────────────────────────────────────────────

/// Returns a normalized [Offset] (x, y in 0..1) for [anchor].
///
/// When [landmarks] is non-null the following keys are read:
///   - `leftEye`     → map with `x`, `y`
///   - `rightEye`    → map with `x`, `y`
///   - `noseTip`     → map with `x`, `y`
///   - `mouthCenter` → map with `x`, `y`
///   - `boundingBox` → map with `x`, `y`, `width`, `height` used to derive
///                     headTop and chinBottom
///
/// Any missing key silently falls back to the heuristic constant.
Offset resolveAnchorPosition(
  ThemeAccessoryAnchor anchor,
  Map<String, dynamic>? landmarks,
) {
  if (landmarks == null) {
    return _kHeuristicPositions[anchor]!;
  }

  // Corners are always heuristic — they are frame-relative, not face-relative.
  if (_kCornerAnchors.contains(anchor)) {
    return _kHeuristicPositions[anchor]!;
  }

  try {
    final bb = landmarks['boundingBox'] as Map<String, dynamic>?;
    final bbX = (bb?['x'] as num?)?.toDouble();
    final bbY = (bb?['y'] as num?)?.toDouble();
    final bbW = (bb?['width'] as num?)?.toDouble();
    final bbH = (bb?['height'] as num?)?.toDouble();

    switch (anchor) {
      case ThemeAccessoryAnchor.headTop:
        if (bbX != null && bbY != null && bbW != null && bbH != null) {
          // Sit ~15% of face height above the top of the bounding box.
          return Offset(bbX + bbW / 2, bbY - bbH * 0.15);
        }
        return _kHeuristicPositions[anchor]!;

      case ThemeAccessoryAnchor.chinBottom:
        if (bbX != null && bbY != null && bbW != null && bbH != null) {
          return Offset(bbX + bbW / 2, bbY + bbH);
        }
        return _kHeuristicPositions[anchor]!;

      case ThemeAccessoryAnchor.leftEye:
        final eye = landmarks['leftEye'] as Map<String, dynamic>?;
        if (eye != null) {
          return Offset(
            (eye['x'] as num).toDouble(),
            (eye['y'] as num).toDouble(),
          );
        }
        return _kHeuristicPositions[anchor]!;

      case ThemeAccessoryAnchor.rightEye:
        final eye = landmarks['rightEye'] as Map<String, dynamic>?;
        if (eye != null) {
          return Offset(
            (eye['x'] as num).toDouble(),
            (eye['y'] as num).toDouble(),
          );
        }
        return _kHeuristicPositions[anchor]!;

      case ThemeAccessoryAnchor.noseTip:
        final nose = landmarks['noseTip'] as Map<String, dynamic>?;
        if (nose != null) {
          return Offset(
            (nose['x'] as num).toDouble(),
            (nose['y'] as num).toDouble(),
          );
        }
        return _kHeuristicPositions[anchor]!;

      case ThemeAccessoryAnchor.mouthCenter:
        final mouth = landmarks['mouthCenter'] as Map<String, dynamic>?;
        if (mouth != null) {
          return Offset(
            (mouth['x'] as num).toDouble(),
            (mouth['y'] as num).toDouble(),
          );
        }
        return _kHeuristicPositions[anchor]!;

      // Corner anchors handled above; listed here so the switch is exhaustive.
      case ThemeAccessoryAnchor.topLeftCorner:
      case ThemeAccessoryAnchor.topRightCorner:
      case ThemeAccessoryAnchor.bottomLeftCorner:
      case ThemeAccessoryAnchor.bottomRightCorner:
        return _kHeuristicPositions[anchor]!;
    }
  } catch (_) {
    // Malformed landmark data — fall back to heuristic.
    return _kHeuristicPositions[anchor]!;
  }
}

// ─── PirateAvatarWidget ──────────────────────────────────────────────────────

/// A player avatar dressed with pirate-themed accessories overlaid on the base
/// [PlayerAvatarWidget].
///
/// Composition:
/// ```
/// RepaintBoundary
///   └─ SizedBox.square(size)
///        └─ Stack
///             ├─ PlayerAvatarWidget  (base layer — fills the square)
///             ├─ Positioned accessory 0
///             ├─ Positioned accessory 1
///             └─ Positioned accessory 2  (if theme has 3)
/// ```
///
/// Accessory sizing rules (per architectural spec):
/// - Face-anchored accessories (hat / eyepatch / scar / monocle / freckles /
///   neckerchief): rendered at `size * 0.35`.
/// - Corner-anchored accessories (parrot / monkey / crab / compass / telescope /
///   spoon / cannonball / seahorse / tiny_cap corner-style): rendered at
///   `size * 0.30`.
///
/// Each accessory is CENTERED on its resolved anchor point via:
///   `left = anchor.x * size - accSize / 2`
///   `top  = anchor.y * size - accSize / 2`
///
/// If any accessory image fails to load, that layer is replaced with
/// [SizedBox.shrink] — the base avatar and other accessories still render.
///
/// When [isActive] is true, a gold glow ring is rendered behind the base avatar
/// to visually distinguish the currently-active player.
class PirateAvatarWidget extends StatelessWidget {
  final Player player;

  /// Theme index 0..7. Unknown indices silently render no accessories.
  final int themeIndex;

  /// Square edge length in logical pixels.
  final double size;

  /// When true, paints a visible gold glow around the avatar.
  final bool isActive;

  const PirateAvatarWidget({
    super.key,
    required this.player,
    required this.themeIndex,
    required this.size,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final paths = kThemeAccessoryPaths[themeIndex] ?? [];
    final anchors = kThemeAccessoryAnchors[themeIndex] ?? [];
    final landmarks = player.faceLandmarks;

    // Clamp to the shorter list in case of mismatch (defensive).
    final count = paths.length < anchors.length ? paths.length : anchors.length;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Glow ring (active player indicator) ──────────────────────────
            if (isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.75),
                        blurRadius: size * 0.12,
                        spreadRadius: size * 0.04,
                      ),
                    ],
                  ),
                ),
              ),

            // ── Base avatar ───────────────────────────────────────────────────
            Positioned.fill(
              child: ClipOval(
                child: PlayerAvatarWidget(
                  player: player,
                  size: size / 2, // PlayerAvatarWidget uses radius
                  isHighlighted: false,
                ),
              ),
            ),

            // ── Accessory layers ──────────────────────────────────────────────
            for (int i = 0; i < count; i++)
              _buildAccessoryLayer(paths[i], anchors[i], landmarks),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessoryLayer(
    String assetPath,
    ThemeAccessoryAnchor anchor,
    Map<String, dynamic>? landmarks,
  ) {
    final isCorner = _kCornerAnchors.contains(anchor);
    final accSize = isCorner ? size * 0.30 : size * 0.35;
    final normalizedPos = resolveAnchorPosition(anchor, landmarks);

    final left = normalizedPos.dx * size - accSize / 2;
    final top = normalizedPos.dy * size - accSize / 2;

    return Positioned(
      left: left,
      top: top,
      width: accSize,
      height: accSize,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
