# Carnival Derby - Design System

## Theme Philosophy
Carnival Derby embraces a vibrant carnival horse racing aesthetic with bold, energetic colors and playful typography. The design evokes the excitement of a fairground horse race with warm wood textures, bright accent colors, and dramatic lighting effects that create a spotlight atmosphere reminiscent of a carnival midway at night.

## Color Palette

### Primary Colors
- **Lava Red:** `#E63946` - Primary action color for buttons, borders, highlights
- **Canary Yellow:** `#FFD700` - Accent color for text, glows, active states, borders
- **Electric Teal:** `#48CAE4` - Secondary accent for switches, selection states, action buttons

### Supporting Colors
- **Cedar Brown:** `#8B5E3C` - Warm wood base color for backgrounds
- **Dark Chocolate Brown:** `#2B1810` - Dark UI elements, overlay backgrounds
- **Midnight Navy:** `#0D1B2A` - Deep contrast for modal backgrounds
- **Warm Amber Glow:** `rgba(255, 230, 150, 0.4)` - Radial gradient spotlight center
- **Deep Moody Navy-Black:** `rgba(13, 27, 42, 0.8)` - Radial gradient edges

### Special Colors
- **Success/Win:** `#FFD700` (Canary Yellow) - Winner highlights, trophy displays
- **Warning/Caution:** `#E63946` (Lava Red) - Bust states, errors
- **Background:** `#8B5E3C` (Cedar) - Base wood plank texture
- **Surface:** `#2B1810` (Dark Chocolate) - Card backgrounds, dialogs
- **Text Primary:** `#FFD700` (Canary Yellow) - Main text, headers
- **Text Secondary:** `#FFFFFF` - Body text, descriptions

### Color Usage Examples
```dart
// Lava Red - Primary buttons, urgent states
backgroundColor: const Color(0xFFE63946),

// Canary Yellow - Text, borders, glows
color: const Color(0xFFFFD700),

// Electric Teal - Switches, selections
activeColor: const Color(0xFF48CAE4),

// Cedar - Wood background base
color: const Color(0xFF8B5E3C),
```

## Typography

### Font Families
- **Primary Font:** Rye (via Google Fonts)
  - Usage: Screen titles, header text, carnival-style headings
- **Display Font:** Luckiest Guy (via Google Fonts)
  - Usage: Large scores, winner announcements, prominent buttons
- **Accent Font:** Bangers (via Google Fonts)
  - Usage: Button labels, dart scores, action text
- **Body Font:** Montserrat (via Google Fonts)
  - Usage: Descriptive text, input labels, settings

