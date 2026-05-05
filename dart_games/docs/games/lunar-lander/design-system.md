# Lunar Lander - Design System

## Theme Philosophy

Lunar Lander draws inspiration from 1960s NASA propaganda posters combined with Pixar's Wall-E warmth. The visual style is bold retro color-blocking, rounded friendly spacecraft, star-filled backgrounds with a warm nostalgic glow. The moon surface is inviting and cartoonish rather than cold or scary. Characters are cute astronaut animals in retro spacesuits with fishbowl helmets, creating a family-friendly space adventure aesthetic.

**Key style words:** Retro, warm, rounded, nostalgic, adventurous, hopeful, bold, starlit, friendly

## Color Palette

### Primary Colors

| Color Name | Hex | Usage |
|-----------|-----|-------|
| Space Black | `#0D1B2A` | Primary background, deep space |
| Earth Blue | `#1B4965` | Panels, headers, AppBar backgrounds |
| Rocket Silver | `#C0C0C0` | Text, UI chrome, panel borders |

### Supporting Colors

| Color Name | Hex | Usage |
|-----------|-----|-------|
| Star White | `#FAFDF6` | Primary text, stars, highlights |
| Moon Dust Gray | `#D4C5A9` | Moon surface, landing zone, secondary text |
| Mission Green | `#52B788` | Success states, safe landing, positive feedback |
| Thruster Red | `#E63946` | Warnings, bust/crash states, negative altitude readout |

### Special Colors

| Color Name | Hex | Usage |
|-----------|-----|-------|
| Rocket Flame | `#F26430` | Active states, rocket flames, accents, primary buttons |

**IMPORTANT — Color substitution note:** The spec (Section 2) calls this accent color "Flame Orange" with hex `#FF6B35`. However, `#FF6B35` is the container app's reserved **Flame Orange** token used globally across all games. To avoid collisions with the container's token, Lunar Lander uses **`#F26430`** ("Rocket Flame") everywhere the spec calls for `#FF6B35`. The visual appearance is nearly identical (both are warm orange), but the hex is different to maintain token separation. Always use `#F26430` in Lunar Lander code — never `#FF6B35`.

## Typography

### Font Families

- **Primary/Display Font:** `GoogleFonts.orbitron` — Geometric, futuristic display font capturing the space-age digital readout aesthetic. Used for headers, UI labels, player names, scores, and all AppBar titles.
- **Body Font:** `GoogleFonts.exo2` — Contemporary sans-serif with subtle futuristic character. Excellent readability for body text, descriptions, and turn summaries.

### Text Styles

| Element | Font | Weight | Size | Color |
|---------|------|--------|------|-------|
| AppBar Title | Orbitron | Bold | 32pt | Star White, letterSpacing: 1.5, orange glow shadow |
| Game Title (results) | Orbitron | Bold | 36pt | Rocket Flame |
| Section Headers | Orbitron | Bold | 28-32pt | Star White |
| Player Names (game) | Orbitron | Bold | 20pt | Rocket Flame |
| Score/Altitude Numbers | Orbitron | Bold | 36-44pt | Star White |
| Button Labels | Orbitron | Bold | 18-22pt | Star White on colored background |
| Body Text | Exo2 | Regular | 14-18pt | Star White |
| Turn Summary Text | Exo2 | Regular | 14pt | Moon Dust Gray |
| Descent Track Labels | Orbitron | Regular | 10pt | Star White |

**CRITICAL:** All 3 AppBars (Menu, Game, Results) MUST use identical title styling: Orbitron Bold, 32pt, Star White, letterSpacing: 1.5, with orange glow shadow. Consistent font size is required across all screens.

## Screen-by-Screen Styling

### Menu Screen

- **Background:** Space background image (`LunarLander-Background.png`) with dark overlay
- **AppBar:** Earth Blue (`#1B4965`) background, Orbitron 32pt Bold Star White title with orange glow
- **Left Panel:** Earth Blue at 0.8 opacity, scrollable game description
- **Settings Boxes:** Earth Blue border (2px), Space Black background at 0.9 opacity, 12px internal padding
- **Start Button (LAUNCH!):** Rocket Flame (`#F26430`) background, full width, Orbitron Bold 22pt
- **Player Tiles:** Earth Blue background

