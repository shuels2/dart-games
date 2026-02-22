# Monster Mash - Design System

## Theme Philosophy
Monster Mash embraces a dark gothic aesthetic with supernatural elements. The design evokes a haunted laboratory where classic monsters battle for survival. Stone tablet textures, lightning effects, and health-reactive monster art create an immersive horror-themed experience.

## Color Palette

### Primary Colors
- **Midnight Navy:** `#1A1A2E` - Primary background color
- **Iron Gate:** `#2F4F4F` - Secondary background, dialog backgrounds, stone button base
- **Ecto-Green:** `#7FFF00` - Primary accent, healing indicators, selection highlights

### Supporting Colors
- **Haunted Purple:** `#4B0082` - Buttons, UI accents, dartboard FAB
- **Pumpkin Orange:** `#FF8C00` - Speed play indicators, secondary accent
- **Aged Parchment:** `#F5F5DC` - Text color, labels
- **Blood Red:** `#FF4444` - Damage indicators, health critical state

### Status Colors
- **Full Health:** `#00CC00` (Green) - Health bar above 70%
- **Weakened:** `#FFCC00` (Yellow) - Health bar 30-70%
- **Critical:** `#FF4444` (Red) - Health bar below 30%
- **Eliminated:** Faded opacity, offset down

### Color Usage Examples
```dart
// Midnight Navy - Primary background
backgroundColor: const Color(0xFF1A1A2E),

// Ecto-Green - Accents, healing
color: const Color(0xFF7FFF00),

// Iron Gate - Dialogs, cards
backgroundColor: const Color(0xFF2F4F4F),

// Haunted Purple - Buttons
backgroundColor: const Color(0xFF4B0082),
```

## Typography

### Font Families
- **Creepster:** Titles, headers, player names - Horror-themed display font
- **PirataOne:** Buttons, labels, scores - Bold pirate/adventure font
- **Montserrat:** Body text, descriptions - Clean readable font

### Text Styles
- **Screen Title:** Creepster, Bold, 28-32pt, Ecto-Green (#7FFF00)
- **Section Header:** Creepster, Bold, 20-24pt, Ecto-Green (#7FFF00)
- **Body Text:** Montserrat, Regular, 14-16pt, Aged Parchment (#F5F5DC)
- **Button Text:** PirataOne, Bold, 16-24pt, Aged Parchment (#F5F5DC)
- **Player Name:** Creepster, Bold, 16-18pt, Aged Parchment (#F5F5DC)
- **Target Number:** PirataOne, Bold, 24-36pt, Ecto-Green (#7FFF00)

### Font Usage Examples
```dart
// Screen titles
GoogleFonts.creepster(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF7FFF00),
)

// Button labels
GoogleFonts.pirataOne(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: const Color(0xFFF5F5DC),
)

// Body text
GoogleFonts.montserrat(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: const Color(0xFFF5F5DC),
)
```

## Screen-by-Screen Styling

### Menu Screen
- **Background:** Solid Midnight Navy (#1A1A2E)
- **AppBar:** Gradient (Midnight Navy to Ecto-Green flash)
- **Buttons:** Stone tablet style with jagged edges and lightning animation
- **Player Tiles:** Dark background with Ecto-Green selection highlight
- **Settings Panels:** Iron Gate cards with Ecto-Green accents
- **Start Button:** Stone button with lime lightning pulse when enabled

### Game Screen
- **Background:** Solid Midnight Navy (#1A1A2E)
- **AppBar:** Same gradient as menu screen
- **Active Player Panel (left 28%):** Monster image (flipped to face right), health bar, target shield, dart display
- **Opponent Grid (right side):** Bottom-heavy layout with perspective scaling
- **Round Progress Bar (top-center):** Current round display with buff shield indicators
- **Health Bar:** Red-to-green gradient clipped by HP percentage
- **Opponent Tiles:** Target number shield (red), health shield (green), monster image, player name

### Results Screen
- **Background:** Solid Midnight Navy (#1A1A2E)
- **Winner Display:** Monster image(s) with glow effect
- **Title Text:** "LAST MONSTER STANDING!" or "TIED!" with glow
- **Winner Name:** Creepster font with player photo
- **Confetti:** Three-directional confetti animation
- **Action Buttons:** Three stone buttons with different lightning colors

## Animations

### Lightning Effect (Stone Buttons)
- **Type:** Animated jagged line with glow
- **Duration:** Continuous loop with AnimationController
- **Usage:** Start button, results screen buttons
- **Colors:** Configurable per button (lime, orange, purple)

### Health Bar Gradient
- **Type:** Linear gradient clipped by percentage
- **Colors:** Red (#FF4444) → Yellow (#FFCC00) → Green (#00CC00)
- **Usage:** All health bar displays

### Monster Image States
- **Type:** Static image swap based on HP percentage
- **States:** FullHealth (>70%), 70Health (30-70%), 30Health (10-30%), Eliminated (0%)
- **Naming:** `{Monster}-{State}.png`

## Button Styles

### Stone Tablet Button (StoneDialogButton)
- **Shape:** Jagged/chipped edges via CustomClipper
- **Fill:** Radial stone gradient with bevel effect
- **Border:** Configurable color
- **Shadow:** Drop shadow below button
- **Lightning:** Optional animated lightning with configurable color
- **Height:** Configurable (default 48)

### Results Screen Buttons
- **Play Again:** Lime lightning (0xFF7FFF00), phase 0.0
- **Change Settings:** Orange lightning (0xFFFF8C00), phase 0.33
- **Play Another Game:** Purple lightning (0xFF4B0082), phase 0.67

## Visual Effects

### Health-Reactive Monster Art
```dart
String getMonsterImagePath(String monsterName, double healthPercentage) {
  if (healthPercentage <= 0) return '$monsterName-Eliminated.png';
  if (healthPercentage <= 0.30) return '$monsterName-30Health.png';
  if (healthPercentage <= 0.70) return '$monsterName-70Health.png';
  return '$monsterName-FullHealth.png';
}
```

### Buff Shield Indicators
- **Heal Shield (left):** Green shield showing heal buff info
- **Damage Shield (right):** Red shield showing damage buff info
- **Buff Label:** Description text below progress bar

## Responsive Design Notes
- Opponent grid uses perspective scaling (0.75x-1.25x) for depth effect
- Active player panel fixed at 28% screen width
- Grid columns adjust based on opponent count (1-7 opponents)
- Minimum tile size enforced for readability
- Monster images scale proportionally with tile size
