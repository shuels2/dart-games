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
  // Upper-cheek placement under the left eye: x aligned to the left
  // eye column, y at the midpoint between the left eye and nose tip.
  // Used for sprites like the bosun scar that should sit directly
  // below the eye rather than between the eye and nose horizontally.
  leftEyeNoseMidpoint,
  // 4 o'clock position on the inscribed circle of the avatar box —
  // (0.5 + 0.5·sin120°, 0.5 − 0.5·cos120°) ≈ (0.933, 0.75). Useful
  // for sprites that should perch on the lower-right edge of the
  // avatar circle (e.g. bosun crab).
  circleFourOClock,
  // 5 o'clock position on the inscribed circle — (0.5 + 0.5·sin150°,
  // 0.5 − 0.5·cos150°) ≈ (0.75, 0.933). Lower-right of the circle,
  // closer to 6 o'clock than the 4 o'clock anchor. Used for sprites
  // that should sit near the bottom-right curve of the avatar (e.g.
  // gunner cannonball).
  circleFiveOClock,
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
  // x = heuristic leftEye.x (0.40); y = midpoint of heuristic leftEye.y
  // (0.40) and noseTip.y (0.55).
  ThemeAccessoryAnchor.leftEyeNoseMidpoint: Offset(0.40, 0.475),
  // (0.5 + 0.5·sin120°, 0.5 − 0.5·cos120°) — point on the inscribed
  // circle at the 4 o'clock mark.
  ThemeAccessoryAnchor.circleFourOClock: Offset(0.933, 0.75),
  // (0.5 + 0.5·sin150°, 0.5 − 0.5·cos150°) — point on the inscribed
  // circle at the 5 o'clock mark.
  ThemeAccessoryAnchor.circleFiveOClock: Offset(0.75, 0.933),
};

// ─── Per-theme accessory anchor map ─────────────────────────────────────────

/// Maps each theme index 0..7 to the ordered list of anchor positions for its
/// accessories.  The list order MUST match [kThemeAccessoryPaths] for the same
/// theme index.
///
/// Anchor rationale per theme:
/// - 0 Captain:    hat=headTop (crown of head), eyepatch=leftEye (over L eye),
///                 parrot=topRightCorner (macaw peeking in from shoulder)
/// - 1 First Mate: bandana=headTop (wraps forehead — sized like the lookout
///                 bandana), monkey=topRightCorner (spider monkey peeking
///                 in from upper-right — pulled inward + rendered behind
///                 the avatar like the captain parrot)
/// - 2 Bosun:      tricorn=headTop, crab=circleFourOClock (perched on the
///                 lower-right edge of the avatar circle at the 4 o'clock
///                 mark), scar=leftEyeNoseMidpoint (sits on the upper cheek
///                 directly below the left eye)
/// - 3 Navigator:  sailor_cap=headTop, monocle=rightEye, compass=circleFour-
///                 OClock (perched on the lower-right edge of the avatar
///                 circle at the 4 o'clock mark)
/// - 4 Lookout:    bandana=headTop, telescope=leftEye with a half-step
///                 right/up nudge so the scope's bottom-left corner pins
///                 exactly on the left-eye landmark (telescope appears
///                 raised to the eye)
/// - 5 Cook:       chef_hat=headTop, neckerchief=chinBottom (under jaw),
///                 spoon=circleFiveOClock (perched on the lower-right edge
///                 of the avatar circle at the 5 o'clock mark — renders
///                 above the neckerchief since accessory index 2 paints
///                 on top of index 1)
/// - 6 Gunner:     floppy_hat=headTop, cannonball=circleFiveOClock (centered
///                 on the lower-right curve of the avatar circle, between the
///                 4 o'clock and 6 o'clock marks)
/// - 7 Cabin Boy:  tiny_cap=headTop, seahorse=circleFourOClock (perched on
///                 the lower-right edge of the avatar circle at the 4 o'clock
///                 mark — matches the spec's "lower-right" placement),
///                 freckles=noseTip (between nose and cheeks — noseTip is the
///                 closest single-point anchor)
const Map<int, List<ThemeAccessoryAnchor>> kThemeAccessoryAnchors = {
  0: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.leftEye,
    ThemeAccessoryAnchor.topRightCorner,
  ],
  1: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.topRightCorner,
  ],
  2: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.circleFourOClock,
    ThemeAccessoryAnchor.leftEyeNoseMidpoint,
  ],
  3: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.rightEye,
    ThemeAccessoryAnchor.circleFourOClock,
  ],
  4: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.leftEye,
  ],
  5: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.chinBottom,
    ThemeAccessoryAnchor.circleFiveOClock,
  ],
  6: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.circleFiveOClock,
  ],
  7: [
    ThemeAccessoryAnchor.headTop,
    ThemeAccessoryAnchor.circleFourOClock,
    ThemeAccessoryAnchor.noseTip,
  ],
};

