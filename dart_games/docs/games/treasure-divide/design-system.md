# Treasure Divide - Design System

## Theme Philosophy

Treasure Divide captures the spirit of Treasure Planet meets Sea of Thieves cartoon mode — bright tropical colors, hand-drawn treasure maps, and cheerful pirate vibes. The twist is that the "characters" are the players themselves: each player's own avatar photo is dressed up at game time with themed pirate accessories drawn from 8 distinct themes. The vibe is adventurous and fun — treasure chests overflowing with gold, tropical islands, and X-marks-the-spot maps. Family-friendly pirates — no scary skulls, just fun adventures.

**Key Style Words:** Tropical, adventurous, treasure, map, island, cheerful, golden, nautical, family-friendly, cartoon pirate

## Color Palette

### Primary Colors

- **Treasure Gold:** `#FFD700` — Primary highlight, coins, scores, success states, active borders, score displays
- **Ocean Teal:** `#008B8B` — Primary background, AppBar fill, panels, active player panel background, settings box background
- **Plank Brown:** `#8B6914` — Cards, panels, wooden surfaces, settings box borders, player strip background overlay

### Supporting Colors

- **Sail White:** `#FFF8E7` — Body text, labels, button text, clean surfaces; inactive toggle segments
- **Blood Red:** `#C41E3A` — Danger states, halved score flash, "HALVED!" overlay text, "QUARTERED!" text, Quarter It badge background, the "DOCK HOME" button
- **Island Green:** `#228B22` — Success/hit indicators, "SAIL AGAIN" button background, positive round status pills ("HIT!" / "SAFE!")

### Special Colors

- **Team crest colors** (one per crew, pulled from the 6 crest palette):
  - Crest 1 — Crossed Cutlasses: Blood Red `#C41E3A`
  - Crest 2 — Gold Doubloon: Treasure Gold `#FFD700`
  - Crest 3 — Compass Rose: Ocean Teal `#008B8B`
  - Crest 4 — Ship's Wheel: Plank Brown `#8B6914`
  - Crest 5 — Anchor: Sail White `#FFF8E7`
  - Crest 6 — Kraken: Island Green `#228B22`

## Typography

### Font Families

- **PirataOne** (via Google Fonts)
  - Usage: Screen titles, AppBar titles, score displays, round target, status overlays ("HALVED!"), badge text, rankings, "SET SAIL!" button label
  - Highly decorative pirate-style font — test carefully at small sizes for readability

- **Merriweather** (via Google Fonts)
  - Usage: Body text, settings labels, button labels (most action buttons), player name in panels, description text, instructions
  - Provides grounded readability to balance PirataOne's ornamentation

### Text Styles

- **Screen titles (AppBar):** PirataOne, Regular, 34pt, Treasure Gold
- **Score display (Active Player Panel):** PirataOne, Regular, 24–32pt, Treasure Gold
- **Round target display (beside current island):** PirataOne, Regular, 28–36pt, Sail White
- **Section headers:** PirataOne, Regular, 24pt, Treasure Gold
- **Body text / labels:** Merriweather, Regular, 16pt, Sail White
- **Button text (primary):** Merriweather, Bold, 18–22pt, respective foreground color
- **Badge text (QUARTER IT, CUSTOM, SOLO CREW):** PirataOne, Regular, 12pt
- **Player name in Active Panel:** PirataOne, Regular, 20pt, Treasure Gold
- **Rankings / stats:** Merriweather, Regular, 16pt, Sail White
- **Compact tile player name:** Merriweather, Bold, 12pt, Sail White
- **Compact tile score:** PirataOne, Regular, 20pt, Treasure Gold

## Screen-by-Screen Styling

### Menu Screen

