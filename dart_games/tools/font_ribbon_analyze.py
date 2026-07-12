#!/usr/bin/env python
"""Font-ribbon pixel analyzer for game.build's AR-10 Font Parity.

Reads a ribbon PNG produced by either
`integration_test/appbar_title_measurement_test.dart` or
`integration_test/home_screen_font_measurement_test.dart`, measures
each game's RECOMMENDED strip cap height against Target Tag's
baseline, and emits structured JSON on stdout.

Usage:
    python tools/font_ribbon_analyze.py \\
        --ribbon temp_screenshots/appbar_title_ribbon.png \\
        --tolerance 3

Output (stdout, JSON):
    {
      "baseline_game": "Target Tag",
      "baseline_cap_px": 15,
      "tolerance_px": 3,
      "games": [
        {"name": "Carnival Derby", "rec_cap_px": 18, "delta_px": +3, "within_tolerance": true},
        ...
      ],
      "all_within_tolerance": true,
      "games_over_tolerance": []
    }

Exit codes:
    0 -- ran cleanly (check `all_within_tolerance` in JSON for parity)
    1 -- ribbon file missing / unparseable / structure not recognized

The game names + expected strip layout are hard-coded to match the
current 10 games. When a new game is added, extend `_KNOWN_GAMES`
below to include it in the expected order.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter

try:
    from PIL import Image
except ImportError:
    print(json.dumps({
        "error": "Pillow (PIL) not installed; run: pip install Pillow",
    }))
    sys.exit(1)


# ordered as they appear top-to-bottom in the ribbons
_KNOWN_GAMES = [
    "Carnival Derby",
    "Clockwork Quest",
    "Gladiator Arena",
    "Lunar Lander",
    "Monster Mash",
    "Pirate's Grid",
    "Reef Royale",
    "Target Tag",  # BASELINE
    "Tiki Golf",
    "Treasure Divide",
]


def _is_dark_page_bg(px, tol=15):
    return all(abs(px[i] - c) < tol for i, c in enumerate((17, 19, 24)))


def _is_light_card(px, tol=15):
    return all(abs(px[i] - c) < tol for i, c in enumerate((242, 243, 245)))


def _is_dark_text(px):
    r, g, b = px
    return r < 100 and g < 100 and b < 110


def _detect_strip_y_ranges(im, ribbon_type):
    """Find the game-strip Y ranges.

    For the appbar ribbon the strips have game-brand colors (not the
    light card). For the home-screen ribbon they're all light card.
    We scan a column ~x=300 for pixels that are NOT the dark page bg,
    then keep every contiguous non-bg block whose height > 20 as a
    strip. Skip the top 1-2 strips (title bar + AppBar of the test
    scaffold).
    """
    W, H = im.size
    scan_x = 300
    in_strip = False
    start = None
    strips = []
    for y in range(H):
        px = im.getpixel((scan_x, y))
        if not _is_dark_page_bg(px):
            if not in_strip:
                start = y
                in_strip = True
        else:
            if in_strip:
                if y - start > 20:
                    strips.append((start, y - 1))
                in_strip = False
    if in_strip and start is not None:
        strips.append((start, H - 1))

    # Skip the header + AppBar of the test scaffold. The 10 game
    # strips are always the LAST 10.
    game_strips = strips[-10:]
    if len(game_strips) != 10:
        raise ValueError(
            f"expected 10 game strips, detected {len(game_strips)} "
            f"(is this a valid ribbon PNG?)"
        )
    return game_strips


def _detect_column_x_ranges(im, first_strip_y):
    """Detect CURRENT / RECOMMENDED horizontal ranges.

    Scan a row 2 px below the top of the first game strip (guaranteed
    to be above any glyph ink). Both column strips share the same
    light card background at that row.
    """
    W, H = im.size
    y_test = first_strip_y + 2
    in_strip = False
    start = None
    x_strips = []
    for x in range(W):
        px = im.getpixel((x, y_test))
        # AppBar ribbon: strip bg is game-brand color, not necessarily
        # light card. Home-screen ribbon: all strips are light card.
        # Sample the very top of the strip (guaranteed no text)
        # separately for each row's actual bg.
        if not _is_dark_page_bg(px):
            if not in_strip:
                start = x
                in_strip = True
        else:
            if in_strip:
                if x - start > 100:
                    x_strips.append((start, x - 1))
                in_strip = False
    if in_strip and start is not None:
        x_strips.append((start, W - 1))

    # Expect: [label-space skipped], [CURRENT], [RECOMMENDED], [OVERLAY?]
    # The overlay column exists on appbar ribbon; for our purposes we
    # only need CURRENT and RECOMMENDED.
    if len(x_strips) < 2:
        raise ValueError(
            f"expected at least 2 column strips, detected {len(x_strips)}"
        )
    return x_strips[0], x_strips[1]


def _measure_cap(im, y0, y1, x0, x1, ribbon_type):
    """Cap height of dark text in strip (y0..y1, x0..x1).

    Returns 0 if no dark text found (rare edge case).

    For the appbar ribbon, strips have varied backgrounds (game brand
    colors); we sample the specific strip bg from the top pixel. For
    the home-screen ribbon, all strips are the light card so we can
    use the constant dark-text detector.
    """
    if ribbon_type == "appbar":
        # Sample strip bg from top of strip, above text
        strip_bg = im.getpixel(((x0 + x1) // 2, y0 + 3))

        def is_text(px, bg=strip_bg, tol=55):
            return sum(abs(px[i] - bg[i]) for i in range(3)) > tol
    else:
        # home-screen: dark text on light card
        def is_text(px):
            return _is_dark_text(px)

    # find top of ink
    top = None
    for y in range(y0 + 2, y1 - 1):
        for x in range(x0 + 8, x1 - 8, 2):
            if is_text(im.getpixel((x, y))):
                top = y
                break
        if top is not None:
            break
    if top is None:
        return 0

    # find baseline: mode of per-column bottoms
    col_bots = []
    for x in range(x0 + 8, x1 - 8):
        col_bot = None
        for y in range(y0 + 2, y1 - 1):
            if is_text(im.getpixel((x, y))):
                col_bot = y
        if col_bot is not None:
            col_bots.append(col_bot)
    if not col_bots:
        return 0
    quantized = [b - (b % 2) for b in col_bots]
    baseline = Counter(quantized).most_common(1)[0][0]
    return baseline - top + 1


def analyze(ribbon_path, tolerance_px, ribbon_type):
    im = Image.open(ribbon_path).convert("RGB")
    strips = _detect_strip_y_ranges(im, ribbon_type)
    cur_x, rec_x = _detect_column_x_ranges(im, strips[0][0])

    baseline_cap = _measure_cap(im, *strips[7], *cur_x, ribbon_type=ribbon_type)
    if baseline_cap == 0:
        raise ValueError("could not measure Target Tag baseline cap")

    games = []
    for i, (y0, y1) in enumerate(strips):
        rec_cap = _measure_cap(im, y0, y1, *rec_x, ribbon_type=ribbon_type)
        delta = rec_cap - baseline_cap if rec_cap else None
        within = (
            delta is not None
            and 0 <= delta <= tolerance_px  # +0..+tolerance
            or _KNOWN_GAMES[i] == "Target Tag"  # baseline itself is fine
        )
        games.append({
            "name": _KNOWN_GAMES[i],
            "rec_cap_px": rec_cap,
            "delta_px": delta,
            "within_tolerance": within,
        })

    over_tolerance = [g for g in games if not g["within_tolerance"]]
    return {
        "ribbon_type": ribbon_type,
        "ribbon_path": ribbon_path,
        "baseline_game": "Target Tag",
        "baseline_cap_px": baseline_cap,
        "tolerance_px": tolerance_px,
        "games": games,
        "all_within_tolerance": not over_tolerance,
        "games_over_tolerance": [g["name"] for g in over_tolerance],
    }


def main():
    ap = argparse.ArgumentParser(
        description=("Analyze a font-ribbon PNG for cap-height parity "
                     "against Target Tag."),
    )
    ap.add_argument("--ribbon", required=True,
                    help="Path to the ribbon PNG.")
    ap.add_argument("--tolerance", type=int, default=3,
                    help="Max positive cap-height delta in px (default 3).")
    ap.add_argument("--type", choices=["appbar", "home_screen"], default=None,
                    help=("Ribbon type. Auto-detected from filename if "
                          "omitted."))
    args = ap.parse_args()

    if args.type is None:
        if "home_screen" in args.ribbon:
            args.type = "home_screen"
        else:
            args.type = "appbar"

    try:
        result = analyze(args.ribbon, args.tolerance, args.type)
    except (FileNotFoundError, ValueError) as e:
        print(json.dumps({"error": str(e), "ribbon": args.ribbon}))
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
