# Reef Royale — Components

## Shared Components

### Dartboard Emulator

- **DartboardSectionConfig.reefRoyale()** — Deep Reef Blue background, seafoam green borders
- **DartboardFABConfig.reefRoyale()** — Deep blue background, seafoam icon, pearl white text

### Dialogs

**AddPlayerDialogConfig.reefRoyale()**
- Deep Reef Blue background with seafoam green border
- Seafoam green input borders and focus borders
- Fredoka font for headers, Nunito for body text

**EditScoreDialogConfig.reefRoyale()**
- Deep Reef Blue background with seafoam border
- Fredoka font for title
- Dart border colors match game indicators (green = hit, gold = claimed, pink = miss, aqua = neighbor)

### Remove Darts Modal

**RemoveDartsModalConfig.reefRoyale()**
- Deep Reef Blue overlay with seafoam accents
- "Remove Darts" prompt with reef-themed styling

### Dartboard Paused Modal

**DartboardPausedModalConfig.reefRoyale()**
- Semi-transparent dark overlay covering the full game area
- WiFi-off icon, "Game Paused" title, reconnection message
- Positioned in outermost body Stack for full coverage

### Dartboard Connection Info

- Displays dartboard connection status on menu screen
- Uses reef color theme

### Player List Panel

- Shared player add/remove panel on menu screen right side
- Integrates with global PlayerProvider

### Resume Game Button

**File:** `lib/widgets/resume_game_button.dart`

**Documentation:** See [Save & Resume Game](../../development/save-resume-game.md#resume-game-button-menu-screen)

**Usage:**
```dart
ResumeGameButton(
  hasSavedGames: _hasSavedGames,
  onPressed: () => setState(() => _showResumeModal = true),
  color: const Color(0xFFFFF8F0), // Pearl White
)
```

- Icon button in menu screen AppBar for accessing saved games
- Positioned left of DartboardConnectionInfo widget
- Enabled when saved games exist, disabled otherwise
- Opens Resume Game Modal when pressed

## Custom Components

### Coral Card
- Displays coral image (claimed/unclaimed state) with target number
- Shows mark progress (X/3 or X/2 with Easy Claim)
- Visual bloom effect when claimed
- Lock indicator when all players have claimed

### Active Player Panel
- Player avatar (photo or default icon)
- Player name
- Sea creature image (138×138)
- Pearl count (gold in standard, coral pink in Cursed Tide)
- Coral claimed count (X/7)
- 3 dart indicators with color-coded borders
- Skip Turn button
- Target hints (when enabled)

### Dart Indicators
Color-coded circles showing each dart's result:
- Empty (unfilled) — not yet thrown
- Seafoam Green — direct target hit
- Sunlit Aqua — neighbor hit
- Sandy Gold — pearl scored on claimed target
- Sandy Gold (full) — coral claimed on this dart
- Coral Pink (50%) — miss or non-target
- Pulsing glow — shared neighbor (multi-target) hit

### Opponent Summary Bar
- Horizontal bar at bottom of game screen
- Shows each opponent's creature, name, pearl count, coral count
- Ink Cloud buff hides opponent details

### Round Progress Bar
- Centered in appbar
- Shows current round / total rounds
- Visible in both standard and speed play modes

### Option Badges
- Positioned right of round progress bar in appbar
- **CURSED** — Coral pink badge, shown when Cursed Tide mode active
- **NEIGHBORS** — Sandy gold badge, shown when Neighbor Numbers enabled
- **BUFFS** — Seafoam green badge, shown when Bonus Buffs enabled

### Buff Banner
- Full-width banner displayed when a buff activates
- Shows buff name and description
- Themed to buff type (Riptide Rush, Pearl Fever, Ink Cloud)
