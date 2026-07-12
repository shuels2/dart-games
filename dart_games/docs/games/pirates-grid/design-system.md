# Pirate's Grid - Design System

## Theme Philosophy

Pirate's Grid channels the feel of Pirates of the Caribbean poster art meets hand-drawn treasure maps. Parchment paper textures, weathered edges, compass rose decorations, and ink-drawn illustrations create an old-world adventure atmosphere that is exciting and accessible. Characters are expressive cartoon pirate captains — always family-friendly and whimsical, never dark or threatening. The grid itself is rendered as a section of a treasure map, with cells that look like aged parchment waiting to be claimed.

**Key Style Words:** Weathered, adventurous, hand-drawn, parchment, inked, bold, warm, nautical, whimsical, treasure

## Color Palette

### Primary Colors
- **Parchment Tan:** `#F5E6C8` — Primary backgrounds, card surfaces, text panels, empty cell backgrounds
- **Ocean Navy:** `#1B2838` — Deep backgrounds, AppBar, contrast panels, player panel backgrounds
- **Treasure Gold:** `#DAA520` — Headers, titles, achievement highlights, winner crown, score text

### Player Colors
- **Blood Red:** `#8B0000` — Player 1 flag color, P1 accents, winning badge, danger state
- **Sea Foam Teal:** `#2E8B8B` — Player 2 flag color, P2 accents, secondary highlights

### Supporting Colors
- **Ink Black:** `#1A1A1A` — Text, borders, grid lines, hand-drawn element outlines
- **Compass Rose Bronze:** `#CD7F32` — Buttons, positive states, secondary accents, borders
- **Worn Leather Brown:** `#8B4513` — Secondary backgrounds, panel borders, grid frame

### Color Usage Summary
| Color | Primary Use |
|-------|-------------|
| `#F5E6C8` Parchment Tan | Cell backgrounds (0.9 opacity), left panel bg, results cards |
| `#1B2838` Ocean Navy | AppBar, right panel bg (0.85 opacity), round tracker bg (0.8 opacity) |
| `#DAA520` Treasure Gold | All headers/titles, score displays, winning glow, action buttons |
| `#8B0000` Blood Red | P1 flag/name, Steal Mode badge, Port Home button, danger states |
| `#2E8B8B` Sea Foam Teal | P2 flag/name, "D" difficulty badges, secondary highlights |
| `#1A1A1A` Ink Black | All body text, grid lines, cell borders |
| `#CD7F32` Compass Rose Bronze | Start button, settings box borders, FAB, skip turn button, "T" badges |
| `#8B4513` Worn Leather Brown | Grid frame border, secondary panel borders |

## Typography

### Font Families
- **Primary Display Font:** `GoogleFonts.pirataOne` — Used for all headers, titles, game terms, scores, buttons, AppBar titles, player names
- **Body Font:** `GoogleFonts.lora` — Used for descriptive text, instructions, how-to-play content, body paragraphs

**Why Pirata One + Lora:** Pirata One is a decorative blackletter font that instantly evokes pirate maps and old-world adventure — perfect for any prominent text. Lora is an elegant serif that reads well at body text sizes and complements the treasure map aesthetic. Both are Google Fonts.

### Text Styles
| Element | Font | Size | Color | Notes |
|---------|------|------|-------|-------|
| Game Title (AppBar) | Pirata One | 35pt | Treasure Gold | letterSpacing: 1.5, Ink Black shadow |
| Screen Title (AppBar) | Pirata One | 35pt | Treasure Gold | All three AppBars identical style |
| Section Headers | Pirata One | 24-28pt | Treasure Gold | |
| Player Names | Pirata One | 20pt | Blood Red (P1) / Sea Foam Teal (P2) | Bold |
| Score/Status | Pirata One | 36-44pt | Treasure Gold | |
| Cell Target Label | Pirata One | 18pt | Treasure Gold | Inside each grid cell |
| Round Tracker | Pirata One | 16pt | Parchment Tan | P1 wins in Blood Red, P2 wins in Sea Foam Teal |
| Timer Display | Pirata One | 24pt | Gold/Bronze/Red (changes) | See Speed Play section |
| Button Labels | Pirata One | 18-22pt | Parchment Tan | On Compass Rose Bronze bg |
| Body Text | Lora | 14-18pt | Parchment Tan / Ink Black | How-to-play, descriptions |

**IMPORTANT: All 3 AppBars (Menu, Game, Results) MUST use identical title styling:** Pirata One, 35pt, Treasure Gold, letterSpacing: 1.5, Ink Black shadow. Title strings: Menu = "PIRATE'S GRID GAME SETUP", Game = "PIRATE'S GRID", Results = "PIRATE'S GRID RESULTS".

## Screen-by-Screen Styling

