# Monster Mash - Component Configurations

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.monsterMash()`

**Configuration:**
```dart
factory DartboardSectionConfig.monsterMash() {
  return DartboardSectionConfig(
    backgroundColor: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    disabledOverlayBackgroundColor: const Color(0xFF2F4F4F).withOpacity(0.9), // Iron Gate
    disabledOverlayBorderColor: const Color(0xFF7FFF00), // Ecto-Green
    removeButtonBackgroundColor: const Color(0xFF4B0082), // Haunted Purple
    removeButtonBorderColor: const Color(0xFF7FFF00), // Ecto-Green
    removeButtonTextStyle: GoogleFonts.pirataOne(
      fontSize: 16,
      color: const Color(0xFFF5F5DC), // Aged Parchment
    ),
  );
}
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.monsterMash()`

**Configuration:**
```dart
factory DartboardFABConfig.monsterMash() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFF4B0082), // Haunted Purple
    iconColor: const Color(0xFF7FFF00), // Ecto-Green
    textColor: const Color(0xFFF5F5DC), // Aged Parchment
    textStyle: GoogleFonts.pirataOne(fontWeight: FontWeight.bold),
  );
}
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.monsterMash()`

**Key Configuration:**
```dart
factory AddPlayerDialogConfig.monsterMash() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF2F4F4F), // Iron Gate
    textColor: const Color(0xFFF5F5DC), // Aged Parchment
    titleStyle: GoogleFonts.creepster(fontSize: 28, /* with text shadow */),
    inputBorderColor: const Color(0xFF7FFF00), // Ecto-Green
    inputFocusedBorderColor: const Color(0xFFFF8C00), // Pumpkin Orange
    photoButtonColor: const Color(0xFF4B0082), // Haunted Purple
    photoButtonBorderColor: const Color(0xFF7FFF00), // Ecto-Green
    photoIconShadows: [/* green glow effect */],
    addButtonColor: const Color(0xFF4B0082),
    addButtonBorderColor: const Color(0xFF7FFF00),
    // Custom stone buttons replace standard Cancel/Add buttons
    customCancelButton: StoneDialogButton(/* stone outline, no fill */),
    customAddButton: StoneDialogButton(/* stone fill with lightning */),
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
    dialogInsetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 24),
    dialogContentWidth: 380,
  );
}
```

**Monster Mash-Specific Features:**
- Uses `customCancelButton` and `customAddButton` fields to replace standard buttons with `StoneDialogButton` widgets
- `dialogInsetPadding` and `dialogContentWidth` control dialog sizing for wider stone button layout
- `photoIconShadows` adds green glow to camera/gallery icons
- `buttonPadding` adjusts spacing around the custom button row

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.monsterMash()`

**Configuration:**
```dart
factory EditScoreDialogConfig.monsterMash() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF2F4F4F).withOpacity(0.95), // Iron Gate
    borderColor: const Color(0xFFFF8C00), // Pumpkin Orange
    borderWidth: 4,
    titleStyle: GoogleFonts.creepster(fontSize: 24, color: const Color(0xFFF5F5DC)),
    dartLabelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
    scoreBoxBackgroundColor: const Color(0xFF2F4F4F),
    scoreBoxDefaultBorderColor: const Color(0xFFF5F5DC).withOpacity(0.3),
    scoreTextStyle: GoogleFonts.pirataOne(fontSize: 18),
    buttonUnselectedColor: const Color(0xFF4B0082), // Haunted Purple
    buttonSelectedColor: const Color(0xFF7FFF00), // Ecto-Green
    cancelButtonColor: Colors.grey.withOpacity(0.85),
    submitButtonColor: const Color(0xFF4B0082).withOpacity(0.85),
    // No scoreDisplayTransform - shows raw segment strings (S20, D15, etc.)
  );
}
```

**Edit Score Dart Border Colors:**
- **Green:** Dart resulted in healing (hit own target, bullseye, outer bull)
- **Red:** Dart resulted in damage (hit opponent's target)
- **Faded White:** Dart had no effect (miss, unassigned number)

## Custom Components

### StoneDialogButton
**File:** `lib/widgets/stone_dialog_button.dart`

**Description:** A reusable button widget styled as a chipped stone tablet with optional lightning animation. Used in Monster Mash menu, results screen, and Add Player dialog.

**Constructor Parameters:**
```dart
StoneDialogButton({
  required VoidCallback onPressed,
  required String label,
  TextStyle? textStyle,
  bool showLightning = false,
  Color lightningColor = const Color(0xFF7FFF00),
  bool showStoneFill = true,
  bool showShadow = true,
  Color? borderColor,
  double height = 48,
  int seed = 0,  // Controls unique edge pattern
})
```

**Visual Features:**
- Jagged/chipped edges via `CustomClipper` with seeded randomization
- Stone gradient fill (radial gradient with bevel lighting)
- Inner bevel effect for 3D appearance
- Optional lightning animation with configurable color
- Drop shadow for depth
- Stone texture overlay

**Usage Examples:**
```dart
// Results screen - Play Again button
StoneDialogButton(
  onPressed: _playAgain,
  label: 'PLAY AGAIN',
  showLightning: true,
  lightningColor: const Color(0xFF7FFF00), // Lime
  height: 52,
  seed: 42,
)

// Add Player dialog - Cancel button (outline only)
StoneDialogButton(
  onPressed: () => Navigator.pop(context),
  label: 'CANCEL',
  showStoneFill: false,
  showLightning: false,
  height: 52,
  seed: 7,
)
```

### Monster Grid Layout
- Uses `_getCellAssignments()` for opponent positioning
- Perspective scaling: back rows at 0.75x, front rows at 1.25x
- Supports 1-7 opponents with dynamic grid sizing
- Eliminated opponents shown faded with offset

### Health Bar
- Gradient from red to green clipped by HP percentage
- Fixed height bar with rounded corners
- Used in both active player panel and opponent tiles

### Buff Shield Indicators
- Heal shield (left): Shows healing buff info (e.g., "+5" for Ancient Bandages)
- Damage shield (right): Shows damage buff info (e.g., "+2x" for Blood Moon, "0" for Shadow Walk, "10" for Lab Spark)
- Round label: Shows "Round X / Max" during Speed Play

### Round Progress Bar
- Centered bar showing current round progress (Speed Play only)
- Buff shields flanking the bar when a buff is active
- Buff description label below the bar