// ─── Corner anchors set (used to decide accessory sizing) ────────────────────

// "Corner" here means "always heuristic + uses the corner sizing
// rule (size × 0.30 instead of 0.35)" — the geometric notion is
// looser; circleFourOClock isn't a box corner but it's frame-relative
// (independent of face landmarks) so it goes in this set.
const _kCornerAnchors = {
  ThemeAccessoryAnchor.topLeftCorner,
  ThemeAccessoryAnchor.topRightCorner,
  ThemeAccessoryAnchor.bottomLeftCorner,
  ThemeAccessoryAnchor.bottomRightCorner,
  ThemeAccessoryAnchor.circleFourOClock,
  ThemeAccessoryAnchor.circleFiveOClock,
};

// ─── Per-accessory size overrides ────────────────────────────────────────────

/// Multiplier applied to the default accessory size, keyed by theme
/// index then accessory index (matching the order in
/// [kThemeAccessoryPaths] / [kThemeAccessoryAnchors]).
///
/// Default base size: `size * 0.35` (face-anchored) or `size * 0.30`
/// (corner-anchored). Each entry below scales that base by the listed
/// factor. Missing entries use 1.0 (no change).
///
/// Use this when a specific sprite needs to be tuned smaller/larger
/// without changing the global formula — keeps the rest of the themes
/// untouched. Add one row per (theme, accessory) you've tuned.
const Map<int, Map<int, double>> kThemeAccessorySizeMultipliers = {
  // Captain (theme 0): hat, eyepatch, parrot.
  // Eyepatch reduced 30% — the source art renders larger than the
  // surrounding eye area at the default 0.35 ratio.
  0: {1: 0.70},
  // Navigator (theme 3):
  //   sailor_cap (0) — multiplier removed; sailor cap now sizes purely
  //                    off face-bbox scaling (see
  //                    kThemeAccessoryFaceWidthScale[3][0]).
  //   monocle (1)    — 0.70× fine-tune on top of face-width scaling
  //                    below (mirrors the captain eyepatch).
  //   compass (2)    — 1.38× corner-anchor base (0.30 × avatarSize)
  //                    so the instrument reads clearly at the 4
  //                    o'clock edge of the circle.
  3: {
    1: 0.70,
    2: 1.38,
  },
  // Cook (theme 5):
  //   spoon (2) — 1.265× corner-anchor base (0.30 × avatarSize) so the
  //               utensil reads clearly at the 5 o'clock edge of the
  //               avatar circle.
  5: {2: 1.265},
  // Bosun (theme 2):
  //   crab (1) — 1.5× the corner-anchor base (0.30 × avatarSize) so
  //              the critter perched at the 4 o'clock mark reads
  //              clearly at the avatar circle's edge.
  2: {1: 1.5},
  // Lookout (theme 4):
  //   telescope (1) — 1.375× the face-anchored base (0.35 × avatarSize)
  //                   for a longer, more visible scope held to the eye.
  4: {1: 1.375},
  // Gunner (theme 6):
  //   cannonball (1) — 1.30× the corner-anchor base (0.30 × avatarSize),
  //                    so the iron ball perched at the 5 o'clock mark
  //                    reads as a clear, heavy projectile.
  6: {1: 1.30},
  // Cabin Boy (theme 7):
  //   seahorse (1) — 1.20× the corner-anchor base so the critter reads
  //                  clearly when floating in the lower-left of the
  //                  avatar circle.
  7: {1: 1.20},
};

