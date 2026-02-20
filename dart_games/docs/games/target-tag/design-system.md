# Target Tag - Design System

## Theme Philosophy
Target Tag embraces a neon tech/cyberpunk aesthetic with bold, vibrant colors against dark backgrounds. The design evokes a futuristic combat arena where shields and elimination create a high-stakes survival experience. Hot Pink and Neon Green create high contrast against deep navy backgrounds for maximum visual impact.

## Color Palette

### Primary Colors
- **Hot Pink:** `#FF007A` - Primary action color, borders, Tagged In indicators, elimination warnings
- **Neon Green:** `#00FFA3` - Secondary action color, shields, success states, accents
- **Dark Navy:** `#0A1929` - Primary background color

### Supporting Colors
- **Slate:** `#475569` - Secondary UI elements, disabled states
- **Dark Slate:** `#1E293B` - Card backgrounds, overlays
- **Midnight Navy:** `#0F172A` - Deep contrast for dialogs

### Status Colors
- **Tagged In:** `#FF007A` (Hot Pink) - Player is in attack mode
- **Eliminated:** `#EF4444` (Red) - Player is eliminated (strikethrough)
- **Vulnerable:** `#FF007A` (Hot Pink) - Player at 0 shields
- **Low Shields:** `#F59E0B` (Amber) - Player at 1 shield
- **Shield Build:** `#00FFA3` (Neon Green) - Shield gains

### Color Usage Examples
```dart
// Hot Pink - Primary actions, Tagged In
backgroundColor: const Color(0xFFFF007A),
borderColor: const Color(0xFFFF007A),

// Neon Green - Shields, success
color: const Color(0xFF00FFA3),

// Dark Navy - Background
backgroundColor: const Color(0xFF0A1929),
```

## Typography

### Font Families
- **Primary Font:** Fredoka (via Google Fonts)
  - Usage: All UI text, headers, buttons, body text
  - Style: Friendly, rounded, tech-modern aesthetic