- **Background:** Game background image (tropical ocean panorama) with a translucent Ocean Teal wash overlay so UI elements read clearly
- **AppBar:** Ocean Teal (`#008B8B`) background; title "TREASURE DIVIDE GAME SETUP" in PirataOne 34pt Treasure Gold; back button (left); DartboardConnectionInfo (right)
- **Left Panel (Captain's Log):** scrollable column, Ocean Teal at 0.8 opacity with Plank Brown 2px border; "CAPTAIN'S LOG" header PirataOne 24pt Treasure Gold; body Merriweather 16pt Sail White; ~40% screen width
- **Settings boxes:** Plank Brown 2px border, Ocean Teal at 0.9 opacity background, 12px internal padding; label Merriweather 16pt Sail White on left, control on right
- **TeamPlayerListPanel:** uses `TeamPlayerListPanelConfig.treasureDivide()`
- **"SET SAIL!" button:** Treasure Gold (`#FFD700`) background, Ocean Teal text, PirataOne 22pt; full width of right panel; 50% opacity when disabled

### Game Screen

- **Background:** same tropical ocean image with darker overlay (Ocean Teal at 0.6 opacity)
- **AppBar:** Ocean Teal background; title "TREASURE DIVIDE" PirataOne 34pt Treasure Gold
- **Badge row (below AppBar):**
  - Quarter It badge: Blood Red pill, "QUARTER IT" PirataOne 12pt Sail White
  - Custom badge: Treasure Gold pill, "CUSTOM" PirataOne 12pt Ocean Teal
  - Solo Crew badge: crew-color pill with 2px Treasure Gold outline, "Solo Crew: 6 darts" PirataOne 12pt Sail White (or Ocean Teal if crew color is light)
- **Active Player Panel (left, 200px):** Ocean Teal at 0.85 opacity, 2px Treasure Gold border; Pirate-themed avatar 80×80; player name PirataOne 20pt Treasure Gold; treasure display Coin icon + score PirataOne 24pt Treasure Gold; round score "+XX this round" Merriweather 14pt (Island Green for positive, Blood Red for 0); dart indicators (3 or 6 slots); Skip Turn button Treasure Gold outline
- **Treasure Map (center dominant):** parchment texture (Plank Brown at 0.9 opacity) with rope border; island markers on winding path; completed islands Island Green filled; current island pulsing Treasure Gold glow (1.4× size, star above); future islands Sail White outline; treasure chest image in lower-right corner (~25% map width); "Island X/Y" scroll label PirataOne 22pt Treasure Gold
- **Player Treasure Strip (bottom):** Plank Brown at 0.5 opacity, 1px Treasure Gold top border; ~140px tall (Solo) / ~180px tall (Team); per-player or per-crew compact tiles with Ocean Teal at 0.85 opacity background, 1px Plank Brown border, 8px border radius
- **Active player tile / active crew tile:** 2px Treasure Gold border with glow

### Results Screen

- **Background:** tropical ocean background with dark overlay (Ocean Teal at 0.7 opacity)
- **AppBar:** Ocean Teal background; title "TREASURE DIVIDE RESULTS" PirataOne 34pt Treasure Gold
- **Winner card:** centered card; "PIRATE CAPTAIN!" PirataOne 36pt Treasure Gold; 120×120 circular PirateAvatarWidget with 3px Treasure Gold border; winner name PirataOne 28pt Sail White; stats PirataOne 20pt Treasure Gold
- **Rankings:** alternating Ocean Teal / Plank Brown rows; Merriweather 16pt Sail White; winner row Treasure Gold border
- **Buttons (3):**
  - "SAIL AGAIN": Island Green background, Sail White text
  - "CHANGE COURSE": Treasure Gold background, Ocean Teal text
  - "DOCK HOME": Blood Red background, Sail White text
  - Button text style: Merriweather 18pt Bold; 12px vertical padding, 24px horizontal padding, 8px border radius

## Animations

### Halve / Quarter Animation

- **Type:** Chest tip + coin scatter + text overlay
- **Duration:** ~1,200ms
- **Usage:** Fires when a player (Solo) or crew (Team) misses all darts in a round. Treasure chest image tips over; coins scatter across the parchment; "HALVED!" or "QUARTERED!" overlays the map in PirataOne 48pt Blood Red with a shake animation. Player tile flashes red.

### Score Float (+XX Floater)

- **Type:** Float upward then fade
- **Duration:** ~800ms
- **Usage:** When the active player banks a hit, the round haul floats up from the current island toward the chest in Treasure Gold (PirataOne 36pt) then disappears as coins "drop" into the chest.

### Island Glow Pulse

- **Type:** Scale pulse (1.0 → 1.15 → 1.0)
- **Duration:** ~1,500ms per cycle (continuous while current)
- **Usage:** Current island on the treasure map continuously pulses with Treasure Gold glow to draw attention to the active target.

## Button Styles

### Primary Button ("SET SAIL!")

- **Background:** Treasure Gold `#FFD700`
- **Text:** Ocean Teal `#008B8B`, PirataOne 22pt
- **Border:** none
- **Shape:** BorderRadius.circular(8)

### Secondary Button ("SAIL AGAIN")

- **Background:** Island Green `#228B22`
- **Text:** Sail White `#FFF8E7`, Merriweather 18pt Bold
- **Border:** none
- **Shape:** BorderRadius.circular(8)

### Danger Button ("DOCK HOME")

- **Background:** Blood Red `#C41E3A`
- **Text:** Sail White `#FFF8E7`, Merriweather 18pt Bold
- **Border:** none
- **Shape:** BorderRadius.circular(8)

### Skip Turn Button (game screen)

- **Background:** transparent
- **Text:** Treasure Gold `#FFD700`, Merriweather 14pt
- **Border:** 1px Treasure Gold
- **Shape:** BorderRadius.circular(8)

### Disabled State (all buttons)

- **Opacity:** 50% on the whole button
- **Otherwise unchanged from enabled style**

## Responsive Design Notes

- Active Player Panel is fixed at 200px wide; the map and strip take the remaining width
- Player Treasure Strip is a fixed-height `SizedBox` (140px Solo, ~180px Team) so the map always takes the dominant central space
- The bottom strip scrolls horizontally if more tiles than fit at current display width (4–8 players Solo on 1080p)
- Team mode: 2–3 crew tiles fit in one row at standard tablet widths; 4–5 crews may tile into two compact half-height rows or scroll horizontally
- DartboardEmulatorSection is a `Positioned(bottom: 0)` overlay; the main layout is designed for full-height use without the emulator; when emulator is showing (~300px tall), the strip remains visible above it
