# Clockwork Quest - Design System

## Visual Identity

Clockwork Quest follows a **Steampunk Clocktower** theme inspired by Hugo (2011) and the sky-city warmth of Bioshock Infinite, but entirely family-friendly. Think brass and copper machinery, Victorian mechanical aesthetics, warm amber lighting, and intricate gear mechanisms.

**Key Style Words:** Warm, brass, mechanical, Victorian, intricate, amber-lit, whimsical engineering, cozy industrial

## Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Brass Gold** | `#C5A54E` | Primary accents, gear elements, active states |
| **Copper Rose** | `#B87333` | Secondary accents, pipe elements, warm highlights |
| **Dark Iron** | `#2C2C34` | Primary background, deep panels |
| **Steam White** | `#F5F0E8` | Text, labels, steam effects |
| **Mahogany Brown** | `#4E2728` | Tertiary backgrounds, wood panels |
| **Amber Glow** | `#FFBF00` | Score highlights, achievement effects, active gear |
| **Verdigris Green** | `#43B3AE` | Buttons, positive states, success indicators |
| **Rivet Silver** | `#8A8D93` | Inactive states, disabled elements, locked gears |

### Color Application

**Backgrounds:**
- Primary: Dark Iron (`#2C2C34`)
- Panels: Mahogany Brown (`#4E2728`) with Brass Gold borders

**Text:**
- Primary: Steam White (`#F5F0E8`)
- Highlighted: Amber Glow (`#FFBF00`)
- Active Player: Brass Gold (`#C5A54E`)

**Interactive Elements:**
- Buttons: Verdigris Green (`#43B3AE`) background, Steam White text
- Active: Brass Gold (`#C5A54E`) border/glow
- Disabled: Rivet Silver (`#8A8D93`)

**Game Elements:**
- Gears (inactive): Rivet Silver (`#8A8D93`)
- Gears (active): Brass Gold (`#C5A54E`) with Amber Glow (`#FFBF00`)
- Progress indicators: Copper Rose (`#B87333`)

## Typography

Clockwork Quest uses **Cinzel Decorative** for all display text and **Lato** for body text.

| Element | Font | Size | Weight | Color | Letter Spacing | Shadow |
|---------|------|------|--------|-------|----------------|--------|
| Game Title | Cinzel Decorative | 40-48pt | Bold | Brass Gold | 1.5 | Dark shadow |
| AppBar Titles | Cinzel Decorative | 28pt | Bold | Steam White | 1.5 | Dark shadow |
| Section Headers | Cinzel Decorative | 24-28pt | Bold | Steam White | 1.0 | None |
| Player Names | Cinzel Decorative | 18-22pt | Bold | Player color | 0.5 | None |
| Score Numbers | Cinzel Decorative | 32-40pt | Bold | Amber Glow | 1.0 | Glow effect |
| Button Labels | Cinzel Decorative | 16-20pt | SemiBold | Steam White | 0.5 | None |
| Body Text | Lato | 14-18pt | Regular | Steam White | 0 | None |
| Small Text | Lato | 12-14pt | Regular | Steam White | 0 | None |

### Typography Guidelines

**Why Cinzel Decorative + Lato:**
- Cinzel Decorative has an ornate, Victorian serif quality perfect for steampunk headers and mechanical inscriptions
- Lato provides clean, modern readability for body text
- The contrast keeps things legible while maintaining the steampunk atmosphere

**AppBar Consistency:**
All 3 AppBars (Menu, Game, Results) use **identical title styling:**
- Font: Cinzel Decorative Bold
- Size: 28pt
- Color: Steam White (`#F5F0E8`)
- Letter Spacing: 1.5
- Shadow: Dark shadow for depth

## Visual Elements

### Gear Icons

**Inactive Gears (1-20):**
- Color: Rivet Silver (`#8A8D93`)
- Number engraved in center (Victorian serif)
- Size: 120x120 pixels
- Border: 2px Dark Iron

**Active Gears (1-20):**
- Color: Brass Gold (`#C5A54E`)
- Number glowing in Amber Glow (`#FFBF00`)
- Size: 120x120 pixels
- Glow effect: 8px Amber blur
- Animation: Gentle rotation (optional)

**Bullseye Gear (21):**
- Larger: 150x150 pixels
- Ornate filigree details
- Inactive: Rivet Silver
- Active: Polished brass/copper with radiating light beams

### Characters

8 steampunk animal characters:
1. **Cogsworth the Owl** - Wise, amber eyes, brass goggles
2. **Gizmo the Fox** - Clever, aviator cap, gear earring
3. **Piston the Cat** - Sophisticated, brass monocle, copper bowtie
4. **Sprocket the Rabbit** - Enthusiastic, top hat with gear, leather cuffs
5. **Rivet the Badger** - Tough, tool belt, welding goggles
6. **Whistle the Mouse** - Small but mighty, ear trumpet hat, copper wrench
7. **Boiler the Bear** - Strong, leather apron, pressure gauge badge
8. **Ticker the Hedgehog** - Inquisitive, clockwork wings, pocket watch

All characters are rendered in warm Pixar animation style with steampunk accessories on bright green backgrounds (removed for transparency).

## Layout Patterns

### Menu Screen
- Background: Dark Iron with gear overlay
- Settings: 2x2 grid of brass-bordered panels
- Player list: DualPlayerListPanel on right with Copper Rose accents
- Buttons: Verdigris Green with Cinzel Decorative labels

### Game Screen
- Background: Clocktower interior (brass gears, copper pipes, amber lighting)
- Left Panel (200px): Active player info, current gear, lap counter
- Center: Gear tracker showing all gears in circular arrangement
- Bottom: Dartboard emulator

### Results Screen
- Background: Victorious clocktower scene with golden lighting
- Title: "THE CLOCKWORK CROWN!" in Brass Gold
- Winner panel: Prominent with character and glow effect
- Rankings: Brass-bordered list with Steam White text
- Buttons: WIND AGAIN, CHANGE SETTINGS, LEAVE TOWER

## Spacing & Layout

- **Panel Padding:** 16-24px
- **Item Spacing:** 12-16px vertical, 16-20px horizontal
- **Border Radius:** 8px for panels, 12px for buttons
- **Gear Grid:** 5 gears per row, 8px spacing
- **AppBar Height:** 64px

## Animation & Effects

- **Gear Activation:** Scale from 1.0 to 1.15, fade Rivet Silver to Brass Gold (300ms ease-out)
- **Advancement:** Gear pulses with Amber Glow (500ms)
- **Lap Complete:** All gears pulse sequentially (100ms each)
- **Steam Effects:** Subtle particle animation on active elements
- **Button Press:** Scale to 0.95 (100ms)

## Accessibility

- **Minimum Text Size:** 14pt for body text
- **Contrast Ratio:** All text/background combinations meet WCAG AA (4.5:1 minimum)
- **Active States:** Visual feedback via color AND size/glow changes
- **Color Blindness:** Gears use both color AND brightness changes for state