### Text Styles
- **Screen Title:** Fredoka, Bold, 28-32pt, Neon Green (#00FFA3)
- **Section Header:** Fredoka, Bold, 20-24pt, Neon Green (#00FFA3)
- **Body Text:** Fredoka, Regular, 14-16pt, White
- **Button Text:** Fredoka, Bold, 16-18pt, White or Black
- **Shield Count:** Fredoka, Bold, 32-48pt, Neon Green (#00FFA3)
- **Player Name:** Fredoka, Bold, 16-18pt, White
- **Target Number:** Fredoka, ExtraBold, 40-60pt, White

### Font Usage Examples
```dart
// Screen titles
GoogleFonts.fredoka(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF00FFA3),
)

// Shield counts
GoogleFonts.fredoka(
  fontSize: 48,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF00FFA3),
)

// Button labels
GoogleFonts.fredoka(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

## Screen-by-Screen Styling

### Menu Screen
- **Background:** Solid Dark Navy (#0A1929)
- **AppBar:** Gradient (Deep Purple → Hot Pink) with Neon Green glow
- **Buttons:** Hot Pink background, white text, Neon Green border
- **Player Tiles:** Dark Slate background, Hot Pink when selected, player photo and name
- **Settings Panels:** Dark Slate cards with Neon Green accents

### Game Screen
- **Background:** Solid Dark Navy (#0A1929)
- **AppBar:** Same gradient as menu screen
- **Active Player Panel:** Large centered display with shield bar, target number, Hero Bonus
- **Opponent Grid:** Grid of opponent tiles with shield counts and Tagged In indicators
- **Player Tiles:** Compact tiles with photo, name, shields, target number
  - **Current Player:** Hot Pink border with glow effect
  - **Tagged In:** Hot Pink "TAGGED IN" badge
  - **Eliminated:** Red strikethrough text, 50% opacity, "ELIMINATED" overlay
  - **Vulnerable (0 shields):** Pulsing Hot Pink border
  - **Low Shields (1 shield):** Amber warning color
- **Dartboard Section:** Dark Navy background, Neon Green accents

### Results Screen
- **Background:** Solid Dark Navy (#0A1929)
- **AppBar:** Same gradient
- **Winner Display:** Large trophy icon, winner photo, confetti effect
- **Winner Name:** Fredoka ExtraBold font, Neon Green color with glow
- **Statistics:** Clean layout with Neon Green labels, white values
- **Action Buttons:** Hot Pink "Play Again", Neon Green "Change Settings"

## Animations

### Pulse Glow (Tagged In)
- **Type:** Pulsing border and shadow animation
- **Duration:** 1500ms repeat
- **Usage:** Tagged In players, current player indicator
- **Implementation:**
```dart
// Hot Pink pulsing border
BoxDecoration(
  border: Border.all(
    color: const Color(0xFFFF007A),
    width: 3,
  ),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFFFF007A).withOpacity(0.5),
      blurRadius: 10,
      spreadRadius: 2,
    ),
  ],
)
```

### Shield Bar Fill
- **Type:** Linear progress animation
- **Duration:** 500ms
- **Usage:** Shield count increases
- **Colors:** Neon Green fill, Dark Slate background

### Elimination Effect
- **Type:** Strikethrough with opacity fade
- **Duration:** 1000ms
- **Usage:** Player elimination
- **Effect:** Red line through name, opacity 50%

## Button Styles

### Primary Button (Action)
- **Background:** Hot Pink (#FF007A)
- **Text:** White, Fredoka Bold, 16-18pt
- **Border:** 2px Neon Green (#00FFA3)
- **Shape:** BorderRadius.circular(8)
- **Hover:** Glow effect

### Secondary Button (Alternative Action)
- **Background:** Neon Green (#00FFA3)
- **Text:** Dark Navy (#0A1929), Fredoka Bold, 16-18pt
- **Border:** 2px Hot Pink (#FF007A)
- **Shape:** BorderRadius.circular(8)
- **Hover:** Glow effect

### Tertiary Button (Cancel/Back)
- **Background:** Slate (#475569)
- **Text:** White, Fredoka, 16pt
- **Border:** 2px Neon Green (#00FFA3)
- **Shape:** BorderRadius.circular(8)

### Disabled Button
- **Background:** Dark Slate at 50% opacity
- **Text:** White at 30% opacity
- **Border:** Slate at 30% opacity
- **Opacity:** 0.5

## Player Tile Visual States

Target Tag uses complex visual states to communicate game status:

### Normal State (Building Shields)
- Border: Transparent or subtle gray
- Background: Dark Slate
- Opacity: 100%
- Shield count: White text

### Current Player
- Border: Hot Pink (#FF007A) with pulse glow
- Background: Dark Slate
- Opacity: 100%
- Badge: "YOUR TURN" in Hot Pink

### Tagged In
- Border: Hot Pink (#FF007A)
- Background: Dark Slate
- Opacity: 100%
- Badge: "TAGGED IN" in Hot Pink background
- Glow: Hot Pink shadow pulse

### Eliminated
- Border: Red (#EF4444)
- Background: Dark Slate
- Opacity: 50%
- Strikethrough: Red line through player name
- Overlay: "ELIMINATED" text

### Vulnerable (0 Shields)
- Border: Pulsing Hot Pink (#FF007A)
- Background: Dark Slate
- Opacity: 100%
- Warning: "VULNERABLE" badge

### Low Shields (1 Shield)
- Border: Amber (#F59E0B)
- Background: Dark Slate
- Opacity: 100%
- Warning: Amber shield count

## Layout Patterns

### Grid Layout (Opponent Targets)
- 2-5 column responsive grid
- Even spacing between tiles
- Scales based on number of opponents

### Panel Layout (Active Player)
- Centered large panel
- Vertical stack: photo → name → shields → target → hero bonus

### List Layout (Player Tiles)
- Vertical scrollable list
- Compact tiles with horizontal layout
- Auto-scroll to current player

## Visual Effects

### Neon Glow
```dart
boxShadow: [
  BoxShadow(
    color: const Color(0xFF00FFA3).withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: 5,
  ),
]
```

### Gradient AppBar
```dart
gradient: LinearGradient(
  colors: [
    const Color(0xFF6B21A8), // Deep Purple
    const Color(0xFFFF007A), // Hot Pink
  ],
)
```

### Shield Bar
```dart
LinearProgressIndicator(
  value: shields / shieldMax,
  backgroundColor: const Color(0xFF1E293B),
  valueColor: AlwaysStoppedAnimation<Color>(
    const Color(0xFF00FFA3), // Neon Green
  ),
)
```

## Responsive Design Notes
- Grid columns adjust: 2-10 players use 2-5 columns
- Text scales with MediaQuery for accessibility
- Player tiles stack vertically on narrow screens
- Active player panel resizes based on available height
- Minimum tile size enforced for readability
