# Gladiator Arena - Design System

## Theme Philosophy

Gladiator Arena channels Disney's Hercules meets the Roman Colosseum — warm golden light, marble columns, sun-drenched arena sands, and expressive gladiator animal characters that are heroic but decidedly family-friendly. The palette is rich, celebratory, and epic, never dark or threatening. Cinzel (classical Roman lettering) pairs with Lato (clean modern body text) for typography that communicates both ancient authority and modern readability.

## Color Palette

| Color Name | Hex | Usage |
|---|---|---|
| Marble White | `#F5F0E8` | Primary text, podium surfaces, button foreground |
| Gladiator Gold | `#DAA520` | Headers, scores, laurel accents, active score values, double-hit highlight |
| Arena Sand | `#D2B48C` | Background fills, AppBar base, secondary panels, settings boxes |
| Imperial Purple | `#7B2D8E` | Active player state, podium glow border, active player name label |
| Blood Red | `#C0392B` | Bust indicator, eliminated score color, podium flash, timer under 5 s |
| Bronze | `#CD7F32` | Buttons, secondary accents, settings box borders, Skip Turn button |
| Colosseum Gray | `#8B8682` | Inactive states, disabled elements, stone textures |
| Laurel Green | `#4A7C59` | Shield Round banner gradient start, positive states, double-hit segment highlight color |

## Typography

All three AppBars (Menu, Game, Results) use **identical title styling**: Cinzel Bold, 36, Marble White, letterSpacing: 1.5, with a dark text shadow (`Colors.black54`, blurRadius 4, offset `Offset(1, 1)`). Each title `Text` widget is wrapped in `Transform.translate(offset: Offset(0, 2))` — a 2 px downward nudge because Cinzel's ascender pushes the visual baseline high in the 56 px AppBar strip. The AppBar itself is a bare `AppBar` (not `PreferredSize`).

| Element | Font | Weight | Size | Color |
|---|---|---|---|---|
| Game Title (AppBar) | `GoogleFonts.cinzel` | Bold | 36 | Marble White |
| Section Headers | `GoogleFonts.cinzel` | Bold | 28–32pt | Marble White |
| Player Names | `GoogleFonts.cinzel` | Bold | 20–24pt | Player accent color |
| Score Numbers (podium) | `GoogleFonts.cinzel` | Bold | 14pt | Gladiator Gold |
| Body Text | `GoogleFonts.lato` | Regular | 14–18pt | Marble White |
| Button Labels | `GoogleFonts.cinzel` | Bold | 18–22pt | Marble White on Bronze bg |
| Speed Play Timer | `GoogleFonts.cinzel` | Bold | 18pt | Marble White (Blood Red under 5 s) |
| Active Player Name Label | `GoogleFonts.cinzel` | Bold | 18pt | Imperial Purple |
| Double Range Indicator | `GoogleFonts.cinzel` | Bold | 12pt | Gladiator Gold |
| Goal Display | `GoogleFonts.cinzel` | Bold | 14pt | Gladiator Gold |
| Shield Banner Text | `GoogleFonts.cinzel` | Bold | 16pt | Marble White |

## Screen-by-Screen Styling

### Menu Screen

- **Background:** GladiatorArena-Background.png (Roman colosseum interior), full-width, BoxFit.cover; a translucent dark overlay sits on top to ensure UI readability
- **AppBar:** Arena Sand (`#D2B48C`) with dark overlay; back button (left), "GLADIATOR ARENA GAME SETUP" title (center), DartboardConnectionInfo (right)
- **Left Panel (How to Play):** Scrollable column, Arena Sand at 0.8 opacity, "HOW TO PLAY" header in Cinzel Bold 24pt Gladiator Gold, body in Lato 16pt Marble White, width ~40%
- **Settings Boxes:** Bronze border (2px), Arena Sand bg at 0.9 opacity, Cinzel 16pt Marble White label, 12px internal padding
- **Start Button ("ENTER THE ARENA!"):** Bronze (`#CD7F32`) background, Marble White Cinzel Bold 22pt; disabled at 50% opacity until 2+ players selected

### Game Screen

- **Background:** Same colosseum background with dark overlay
- **AppBar:** Arena Sand with dark overlay; back button triggers SaveGameModal; "GLADIATOR ARENA" title; actions (left to right from title): Speed Play timer (conditional), Skip Turn button, D1/D2/D3 dart indicators, DartboardConnectionInfo (rightmost)
- **Dart Indicators:** Empty = outlined circle Bronze border 0.5 opacity; Thrown (hit) = filled Gladiator Gold circle, Cinzel 12pt Bold score; Bust = filled Blood Red with "X"; Skipped = outlined Marble Gray 0.5 opacity
- **Skip Turn Button:** Bronze outline, "SKIP TURN" Cinzel 12pt Bold Bronze foreground, no fill
- **Shield Banner:** 40px tall, full width; Laurel Green → Arena Sand gradient; shield icon (24×24) + "Shield Round — No Knockoffs!" Cinzel 16pt Bold Marble White; centered
- **Goal Display:** "Goal: {target}" Cinzel 14pt Bold Gladiator Gold; "2x" badge when Double Finish ON (pill-shaped, Gladiator Gold)
- **Arena Podium Display:**
  - Each player shown as a vertical bar; height = (score / target) × maxPodiumHeight (clamped 0–max)
  - Podium bar color: Gladiator Gold for the active player, player accent color for others, with marble texture overlay
  - Active player: Imperial Purple 3px glow border around the entire podium, soft Gladiator Gold drop-shadow behind character image
  - Character image: 60×60, sits on top of podium bar
  - Score text: Cinzel 14pt Bold Gladiator Gold, rendered above podium column
  - Player name label (active player only): Cinzel 18pt Bold Imperial Purple, rendered below the podium on the arena floor, 8px gap from arena floor bar
  - "Double Range!" indicator (conditional): Cinzel 12pt Bold Gladiator Gold, 4px above character image, active player only when Double Finish ON and player is in range
