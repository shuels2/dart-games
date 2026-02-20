# Design System

## Overview

The Dart Games design system defines the visual language for the **container app screens only**. Individual games have their own unique visual identities.

## Container App Design Language

The design system below applies to the core container app screens:
- Splash screen
- Home screen (game selection)
- Dartboard setup screen
- System settings (options screen)
- Dartboard emulator (admin tool)

These screens provide a consistent container experience across the app.

## Colors

### Primary Colors
- **Flame Orange:** `#FF6B35` - Primary brand color
- **Tangerine Orange:** `#F7931E` - Secondary brand color
- **Deep Ocean Blue:** `#004E89` - Tertiary color, accents

### Gradient AppBars
- **Start:** Red `#F44336`
- **End:** Amber `#FFC107`

This gradient creates a warm, energetic header for container screens.

### Usage Guidelines
- Use Flame Orange for primary actions (buttons, links)
- Use Tangerine Orange for secondary elements
- Use Deep Ocean Blue for tertiary elements and accents
- Apply gradient to all AppBars in container screens

## Typography

### Font Family
**Nunito** (via Google Fonts)

```dart
import 'package:google_fonts/google_fonts.dart';

GoogleFonts.nunito(/* parameters */)
```

### Text Styles

#### Hero Headers
- **Weight:** Black (900)
- **Size:** 32-40pt
- **Letter Spacing:** Negative (tighter)
- **Usage:** Large headers, splash screen, major sections

#### Screen Titles
- **Weight:** Bold (700)
- **Size:** 24-28pt
- **Usage:** AppBar titles, screen headings

#### Live Scores/Numbers
- **Weight:** Semi-Bold (600)
- **Size:** 28pt+
- **Features:** Tabular figures (for consistent number alignment)
- **Usage:** Scores, statistics, numeric displays

#### Body Text
- **Weight:** Regular (400)
- **Size:** 16pt
- **Line Height:** 1.4x
- **Usage:** General content, descriptions, labels

### Typography Examples

```dart
// Hero header
Text(
  'Dart Games',
  style: GoogleFonts.nunito(
    fontWeight: FontWeight.w900,
    fontSize: 40,
    letterSpacing: -1.5,
  ),
)

// Screen title
Text(
  'Game Selection',
  style: GoogleFonts.nunito(
    fontWeight: FontWeight.w700,
    fontSize: 28,
  ),
)

// Body text
Text(
  'Select a game to play',
  style: GoogleFonts.nunito(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.4,
  ),
)
```

## Container Screen Design Patterns

### Splash Screen
- Large logo/title with hero header typography
- Flame Orange primary color
- Simple, clean layout
- Loading indicator using Tangerine Orange

### Home Screen (Game Selection)
- Gradient AppBar (Red to Amber)
- Game cards with distinct visual identities for each game
- Dartboard connection status indicator
- Navigation to System Settings

### Dartboard Setup Screen
- Gradient AppBar
- Connection status prominently displayed
- Clear call-to-action buttons (Flame Orange)
- Simple, focused interface

### Options Screen (System Settings)
- Gradient AppBar
- Sectioned layout (Announcer, Music, Users, Admin)
- Material Design UI components
- Flame Orange for primary actions

### Test Dartboard Screen (Admin Tool)
- Gradient AppBar
- Interactive dartboard centered
- Technical information displayed
- Developer-focused UI

## Buttons

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFFF6B35), // Flame Orange
    foregroundColor: Colors.white,
    textStyle: GoogleFonts.nunito(
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
  ),
  onPressed: () {},
  child: Text('Primary Action'),
)
```

### Secondary Button
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFFFF6B35), // Flame Orange
    side: BorderSide(color: Color(0xFFFF6B35)),
    textStyle: GoogleFonts.nunito(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ),
  onPressed: () {},
  child: Text('Secondary Action'),
)
```

## AppBar Style

```dart
AppBar(
  title: Text(
    'Screen Title',
    style: GoogleFonts.nunito(
      fontWeight: FontWeight.w700,
      fontSize: 24,
    ),
  ),
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFF44336), // Red
          Color(0xFFFFC107), // Amber
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
)
```