### Text Styles
- **Screen Title:** Rye, Bold, 28-32pt, Canary Yellow (#FFD700)
- **Section Header:** Bangers, Bold, 20-24pt, Canary Yellow (#FFD700)
- **Body Text:** Montserrat, Regular, 14-16pt, White
- **Button Text:** Luckiest Guy or Bangers, Bold, 16-20pt, White or Black
- **Score Display:** Luckiest Guy, Bold, 32-48pt, Canary Yellow (#FFD700)
- **Player Name:** Rye or Montserrat, Bold, 16-18pt, Canary Yellow (#FFD700)

### Font Usage Examples
```dart
// Screen titles
GoogleFonts.rye(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: const Color(0xFFFFD700),
)

// Large scores
GoogleFonts.luckiestGuy(
  fontSize: 48,
  color: const Color(0xFFFFD700),
)

// Button labels
GoogleFonts.bangers(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

## Screen-by-Screen Styling

### Menu Screen
- **Background:** Rotated wood plank texture (CarnivalDerby-WoodPlanks.jpg) with Cedar (#8B5E3C) tint, overlaid with radial gradient spotlight effect
- **AppBar:** Horizontal gradient (Lava Red → Canary Yellow → Electric Teal) with Canary Yellow glow and drop shadow
- **Buttons:** Lava Red background, white text, Canary Yellow border, rounded corners
- **Player Tiles:** White background, Electric Teal when selected, player photo and name, draggable
- **String Lights:** Decorative Canary Yellow string lights across top
- **Target Logo:** Large faded carnival target centered behind content

### Game Screen
- **Background:** Same wood plank texture with radial spotlight as menu screen
- **AppBar:** Same tri-color gradient as menu screen
- **Race Track:** Oval track with horse icons, finish line marker, score progress visualization
- **Player Panels:** Current player highlighted with Canary Yellow border and glow
- **Score Display:** Large Luckiest Guy font, Canary Yellow color, Canary Yellow bottom border
- **Action Buttons:** Lava Red background, white text, Canary Yellow border
- **Dartboard Section:** Dark Chocolate background, Canary Yellow accents
- **String Lights:** Same decorative lights as menu screen

### Results Screen
- **Background:** Same wood plank texture with radial spotlight
- **AppBar:** Same tri-color gradient
- **Winner Display:** Electric Teal header with Canary Yellow glow, large trophy icon, confetti-style presentation
- **Winner Name:** Luckiest Guy font, Canary Yellow color with yellow glow effect
- **Statistics:** Montserrat font, white text, clean layout
- **Action Buttons:** Lava Red "Play Again", Electric Teal "Change Settings", Canary Yellow borders

## Animations

### Canary Yellow Glow (Pulse)
- **Type:** Pulse shadow animation
- **Duration:** 1500ms
- **Usage:** App bar title, winner name, active player indicators
- **Implementation:**
```dart
shadows: [
  Shadow(
    color: Color(0xFFFFD700),
    blurRadius: 20,
  ),
  Shadow(
    color: Color(0xFFFFD700),
    blurRadius: 40,
  ),
],
```

### String Lights Twinkle
- **Type:** Opacity animation
- **Duration:** Variable per light
- **Usage:** Decorative carnival atmosphere
- **Implementation:** Positioned circles with Canary Yellow glow

### Radial Gradient Spotlight
- **Type:** Static gradient overlay
- **Duration:** N/A (constant effect)
- **Usage:** Creates warm overhead lamp effect on all screens
- **Implementation:**
```dart
RadialGradient(
  center: Alignment(0, -0.6),
  radius: 1.2,
  colors: [
    Color.fromRGBO(255, 230, 150, 0.4), // Warm center glow
    Color.fromRGBO(255, 230, 150, 0.1), // Mid-falloff
    Color.fromRGBO(13, 27, 42, 0.8),     // Outer shadows
  ],
  stops: [0.0, 0.4, 1.0],
)
```

## Button Styles

### Primary Button (Action Button)
- **Background:** Lava Red (#E63946)
- **Text:** White, Luckiest Guy or Bangers font, 16-18pt
- **Border:** 4px Canary Yellow (#FFD700)
- **Shape:** BorderRadius.circular(8)
- **Hover:** Slight opacity change
- **Disabled:** 50% opacity

### Secondary Button (Cancel/Back)
- **Background:** Cedar (#8B5E3C) or Electric Teal (#48CAE4)
- **Text:** White, Montserrat or Bangers font, 16pt
- **Border:** 2px Canary Yellow (#FFD700)
- **Shape:** BorderRadius.circular(8)
- **Hover:** Slight opacity change

### Tertiary Button (Icon Button)
- **Background:** Transparent or Lava Red (#E63946)
- **Icon:** Canary Yellow (#FFD700)
- **Border:** Optional Canary Yellow border
- **Shape:** Circular or rounded square

### Disabled Button
- **Background:** Gray or original color at 50% opacity
- **Text:** White at 50% opacity
- **Border:** Gray at 50% opacity
- **Opacity:** 0.5

## Layout Patterns

### Two-Column Layout
Menu screen uses two-column layout:
- Left: Game description with decorative elements
- Right: Settings and player selection

### Scrollable Lists
Player lists are scrollable with consistent card styling:
- Drag-and-drop enabled between lists
- Visual feedback on selection
- Smooth scroll behavior

### Centered Content
Results screen centers winner display:
- Large trophy and player photo
- Winner name with glow effect
- Statistics below in clean rows

## Visual Effects

### Wood Plank Background
```dart
Transform.rotate(
  angle: 1.5708, // 90 degrees
  child: Container(
    decoration: BoxDecoration(
      color: const Color(0xFF8B5E3C),
      image: DecorationImage(
        image: AssetImage('assets/games/carnival_derby/images/CarnivalDerby-WoodPlanks.jpg'),
        fit: BoxFit.cover,
        repeat: ImageRepeat.repeat,
        colorFilter: ColorFilter.mode(
          const Color(0xFF8B5E3C).withOpacity(0.7),
          BlendMode.multiply,
        ),
      ),
    ),
  ),
)
```

### Spotlight Radial Gradient
Applied over wood background for dramatic lighting

### Drop Shadows
Used sparingly for depth on:
- App bar titles
- Winner name
- Action buttons

## Responsive Design Notes
- Layout adapts to screen width using `Expanded` and `Flexible`
- Player lists scroll independently
- Race track scales proportionally
- Button sizes adjust based on available space
- Minimum width enforced for player cards
- Text scales with MediaQuery for accessibility