### Menu Screen
- **Background:** Ocean Navy at 0.8 opacity over parchment background image
- **AppBar:** Ocean Navy (`#1B2838`) with Treasure Gold title text
- **Left Panel (How to Play):** Scrollable, Ocean Navy at 0.8 opacity, Lora body text in Parchment Tan
- **Settings Boxes:** 2 rows of 2 boxes; each box has Compass Rose Bronze 2px border, Ocean Navy 0.9 opacity background, Pirata One label text
- **DualPlayerListPanel:** Fits between settings and start button; max 2 players enforced
- **Start Button ("SET SAIL!"):** Compass Rose Bronze background, full width of right panel, 50% opacity when disabled (fewer than 2 players)

### Game Screen
- **Background:** Parchment/treasure map background image with dark overlay
- **AppBar:** Ocean Navy with Treasure Gold title
- **Active Player Panel (left, 200px):** Ocean Navy at 0.85 opacity, 2px Compass Rose Bronze border
  - Player avatar (80x80, circular, player photo — NOT game character)
  - Player name: Pirata One 20pt, Blood Red (P1) or Sea Foam Teal (P2)
  - Flags counter: flag icon + "X planted" in Pirata One 16pt Parchment Tan
  - Dart indicators: 3 slots; empty = outlined circle (Compass Bronze border), thrown = filled (Bronze=success, Blood Red=miss)
  - Skip Turn button: Compass Rose Bronze outline, Pirata One 14pt
- **Grid Cells:** 3x3, each cell ~160x160px with 6px margins
  - Background: Parchment Tan at 0.9 opacity, 2px Ink Black border, 4px border radius
  - Empty: empty_square.png (parchment with faint "X")
  - P1 claimed: flag_red.png with Blood Red 2px border glow
  - P2 claimed: flag_teal.png with Sea Foam Teal 2px border glow
  - Winning cells: Treasure Gold pulsing glow + sparkle overlay
  - Grid frame: Worn Leather Brown 3px slightly irregular border (hand-drawn effect)
- **Round Score Tracker (conditional, Best Of > 1):** Ocean Navy 0.8 opacity pill, 1px Compass Rose Bronze border, centered above grid
- **Steal Mode Badge (conditional):** Blood Red pill, crossed-swords icon + "STEAL MODE" text, centered below grid

### Results Screen
- **Background:** Treasure map bg with dark overlay
- **Winner Section:** Centered card — winner title (Pirata One 36pt Treasure Gold), winner avatar (120x120 with golden border and coin animation), player name (Pirata One 28pt Parchment Tan), stats (Pirata One 20pt Treasure Gold)
- **Rankings:** 2-player list; winner marked with Compass Rose Bronze "WIN" badge
- **Action Buttons:**
  - "SET SAIL AGAIN" (Play Again): Compass Rose Bronze background
  - "NEW VOYAGE" (Change Settings): Treasure Gold background
  - "PORT HOME" (Back to Home): Blood Red background

## Animations

### Flag Plant Animation
- **Type:** Scale + bounce (scale from 0 to 1 with slight overshoot)
- **Duration:** ~300ms
- **Usage:** When a player successfully claims a grid cell
- **Sound:** Flag Plant sound plays simultaneously

### Winning Line Glow
- **Type:** Pulsing Treasure Gold glow on all 3 cells in the winning line
- **Duration:** Continuous until screen changes (~1s pulse cycle)
- **Usage:** When 3-in-a-row is detected; sparkle overlay added to each winning cell

### Speed Play Timer Pulse
- **Type:** Scale pulse at 2-0 seconds (Blood Red phase)
- **Duration:** 0.5s per pulse cycle
- **Usage:** Final 2 seconds of the Speed Play timer to alert the player

### Steal/Mutiny Animation
- **Type:** Cross-fade between flag images with shake effect
- **Duration:** ~400ms
- **Usage:** When Steal Mode replaces an opponent's flag

## Button Styles

### Primary Button (SET SAIL!, action buttons)
- **Background:** Compass Rose Bronze (`#CD7F32`)
- **Text:** Parchment Tan (`#F5E6C8`), Pirata One, 18-22pt
- **Border:** None
- **Shape:** BorderRadius.circular(8)

### Secondary Button (outline style, Skip Turn)
- **Background:** Transparent
- **Text:** Compass Rose Bronze, Pirata One, 14pt
- **Border:** 1px Compass Rose Bronze
- **Shape:** BorderRadius.circular(8)

### Disabled Button
- **Background:** Same as enabled
- **Text:** Same as enabled
- **Opacity:** 0.5

### Results Buttons
- "SET SAIL AGAIN": Compass Rose Bronze bg
- "NEW VOYAGE": Treasure Gold bg
- "PORT HOME": Blood Red bg
- All: Parchment Tan text, Pirata One font, BorderRadius.circular(8)

## Responsive Design Notes

- Settings boxes use `Expanded` widgets in rows to fill available width
- Grid cells use `Flexible` sizing to adapt to screen width while maintaining square aspect ratio
- DualPlayerListPanel fills all remaining vertical space between settings and start button
- AppBar height is standard Flutter AppBar (no custom height)
- Game screen uses a fixed 200px active player panel on the left; remainder is the grid area
- All text uses Pirata One except how-to-play body text (Lora), ensuring consistent font rendering