/// Per-(theme, accessory) position nudge, in units of the accessory's
/// own size. `Offset(-0.5, 0.5)` means shift left by 50% of the
/// sprite's width and down by 50% of its height.
///
/// Applied AFTER the standard anchor-based positioning (which centers
/// the sprite on its resolved anchor point). Use it for finishing
/// touches — e.g. pulling a corner-anchored sprite inward so part of
/// it overlaps the avatar circle.
///
/// Missing entries default to `Offset.zero` (no nudge).
const Map<int, Map<int, Offset>> kThemeAccessoryOffsetMultipliers = {
  // Captain (theme 0):
  //   hat (0) — shifted right 8% and up 10% of its own size so the
  //             brim aligns with the head and sits a touch above it.
  //   eyepatch (1) — right 3%, up 3% of its own size to settle the
  //                  patch over the eye proper.
  //   parrot (2) — pulled inward toward the upper-right of the avatar
  //                circle so it peeks out from behind. Originally
  //                -0.5/+0.5 (full half-step inward) hid too much of
  //                the bird; bumped 20% back toward the corner.
  0: {
    0: Offset(0.08, -0.10),
    1: Offset(0.03, -0.03),
    2: Offset(-0.30, 0.30),
  },
  // First Mate (theme 1):
  //   bandana (0) — right 7%, down 20% of its own size.
  //   monkey (1)  — pulled inward from the topRightCorner anchor —
  //                 left 5%, down 60% of its own size (less inward
  //                 than the captain parrot, so more of the monkey
  //                 sticks out past the avatar circle).
  1: {
    0: Offset(0.07, 0.20),
    1: Offset(-0.05, 0.60),
  },
  // Bosun (theme 2):
  //   tricorn (0) — right 5%, up 5% of its own size — tuned closer to
  //                 the head than the captain hat since the tricorn's
  //                 wider profile and asymmetric peak read better when
  //                 it sits nearer the forehead.
  //   crab (1)    — pulled left 20% (into the circle from the 4 o'clock
  //                 edge) and down 10% of its own size.
  //   scar (2)    — right 20%, down 15% of its own size — slid off the
  //                 eye column toward the cheekbone so it doesn't sit
  //                 directly under the iris.
  2: {
    0: Offset(0.05, -0.05),
    1: Offset(-0.20, 0.10),
    2: Offset(0.20, 0.15),
  },
  // Navigator (theme 3):
  //   sailor_cap (0) — up 5% of its own size — sits just above the head
  //                    crown without floating off it.
  //   monocle (1)    — left 10% of its own size — sits centered on
  //                    the rightEye y level, just inboard horizontally.
  //   compass (2)    — left 20%, down 20% of its own size — pulls the
  //                    instrument inward from the 4 o'clock edge so it
  //                    overlaps the avatar circle.
  3: {
    0: Offset(0, -0.05),
    1: Offset(-0.10, 0.00),
    2: Offset(-0.20, 0.20),
  },
  // Cook (theme 5):
  //   chef_hat (0)    — up 30% of its own size (25% further up than the
  //                     navigator sailor cap's -0.05) so the toque rises
  //                     well above the head.
  //   neckerchief (1) — down 45% of its own size from the chinBottom
  //                     anchor so the cloth drapes well below the jaw.
  //   spoon (2)       — right 50%, up 50% of its own size from the
  //                     circleFiveOClock anchor — slides the utensil
  //                     out past the avatar circle's edge to the right.
  5: {
    0: Offset(0, -0.30),
    1: Offset(0, 0.45),
    2: Offset(0.50, -0.50),
  },
  // Lookout (theme 4):
  //   bandana (0)   — left 13%, down 25% of its own size — the bandana
  //                   art has a lot of negative space above the cloth
  //                   itself, so the box needs to slide down so the
  //                   visible bandana lands on the forehead.
  //   telescope (1) — right 43%, up 40% from the leftEye anchor —
  //                   started at +0.5/-0.5 (bottom-left corner exactly
  //                   on the eye), slid 10% left + 10% down so the
  //                   eyepiece overlaps the eye, then nudged 3% back
  //                   to the right.
  4: {
    0: Offset(-0.13, 0.25),
    1: Offset(0.43, -0.4),
  },
  // Gunner (theme 6):
  //   floppy_hat (0) — right 6%, up 15% of its own size — the floppy
  //                    hat art has tall negative space below the brim,
  //                    so the box needs to slide up so the visible
  //                    crown lands on the forehead.
  //   cannonball (1) — up 30% of its own size from the circleFiveOClock
  //                    anchor so the ball sits inset from the lower-right
  //                    curve of the circle rather than dangling off it.
  6: {
    0: Offset(0.06, -0.15),
    1: Offset(0, -0.30),
  },
  // Cabin Boy (theme 7):
  //   tiny_cap (0) — left 35%, up 10% of its own size — slides the
  //                  cap off the centered headTop position toward the
  //                  side of the head so it reads as a worn-jaunty cap.
  //   seahorse (1) — left 15%, down 15% of its own size from the
  //                  circleFourOClock anchor so the critter pulls in
  //                  toward the avatar circle from the 4 o'clock edge.
  7: {
    0: Offset(-0.35, -0.10),
    1: Offset(-0.15, 0.15),
  },
};