- **Pattern A score display:** Scores shown directly on each podium as plain running totals (not prefixed with S/D/T notation)
- **Laurel Green double-hit highlight:** When the active player's final dart is a winning double, the double ring segment briefly glows Laurel Green before transitioning to the results screen
- **Elimination Zone:** 60px at bottom of center area; Blood Red at 0.15 opacity, 1px Blood Red border top; Lato 14pt Blood Red text; fades after 5 seconds
- **Bust indicator:** All 3 dart circles flash Blood Red simultaneously with a "BUST" badge briefly overlaid in AppBar (Cinzel 14pt Bold Blood Red on Marble White), then fade before turn advances

### Results Screen

- **Background:** Same colosseum background with dark overlay
- **AppBar:** "GLADIATOR ARENA RESULTS" in Cinzel Bold 36 Marble White; Arena Sand with dark overlay
- **Winner Display:** "CHAMPION OF THE ARENA!" in Cinzel 36pt Gladiator Gold with shadow; centered Row of winner character image (left, 270×270 with Gladiator Gold drop-shadow glow + golden laurel wreath overlay) and winner player photo / fallback initial (right, 270×270 ClipOval); winner name Cinzel Bold 28pt Gladiator Gold; final score Cinzel 20pt Marble White
- **Rankings:** Rank 1 Gladiator Gold, rank 2 Marble White, rank 3 Bronze, rank 4+ Colosseum Gray; 2-column layout for 5–8 players (left ranks 1–4, right ranks 5–8)
- **Knockoff Stats:** Lato 14pt, Arena Sand bg at 0.6 opacity; shown only if at least one knockoff occurred
- **Buttons:** "FIGHT AGAIN" Bronze; "CHANGE RULES" Imperial Purple; "LEAVE ARENA" Blood Red

## Animations

### Active Player Glow
- **Type:** Static Imperial Purple border (3px) around active player's podium — always visible during the active turn, no pulsing
- **Usage:** Surrounds the active player's podium throughout their turn

### Character Active Glow (Shape-Conformal)
- **Type:** `ImageFiltered` + `ColorFiltered` compositing — applies a colored glow that follows the character silhouette rather than the bounding box
- **Usage:** Gladiator Gold soft shadow behind character image when player is active

### Knockoff Podium Collapse
- **Type:** AnimatedContainer height reduction to 0 + shake effect on character image (dizzy animation)
- **Duration:** ~400ms collapse + brief shake
- **Usage:** When a player is knocked off; score shows "0" in Blood Red

### Bust Flash
- **Type:** All three dart circles flash Blood Red with "BUST" badge overlaid in AppBar
- **Duration:** ~600ms flash then fade
- **Usage:** When a player's turn is voided by a bust

### Podium Height
- **Type:** AnimatedContainer height (proportional to score/target ratio)
- **Duration:** Standard Flutter implicit animation (~200ms)
- **Usage:** Every time a player's score changes; podium bar height updates smoothly

## Button Styles

### Primary / Start Button ("ENTER THE ARENA!")
- **Background:** Bronze (`#CD7F32`)
- **Text:** Marble White, Cinzel Bold, 22pt
- **Shape:** RoundedRectangleBorder, radius 8
- **Disabled:** 50% opacity (before 2+ players selected)

### Results Action Buttons
- "FIGHT AGAIN": Bronze background, Marble White text, Cinzel 18pt
- "CHANGE RULES": Imperial Purple background, Marble White text, Cinzel 18pt
- "LEAVE ARENA": Blood Red background, Marble White text, Cinzel 18pt

### Skip Turn Button (In-Game)
- **Background:** Transparent
- **Text:** Bronze foreground, Cinzel 12pt Bold
- **Border:** Bronze outline

## Responsive Design Notes

- **Podium width:** `(availableWidth - margins) / playerCount`, clamped min 80px, max 150px; adapts automatically for 2–8 players
- **Rankings (5–8 players):** Switches from single column to a `Row` of two `Expanded(Column(...))` children separated by a 12–16px `SizedBox` — same pattern as Lunar Lander and Reef Royale — to ensure all ranking rows fit without scrolling on tablet portrait
- **Winner card row:** Both character image and player photo are 270×270; on narrow widths both slots scale together to maintain balance
