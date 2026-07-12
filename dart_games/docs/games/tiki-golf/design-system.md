# Tiki Golf - Design System

## Theme Philosophy

Tiki Golf evokes the warm, laid-back atmosphere of Lilo & Stitch meets a tropical mini-golf course. Bright island colors — crystal lagoon blues, lush palm greens, sandy creams — are layered over a fully illustrated tropical background (tiki totems, palms, ocean, volcano). The vibe is sunny, playful, family-friendly, and breezy. A Palm Green translucent overlay on the background keeps the illustrated scene visible while ensuring UI elements remain readable at all screen sizes.

## Color Palette

### Primary Colors
- **Lagoon Blue:** `#00B4D8` — Primary active states, highlights, primary buttons, segmented toggle active background, USE MULLIGAN button
- **Palm Green:** `#2D6A4F` — Secondary backgrounds, scorecard rows, settings box background (0.9 opacity), background overlay (0.60 opacity)
- **Tiki Brown:** `#8B5E3C` — Borders on all settings boxes (2px), tiki element styling, panel borders, Mulligan button background

### Supporting Colors
- **Hibiscus Pink:** `#FF69B4` — Accent elements, bogey score color, NEXT PLAYER (decline mulligan) button
- **Sand White:** `#FFF5E1` — Primary text color, labels, card backgrounds, button labels on colored backgrounds
- **Tropical Orange (substituted):** `#FF8C42` — Urgent states, double bogey / Splash score color, alert indicators. **Note:** The spec originally specified `#FF6B35` (Sunset Orange). The user substituted `#FF8C42` for all game-screen styling, wireframes, and screen code. Use `#FF8C42` exclusively — do NOT revert to the spec's `#FF6B35`.
- **Sky Blue:** `#87CEEB` — Light background areas, header accents
- **Coconut Cream:** `#FFFDD0` — Subtle backgrounds, alternating scorecard rows

### Score Colors
- **Birdie (1 stroke):** Lagoon Blue `#00B4D8` — under par, great result
- **Par (2 strokes):** Sand White `#FFF5E1` — neutral, expected result
- **Bogey (3+ strokes, not Splash):** Hibiscus Pink `#FF69B4` — over par
- **Splash (Max Darts + 1):** Tropical Orange `#FF8C42` — worst case

### Team Colors (assigned from crests)
Each team is identified by its randomly-assigned crest color, used for team name text and active player panel highlights.

## Typography

### Font Families