/// Set of accessories rendered BEHIND the base avatar (between the
/// optional glow ring and the avatar's ClipOval), keyed by theme
/// index. Accessories listed here paint first; the round avatar then
/// paints on top of them, hiding the portion that falls inside the
/// circle — so the sprite looks like it's emerging from behind the
/// avatar.
///
/// Missing entries (or themes not listed) render in front of the
/// avatar as usual.
const Map<int, Set<int>> kAccessoriesBehindAvatar = {
  // Captain parrot — sits behind the avatar so the bird looks like
  // it's poking out from the upper-right of the circle.
  0: {2},
  // First Mate monkey — same effect as the captain parrot, mirrored
  // to the upper-left of the avatar.
  1: {1},
};

/// Per-(theme, accessory) face-width scaling. When an entry exists
/// AND the player has a face bounding box, the accessory's base size
/// is `faceWidth * avatarSize * scale` — so it tracks the player's
/// actual head width instead of the fixed 0.30 / 0.35 avatar-relative
/// ratio. Useful for hats, bandanas, hoods, etc. that need to match
/// the head, not the avatar frame.
///
/// Scale semantics:
///   1.0 → sprite width equals the face bounding-box width exactly
///   1.1 → sprite extends 5% beyond the face on each side (brim)
///   0.9 → sprite is 90% of face width
///
/// Falls back to the standard `baseSize` formula when no entry is
/// configured or no bounding box is available. The
/// [kThemeAccessorySizeMultipliers] value is still applied on top,
/// so you can dial a face-width-scaled sprite a touch larger/smaller
/// without changing the head-width baseline.
const Map<int, Map<int, double>> kThemeAccessoryFaceWidthScale = {
  // Captain (theme 0):
  //   hat (0)      — accSize = faceBoundingBoxWidth × avatarSize × 1.6,
  //                  so the hat box spans 1.6× the player's actual face
  //                  bbox width (brim overhangs ~30% past each side of
  //                  the face). Tracks head width automatically.
  //   eyepatch (1) — face-width scaled at 0.575 so the patch box is
  //                  57.5% of the face bbox width. The 0.70 size
  //                  multiplier still applies on top → effective patch
  //                  size is faceWidth × avatarSize × 0.575 × 0.70.
  0: {0: 1.6, 1: 0.575},
  // Bosun (theme 2):
  //   tricorn (0) — 1.36× face-width (15% smaller than the captain
  //                 hat at 1.6) since the tricorn art has more vertical
  //                 mass and looked oversized at the captain's scale.
  //   scar (2)    — 0.25× face-width so the scar's box spans 25% of
  //                 the player's actual face bbox width.
  2: {
    0: 1.36,
    2: 0.25,
  },
  // Lookout (theme 4):
  //   bandana (0) — 1.541× face-width — the bandana wraps further
  //                 around the head than the tricorn brim so it
  //                 reads better with a touch more overhang on
  //                 each side.
  4: {0: 1.541},
  // First Mate (theme 1):
  //   bandana (0) — 1.156× face-width — 25% smaller than the lookout
  //                 bandana's 1.541; sits tighter to the head.
  1: {0: 1.156},
  // Navigator (theme 3):
  //   sailor_cap (0) — 1.02× face-width — a snug round cap that just
  //                    matches the head width with almost no overhang.
  //   monocle (1)    — face-width scaled at 0.575, same as the captain
  //                    eyepatch. The 0.70 size multiplier applies on
  //                    top → effective dimension faceWidth × avatarSize
  //                    × 0.575 × 0.70.
  3: {
    0: 1.02,
    1: 0.575,
  },
  // Cook (theme 5):
  //   chef_hat (0)    — 1.02× face-width, sized the same as the
  //                     navigator sailor cap.
  //   neckerchief (1) — 1.202× face-width so the cloth drapes a touch
  //                     past the head width across the chin / neck.
  5: {
    0: 1.02,
    1: 1.202,
  },
  // Cabin Boy (theme 7):
  //   tiny_cap (0) — 0.591× face-width — a small cap that sits well
  //                  inside the head outline, true to the "tiny" name.
  //   freckles (2) — 0.715× face-width so the freckles patch spans
  //                  roughly the cheekbones, across the nose bridge
  //                  from cheek to cheek.
  7: {
    0: 0.591,
    2: 0.715,
  },
  // Gunner (theme 6):
  //   floppy_hat (0) — 2.101× face-width — wider than the lookout
  //                    bandana since the floppy crown extends further
  //                    past the head than a bandana wrap.
  6: {0: 2.101},
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

      case ThemeAccessoryAnchor.leftEyeNoseMidpoint:
        // Upper-cheek under the left eye: x = leftEye.x (so the
        // sprite is column-aligned with the eye), y = midpoint between
        // leftEye.y and noseTip.y. Used for the bosun scar. Falls
        // back to the heuristic when either landmark is missing.
        final eye = landmarks['leftEye'] as Map<String, dynamic>?;
        final nose = landmarks['noseTip'] as Map<String, dynamic>?;
        if (eye != null && nose != null) {
          final ex = (eye['x'] as num).toDouble();
          final ey = (eye['y'] as num).toDouble();
          final ny = (nose['y'] as num).toDouble();
          return Offset(ex, (ey + ny) / 2);
        }
        return _kHeuristicPositions[anchor]!;

      // Frame-relative anchors handled by the early-return above;
      // listed here so the switch is exhaustive.
      case ThemeAccessoryAnchor.topLeftCorner:
      case ThemeAccessoryAnchor.topRightCorner:
      case ThemeAccessoryAnchor.bottomLeftCorner:
      case ThemeAccessoryAnchor.bottomRightCorner:
      case ThemeAccessoryAnchor.circleFourOClock:
      case ThemeAccessoryAnchor.circleFiveOClock:
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

  // ─── Accessory ImageProvider cache ──────────────────────────────────────────
  //
  // Each accessory PNG is wrapped in
  //   ResizeImage(AssetImage(path), width: 256, height: 256, policy: fit)
  // The wrapped provider is keyed by asset path and memoized for the
  // lifetime of the process. Without this, every PirateAvatarWidget.build()
  // — and the gameplay screen rebuilds via setState on every dart throw,
  // touching every visible avatar — allocates fresh AssetImage + ResizeImage
  // instances. While ImageProvider.== is defined on both classes (so the
  // image cache would still hit), the per-frame allocation churn of up to
  // 8 players × 2-3 accessories = ~24 throwaway provider chains per setState
  // contributed to CanvasKit wasm-heap pressure that surfaces as
  // RuntimeError: Aborted() inside PictureRecorder. Memoizing keeps a
  // single canonical instance per asset path so Image widgets reuse the
  // exact same key and stream listener registration across rebuilds.
  static final Map<String, ImageProvider> _accessoryProviderCache = {};

  static ImageProvider _accessoryProvider(String assetPath) {
    return _accessoryProviderCache.putIfAbsent(
      assetPath,
      () => ResizeImage(
        AssetImage(assetPath),
        width: 256,
        height: 256,
        policy: ResizeImagePolicy.fit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paths = kThemeAccessoryPaths[themeIndex] ?? [];
    final anchors = kThemeAccessoryAnchors[themeIndex] ?? [];
    final landmarks = player.faceLandmarks;

    // Clamp to the shorter list in case of mismatch (defensive).
    final count = paths.length < anchors.length ? paths.length : anchors.length;
    final behindSet =
        kAccessoriesBehindAvatar[themeIndex] ?? const <int>{};

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

            // ── Accessories that render BEHIND the avatar ─────────────────────
            // Painted before the ClipOval so the portion overlapping the
            // circle is covered, making the sprite look like it's emerging
            // from behind the avatar.
            for (int i = 0; i < count; i++)
              if (behindSet.contains(i))
                _buildAccessoryLayer(i, paths[i], anchors[i], landmarks),

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

            // ── Accessories that render IN FRONT of the avatar ────────────────
            for (int i = 0; i < count; i++)
              if (!behindSet.contains(i))
                _buildAccessoryLayer(i, paths[i], anchors[i], landmarks),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessoryLayer(
    int accessoryIndex,
    String assetPath,
    ThemeAccessoryAnchor anchor,
    Map<String, dynamic>? landmarks,
  ) {
    final isCorner = _kCornerAnchors.contains(anchor);
    // Pull the face bounding-box width if we have landmarks — used by
    // face-width-scaled accessories (hats, bandanas) so the sprite
    // matches the actual head, not the avatar frame.
    double? faceWidth;
    if (landmarks != null) {
      try {
        final bb = landmarks['boundingBox'] as Map<String, dynamic>?;
        faceWidth = (bb?['width'] as num?)?.toDouble();
      } catch (_) {
        faceWidth = null;
      }
    }
    final faceWidthScale =
        kThemeAccessoryFaceWidthScale[themeIndex]?[accessoryIndex];
    final double baseSize;
    if (faceWidthScale != null && faceWidth != null && faceWidth > 0) {
      // Head-width scaling — sprite tracks the player's actual face
      // width regardless of avatar pixel size.
      baseSize = faceWidth * size * faceWidthScale;
    } else {
      baseSize = isCorner ? size * 0.30 : size * 0.35;
    }
    // Per-(theme, accessory) size override — defaults to 1.0 (no change).
    // Applied as a fine-tune on top of whichever base sizing strategy
    // ran above.
    final multiplier =
        kThemeAccessorySizeMultipliers[themeIndex]?[accessoryIndex] ?? 1.0;
    final accSize = baseSize * multiplier;
    final normalizedPos = resolveAnchorPosition(anchor, landmarks);
    // Per-(theme, accessory) position nudge, in units of the sprite's
    // own size — applied AFTER centering on the anchor.
    final offsetMultiplier =
        kThemeAccessoryOffsetMultipliers[themeIndex]?[accessoryIndex] ??
            Offset.zero;

    final left = normalizedPos.dx * size -
        accSize / 2 +
        offsetMultiplier.dx * accSize;
    final top = normalizedPos.dy * size -
        accSize / 2 +
        offsetMultiplier.dy * accSize;

    return Positioned(
      left: left,
      top: top,
      width: accSize,
      height: accSize,
      child: Image(
        // Cap the decoded bitmap dimensions of accessory PNGs. The source
        // art ships at 600–950 px on the long edge (parrot is 897×935 →
        // ~3.4 MB of pixel data decoded as RGBA). With up to 8 players
        // rendering 2–3 accessories each, the uncapped decode pool can
        // exhaust the CanvasKit wasm heap and trigger RuntimeError:
        // Aborted() inside PictureRecorder. The on-screen accessory is
        // 30–35% of the avatar size (≤ 110px logical for the 300px active
        // avatar), so 256px gives ~2× headroom for hi-DPI without keeping
        // multi-MB rasters resident.
        //
        // Policy MUST be `fit` (not the default `exact`) — non-square
        // accessories (e.g. captain hat 922×567) would otherwise decode
        // as a squished 256×256 bitmap and BoxFit.contain can't recover
        // the original aspect from a pre-distorted source.
        //
        // The provider itself is fetched from a static memoization cache
        // (see [_accessoryProvider]) so up to ~24 accessory layers across
        // 8 player tiles don't allocate fresh provider chains on every
        // parent setState (each dart throw rebuilds the whole gameplay
        // screen).
        image: _accessoryProvider(assetPath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