### Game Screen

- **Background:** Space background image with dark overlay
- **AppBar:** Earth Blue background, identical to Menu AppBar
- **Active Player Panel:** Earth Blue at 0.85 opacity with 2px Rocket Flame border, 200px wide
- **Descent Tracks:** Space Black at 0.6 opacity, 1px Rocket Silver border, 80px wide per player
- **Altitude Readout (normal):** Star White, Orbitron 16pt
- **Altitude Readout (negative, Hard Landing OFF):** Thruster Red, Orbitron 16pt
- **Hard Landing Badge:** Thruster Red (`#E63946`) pill background, Orbitron 12pt Bold, Star White text
- **Dart Indicators (hit):** Mission Green filled circle, Orbitron 12pt score text
- **Dart Indicators (miss):** Moon Dust Gray filled circle
- **Dart Indicators (crash/bust):** Thruster Red, explosion icon
- **Skip Turn Button:** Rocket Flame outline button, Orbitron 14pt
- **Active Rocket:** Rocket Flame glow animation on active player's rocket
- **Inactive Rockets:** 70% opacity

### Results Screen

- **Background:** Space background with dark overlay
- **AppBar:** Earth Blue background, identical to Menu/Game AppBars
- **Winner Panel:** "MISSION ACCOMPLISHED!" in Orbitron 36pt Bold, Rocket Flame
- **Winner Avatar:** 120x120, circular, 3px Rocket Flame border
- **Rankings:** Alternating Earth Blue / Space Black rows, Exo2 16pt Star White
- **Winner Row:** Rocket Flame border highlight
- **Play Again Button (RELAUNCH):** Mission Green (`#52B788`)
- **Change Settings Button (CHANGE MISSION):** Earth Blue (`#1B4965`)
- **Back to Home Button (MISSION CONTROL):** Thruster Red (`#E63946`)

## Animations

### Active Rocket Flame Trail
- **Type:** Pulsing glow animation
- **Usage:** Active player's rocket icon on the descent track
- **Effect:** Rocket Flame color glow that pulses to indicate the current player

### Descent Line Shrink
- **Type:** Height reduction
- **Usage:** The descent track line visually shrinks as the rocket descends, reinforcing the countdown to landing

### Crash Animation (Hard Landing ON bust)
- **Type:** Shake + fade explosion overlay
- **Usage:** Triggered when a dart brings altitude below 0 with Hard Landing ON
- **Effect:** Rocket shakes, small explosion puff appears, rocket pulls back up to pre-turn altitude

## Button Styles

### Primary Button (LAUNCH!, RELAUNCH)
- **Background:** Rocket Flame `#F26430` (LAUNCH!) or Mission Green `#52B788` (RELAUNCH)
- **Text:** Star White, Orbitron Bold
- **Shape:** 8px border radius
- **Padding:** 12px vertical, 24px horizontal

### Secondary Button (CHANGE MISSION)
- **Background:** Earth Blue `#1B4965`
- **Text:** Star White, Orbitron Bold 18pt
- **Shape:** 8px border radius

### Danger Button (MISSION CONTROL)
- **Background:** Thruster Red `#E63946`
- **Text:** Star White, Orbitron Bold 18pt
- **Shape:** 8px border radius

### Disabled Button (LAUNCH! with < 2 players)
- **Opacity:** 50%

## Character Images

The 8 astronaut animal characters are displayed as native images WITHOUT circle clipping. The characters have transparent backgrounds and are used directly as rectangular (or naturally shaped) PNGs. This differs from games that clip character images to circles — Lunar Lander shows the full character artwork.

## Responsive Design Notes

- The descent tracks layout adapts to player count: with 2-4 players tracks are wider; with 5-8 players tracks narrow to fit horizontally. All tracks always span the same vertical height.
- The active player panel is fixed at 200px wide regardless of screen width.
- The "HARD LANDING" badge is only rendered when `hardLandingEnabled` is true — it does not occupy space otherwise.