**AR-4 Nunito Exemption:** Tiki Golf has user-approved permission to use `GoogleFonts.nunito` for body text. This is an explicit exception to the AR-4 audit rule (which normally flags Nunito as the container app's font). AR-4 should suppress Nunito false positives for `lib/screens/games/tiki_golf/` only. Display headings remain `GoogleFonts.boogaloo` (game-specific).

- **Display Font:** `GoogleFonts.boogaloo` — Game title, section headers, player names, score numbers, button labels. Casual hand-drawn style that captures the breezy tropical island vibe.
- **Body Font:** `GoogleFonts.nunito` — Body text, descriptions, captions. Warm and friendly while staying highly readable. Approved exemption from AR-4.

### Text Styles

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Game Title | Boogaloo | 48-56pt | Regular | Sand White with Tiki Brown shadow |
| Section Headers | Boogaloo | 28-32pt | Regular | Sand White |
| Player Names | Boogaloo | 20-24pt | Regular | Sand White (or team color) |
| Score Numbers | Boogaloo | 36-44pt | Regular | Score color (see above) |
| Body Text | Nunito | 14-18pt | Regular | Sand White |
| Button Labels | Boogaloo | 18-22pt | Regular | Sand White on colored bg |
| Settings Labels | Boogaloo | 16pt | Regular | Sand White |
| Hole Name / Target | Boogaloo | 20-24pt | Regular | Sand White |
| Mulligan Badge | Boogaloo | 12pt | Regular | Sand White |

## Screen-by-Screen Styling

### Background (All Screens)

All three screens (menu, game, results) share the same background stack:
1. `Positioned.fill(Image.asset('assets/games/tiki_golf/images/TikiGolf-Background.png', fit: BoxFit.cover))` — The fully illustrated mini-golf scene (tiki totems, palms, ocean, volcano).
2. `Positioned.fill(Container(color: const Color(0xFF2D6A4F).withOpacity(0.60)))` — Palm Green overlay at 60% opacity, layered immediately above the background. This ensures all UI is readable without obscuring the tropical scene.

The overlay sits BEHIND all foreground UI (AppBar, panels, scorecard, dartboard emulator, modals). Do NOT remove or weaken this overlay.

### Menu Screen
- **Background:** Illustrated tropical background + Palm Green 60% overlay
- **AppBar:** Palm Green background, Sand White title "TIKI GOLF GAME SETUP" in Boogaloo 36pt, Tiki Brown bottom border
- **Settings Boxes:** Palm Green at 0.9 opacity background, Tiki Brown 2px border, 8px border radius, 12px internal padding
- **Segmented Toggles:** Lagoon Blue active segment, Sand White inactive, Boogaloo 16pt Bold labels
- **TeamPlayerListPanel:** Tiki Brown border, Palm Green background at 0.85 opacity
- **TEE OFF Button:** Lagoon Blue background, Sand White Boogaloo 20pt text, full-width, 12px border radius
- **Description Panel (left):** Palm Green at 0.8 opacity background, Sand White Nunito 14-16pt body text

### Game Screen
- **Background:** Same illustrated background + Palm Green 60% overlay
- **AppBar:** Palm Green background, Sand White title `'TIKI GOLF'` in Boogaloo 36pt with 4-corner Tiki Brown outline shadow (same font style as the Menu and Results AppBars). Hole name + target number are surfaced below the AppBar in the active-player / scorecard panels — NOT in the AppBar title.
- **Active Player Panel:** Tiki Brown border, Palm Green 0.9 opacity background; shows avatar + name + running total (Solo) or team logo + team name + active player + team total (Team)
- **Dart Row:** Max Darts indicator slots (3-6 dynamic), Tiki Brown border, dart hit/miss indicators. Skip Turn button (Hibiscus Pink) always visible. Mulligan button (Tiki Brown, tiki mask icon + "1x" badge) visible when Mulligan ON.
- **Scorecard Panel:** Palm Green 0.85 opacity background, Tiki Brown border, alternating Coconut Cream/Palm Green rows, score cells colored by stroke count (Lagoon Blue = birdie, Sand White = par, Hibiscus Pink = bogey, Tropical Orange = splash)
- **Hole Image:** Themed hole image displayed in the active area (volcano, waterfall, etc. — randomly assigned at game start)
- **Dartboard Emulator:** Tiki Brown border, Palm Green background for disabled overlay

### Results Screen
- **Background:** Same illustrated background + Palm Green 60% overlay
- **AppBar:** Palm Green background, Sand White title `'TIKI GOLF RESULTS'` in Boogaloo 36pt with 4-corner Tiki Brown outline shadow (identical font style to Menu and Game AppBars).
- **Winner Display (Solo):** Golden Tiki trophy image (GoldenTiki.png), large Boogaloo "GOLDEN TIKI CHAMPION!" headline in Sand White
- **Winner Display (Team):** Winning team's crest image (large, 120×120), team name in Boogaloo 36pt, team color accent
- **Stats Panel:** Palm Green 0.9 opacity background, Tiki Brown border, scorecard with all players' hole-by-hole scores
- **Action Buttons:** PLAY AGAIN (Lagoon Blue), CHANGE SETTINGS (Tiki Brown), LEAVE (Sand White outline)

## Animations

### Birdie Celebration
- **Type:** Short particle burst (tropical confetti)
- **Duration:** 600ms
- **Usage:** Triggered when player hits target on dart 1

### Splash Animation
- **Type:** Water splash ripple from hole image area
- **Duration:** 400ms
- **Usage:** Triggered when all darts missed (Splash result)

### Scorecard Update
- **Type:** Fade-in of score cell with color
- **Duration:** 300ms
- **Usage:** Each time a player's hole score is confirmed

### Hole Transition
- **Type:** Slide-in of new hole image from right
- **Duration:** 400ms
- **Usage:** When advancing to the next hole

## Button Styles

### Primary Button (TEE OFF, USE MULLIGAN)
- **Background:** Lagoon Blue `#00B4D8`
- **Text:** Sand White `#FFF5E1`, Boogaloo 20pt
- **Border:** None
- **Shape:** `BorderRadius.circular(12)`

### Secondary Button (NEXT PLAYER, CHANGE SETTINGS)
- **Background:** Hibiscus Pink `#FF69B4`
- **Text:** Sand White `#FFF5E1`, Boogaloo 18pt
- **Border:** None
- **Shape:** `BorderRadius.circular(12)`

### Tertiary Button (SKIP TURN, LEAVE)
- **Background:** Tiki Brown `#8B5E3C`
- **Text:** Sand White `#FFF5E1`, Boogaloo 16pt
- **Border:** `1px Sand White`
- **Shape:** `BorderRadius.circular(8)`

### Disabled Button
- **Background:** Same as active variant
- **Text:** Same as active variant
- **Opacity:** 0.50

### Mulligan Button (special)
- **Background:** Tiki Brown `#8B5E3C`
- **Icon:** Tiki mask (32×32)
- **Text:** "Mulligan" in Boogaloo 14pt Sand White
- **Badge:** "1x" badge in Tropical Orange `#FF8C42`, Boogaloo 12pt
- **Shape:** `BorderRadius.circular(8)`
- **State enabled:** Full opacity, active when Splash result + mulligan available
- **State disabled:** 50% opacity when mulligan unavailable or not on Splash result

## Responsive Design Notes

- The scorecard panel shrinks gracefully for 16-player team games — hole-score cells compress to 28px wide with abbreviated player names.
- Dart indicator slots scale at 5 or 6 darts — slot height shrinks slightly to keep the panel within 200px width.
- The TeamPlayerListPanel uses scroll within its bounded panel when the player list overflows (same as Target Tag).
- All layouts are tested on 1280×800 (tablet landscape) and 1920×1080 (desktop landscape). No layout scrolls at either resolution.