## Individual Game Design Freedom

**Each game should have its own unique visual identity.**

Games are encouraged to:
- ✅ Use custom color palettes that fit their theme
- ✅ Use different fonts and text styles
- ✅ Create unique UI elements, widgets, animations
- ✅ Maintain their own internal design consistency
- ✅ Create a distinct, memorable experience

### Examples

**Carnival Derby:**
- Yellow/amber carnival theme colors
- Montserrat and Bangers fonts
- Wood plank backgrounds
- Carnival-specific visual elements
- Horse racing aesthetic

**Target Tag:**
- Pink/green neon tech theme
- Fredoka font
- Dark navy backgrounds
- Futuristic, tech aesthetic
- Shield and elimination visuals

### Design Guidelines for Games

While games have design freedom, they should:
1. **Not use container colors/fonts** (avoid Nunito, Flame Orange, etc.)
2. **Maintain internal consistency** within the game
3. **Create clear visual hierarchy** for gameplay elements
4. **Ensure readability** of text and UI elements
5. **Support accessibility** (color contrast, font sizes)

## Responsive Design

### Screen Sizes
Support for:
- Web desktop (large screens 1920x1080+)
- Web mobile (small screens 375x667+)
- iPad landscape and portrait
- Android tablet landscape and portrait

### Adaptive Layout Patterns
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      // Large screen layout
      return WideLayout();
    } else {
      // Small screen layout
      return NarrowLayout();
    }
  },
)
```

## Touch Targets

All interactive elements must be:
- **Minimum size:** 44x44 points
- **Adequate spacing:** 8+ points between elements
- **Clear affordance:** Visual indication of interactivity

## Accessibility

### Color Contrast
- Text on background: Minimum 4.5:1 contrast ratio
- Large text (18pt+): Minimum 3:1 contrast ratio
- Interactive elements: Clear visual distinction

### Font Sizes
- Minimum body text: 14pt
- Recommended body text: 16pt
- Scalable text: Support dynamic type

## Animation Guidelines

### Timing
- **Quick:** 100-200ms (hover states, small UI changes)
- **Standard:** 300ms (page transitions, dialogs)
- **Slow:** 500ms+ (major state changes)

### Easing
- **Ease-in-out:** Standard transitions
- **Ease-out:** Elements entering
- **Ease-in:** Elements exiting

### Examples
```dart
AnimationController(
  duration: Duration(milliseconds: 300),
  vsync: this,
);

CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
);
```

## Material Design Integration

Container screens use Material Design 3 components:
- Cards
- Buttons (Elevated, Outlined, Text)
- Dialogs
- SnackBars
- Navigation elements
- Form fields

Games may use Material Design or create custom components.

## Icons

### Container App Icons
- Material Icons for system functions
- Custom icons for game-specific features

### Usage
```dart
Icon(
  Icons.home,
  color: Color(0xFFFF6B35), // Flame Orange
  size: 24,
)
```

## Spacing System

Use 8pt grid system for consistency:
- **Extra small:** 4pt
- **Small:** 8pt
- **Medium:** 16pt
- **Large:** 24pt
- **Extra large:** 32pt

```dart
EdgeInsets.all(8.0)   // Small padding
EdgeInsets.all(16.0)  // Medium padding
EdgeInsets.all(24.0)  // Large padding
```

## Elevation

Material elevation for depth:
- **Level 0:** Base layer (screens)
- **Level 1:** Cards, tiles
- **Level 2:** AppBar, bottom sheets
- **Level 3:** Dialogs, modals
- **Level 4:** Tooltips, snackbars

## Summary

**Container App:**
- Consistent design language across core screens
- Flame Orange (#FF6B35) primary color
- Nunito typography
- Material Design components
- Red-to-Amber gradient AppBars

**Individual Games:**
- Unique visual identities
- Custom colors, fonts, themes
- Internal design consistency
- Freedom to create distinct experiences

## Related Documentation

- [Container App Architecture](container-app.md)
- [Game-Specific Design Systems](../games/carnival-derby/design-system.md)
- [Target Tag Design System](../games/target-tag/design-system.md)
