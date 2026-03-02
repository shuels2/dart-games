# Reef Royale — Design System

## Theme Philosophy

Vibrant underwater reef aesthetic with ocean-inspired colors, coral imagery, and sea creature characters. Warm and family-friendly with bright accents against deep ocean backgrounds.

## Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| **Deep Reef Blue** | `#0B3D91` | Primary background, containers |
| **Seafoam Green** | `#48D1CC` | Primary accent, borders, claimed indicators |
| **Sunlit Aqua** | `#00CED1` | Secondary accent, neighbor hit indicators |
| **Pearl White** | `#FFF8F0` | Text, icons |
| **Sandy Gold** | `#F4D03F` | Pearl scoring, claimed coral indicators |
| **Coral Pink** | `#FF6B6B` | Cursed Tide mode, miss indicators, skip button |
| **Bioluminescent Purple** | `#9B59B6` | Buff system accents |

## Status Colors

| Status | Color | Usage |
|--------|-------|-------|
| Direct hit | Seafoam Green | Dart indicator border |
| Neighbor hit | Sunlit Aqua | Dart indicator border |
| Pearl scored | Sandy Gold (70% opacity) | Dart indicator border |
| Coral claimed | Sandy Gold | Dart indicator border |
| Miss / non-target | Coral Pink (50% opacity) | Dart indicator border |
| Multi-target hit | Pulsing glow | Shared neighbor animation |

## Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| Screen title | Fredoka | 54pt | Bold |
| Section headers | Fredoka | 34pt | Bold |
| Player name | Fredoka | 18pt | Bold |
| Pearl/coral counts | Fredoka | 20-22pt | Bold |
| Body text | Nunito | 18pt | Regular |
| Badges (CURSED/BUFFS/NEIGHBORS) | Fredoka | 14pt | Bold |
| Dart indicator text | Fredoka | 14pt | Bold |
| Button text | Fredoka | 16-18pt | Bold |

## AppBar

- **Gradient:** Deep Reef Blue → Seafoam Green (left to right)
- **Title:** "REEF ROYALE" with seafoam green glow and dark drop shadow
- **Center:** Round progress bar
- **Right of progress bar:** Option badges (CURSED in coral pink, NEIGHBORS in sandy gold, BUFFS in seafoam green)

## Screen Layouts

### Menu Screen
- **Left panel:** How to Play description, Game Modes, Beginner Tips
- **Right panel:** Game options (dropdowns, toggles, slider), player list, Dive In button
- **Background:** Deep Reef Blue with reef background image

### Game Screen
- **Left (200px):** Active player panel — avatar, creature, pearl/coral counts, dart indicators, skip button, hints
- **Center:** Coral tracker grid (7 coral cards with claim state)
- **Bottom:** Opponent summary bar
- **Dartboard:** Emulator section or real dartboard input

### Results Screen
- **Center:** Winner creature image (responsive sizing), winner name, pearl/coral stats
- **Rankings:** All player standings
- **Actions:** Play Again, Change Settings, Back to Menu

## Animations

- **Coral bloom:** Visual state change when claimed (unclaimed → claimed image)
- **Pulsing glow:** Shared neighbor multi-target hits
- **Confetti:** Victory screen celebration
- **Buff banner:** Slide-in announcement when buff activates
