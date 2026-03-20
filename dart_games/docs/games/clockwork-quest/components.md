# Clockwork Quest - Components

## Screen Structure

Clockwork Quest consists of 3 main screens plus shared components from the container app.

## Menu Screen

**File:** `lib/screens/games/clockwork_quest/clockwork_quest_menu_screen.dart`

### Layout
```
AppBar (Cinzel Decorative, Steam White)
├─ Title: "CLOCKWORK QUEST"
├─ Back Button
└─ Resume Game Button (conditional)

Body (Dark Iron background)
├─ Settings Section (Left, flex: 3)
│  ├─ Section Title: "GAME SETTINGS"
│  ├─ Settings Grid (2x2)
│  │  ├─ Include Bullseye (Checkbox)
│  │  ├─ D/T Count (Checkbox)
│  │  ├─ Speed Mode (Checkbox)
│  │  └─ Number of Laps (Dropdown: 1-5)
│  └─ START TOWER CLIMB Button (Verdigris Green)
│
└─ Player Panel (Right, flex: 2)
   └─ DualPlayerListPanel
      ├─ Header: "INVENTORS"
      ├─ Player List (8 characters)
      └─ Add Player Button
```

### Shared Components Used

| Component | Config Factory | Purpose |
|-----------|---------------|---------|
| DualPlayerListPanel | `DualPlayerListPanelConfig.clockworkQuest()` | Player selection with steampunk styling |
| AddPlayerDialog | `AddPlayerDialogConfig.clockworkQuest()` | Add new players |
| ResumeGameButton | `ResumeGameModalConfig.clockworkQuest()` | Resume saved games |

### Settings Components

**Checkbox Tiles:**
- Background: Mahogany Brown with Brass Gold border
- Text: Cinzel Decorative, Steam White
- Checkbox: Verdigris Green when checked
- Tap behavior: Toggle state, save to provider

**Number of Laps Dropdown:**
- Values: 1, 2, 3, 4, 5
- Default: 1
- Styled with Brass Gold border and Steam White text

## Game Screen

**File:** `lib/screens/games/clockwork_quest/clockwork_quest_game_screen.dart`

### Layout
```
AppBar
├─ Title: "CLOCKWORK QUEST"
├─ Back Button (triggers save modal if progress made)
└─ Dartboard Connection Info

Body (Clocktower interior background)
├─ Main Content (Row)
│  ├─ Active Player Panel (200px left column)
│  │  ├─ Player name (Cinzel Decorative, Brass Gold)
│  │  ├─ Character avatar
│  │  ├─ Current Gear indicator
│  │  ├─ Lap counter (if laps > 1)
│  │  └─ Skip Turn Button
│  │
│  └─ Gear Tracker (Center, flex: 1)
│     └─ Circular gear grid showing all gears
│        ├─ Gears 1-20 (always shown)
│        └─ Gear 21 Bullseye (conditional)
│
└─ Bottom Section
   ├─ Edit Score Button (after 3 darts)
   ├─ Dartboard Emulator
   └─ Remove Darts Modal (after 3 darts)
```

### Gear Tracker Component

The gear tracker shows all gears in a circular/grid arrangement:

**Layout:**
- 5 gears per row
- 8px spacing between gears
- Gears arranged 1-20 (or 1-21 if bullseye mode)

**Gear Display:**
- **Inactive (not yet reached):** Rivet Silver, no glow
- **Active (current target):** Brass Gold with Amber Glow pulse
- **Complete (passed):** Brass Gold, static

**Lap Counter:**
Only shown when numberOfLaps > 1:
- Position: Above gear grid
- Text: "Lap [current] of [total]"
- Style: Cinzel Decorative, Amber Glow

### Active Player Panel

**Components:**
- Player name in Brass Gold
- Character avatar (120x120)
- Current gear number in large Amber Glow text
- Progress bar (optional): Shows gear progress within current lap
- Skip Turn button (Verdigris Green)

### Shared Components Used

| Component | Config Factory | Purpose |
|-----------|---------------|---------|
| DartboardSection | `DartboardSectionConfig.clockworkQuest()` | Dartboard emulator |
| DartboardConnectionInfo | `DartboardConnectionInfoConfig.clockworkQuest()` | Connection status |
| RemoveDartsModal | `RemoveDartsModalConfig.clockworkQuest()` | Takeout prompt |
| DartboardPausedModal | `DartboardPausedModalConfig.clockworkQuest()` | Pause handling |
| EditScoreDialog | `EditScoreDialogConfig.clockworkQuest()` | Manual score correction |
| SaveGameModal | `SaveGameModalConfig.clockworkQuest()` | Save progress on exit |

## Results Screen

**File:** `lib/screens/games/clockwork_quest/clockwork_quest_results_screen.dart`

### Layout
```
AppBar
├─ Title: "RESULTS"
└─ Dartboard Connection Info

Body (Victorious clocktower background)
├─ Victory Section
│  ├─ Title: "THE CLOCKWORK CROWN!"
│  ├─ Winner Panel (Brass-bordered, glowing)
│  │  ├─ Character avatar
│  │  ├─ Player name
│  │  └─ "CROWNED CHAMPION" subtitle
│  │
│  └─ Rankings List
│     └─ For each player:
│        ├─ Rank number
│        ├─ Player name
│        ├─ Character avatar (small)
│        ├─ Progress: "Gear [N]" or "Lap [X], Gear [N]"
│        └─ Border: Brass Gold if winner, Copper Rose otherwise
│
└─ Action Buttons (centered, horizontal)
   ├─ WIND AGAIN (Verdigris Green) → New game, same settings
   ├─ CHANGE SETTINGS (Copper Rose) → Return to menu
   └─ LEAVE TOWER (Rivet Silver) → Return to home
```

### Shared Components

No shared components on results screen - fully custom layout.

## Shared Component Configurations

All shared components use the `.clockworkQuest()` factory method to apply steampunk styling:

**Color Scheme:**
- Primary: Brass Gold (`#C5A54E`)
- Secondary: Copper Rose (`#B87333`)
- Background: Dark Iron (`#2C2C34`)
- Text: Steam White (`#F5F0E8`)
- Accent: Verdigris Green (`#43B3AE`)

**Typography:**
- Headers: Cinzel Decorative Bold
- Body: Lato Regular
- All text in Steam White

**Example Config:**
```dart
static DartboardSectionConfig clockworkQuest() {
  return DartboardSectionConfig(
    primaryColor: Color(0xFFC5A54E),      // Brass Gold
    secondaryColor: Color(0xFFB87333),    // Copper Rose
    backgroundColor: Color(0xFF2C2C34),   // Dark Iron
    textColor: Color(0xFFF5F0E8),         // Steam White
    buttonColor: Color(0xFF43B3AE),       // Verdigris Green
    headerFont: GoogleFonts.cinzelDecorative,
    bodyFont: GoogleFonts.lato,
  );
}
```

## Widget Keys

All interactive elements have widget keys for automated testing:

**Menu Screen:**
- `ClockworkQuestMenuKeys.includeBullseyeCheckbox`
- `ClockworkQuestMenuKeys.doubleTriplesCountCheckbox`
- `ClockworkQuestMenuKeys.speedModeCheckbox`
- `ClockworkQuestMenuKeys.numberOfLapsDropdown`
- `ClockworkQuestMenuKeys.startButton`
- `ClockworkQuestMenuKeys.backButton`
- `ClockworkQuestMenuKeys.resumeGameButton`
- `ClockworkQuestMenuKeys.addPlayerButton`
- `ClockworkQuestMenuKeys.playerTile(playerId)`

**Game Screen:**
- `ClockworkQuestGameKeys.gearIcon(number)` - for each gear 1-21
- `ClockworkQuestGameKeys.skipTurnButton`
- `ClockworkQuestGameKeys.editScoreButton`
- `ClockworkQuestGameKeys.backButton`

**Results Screen:**
- `ClockworkQuestResultsKeys.winnerName`
- `ClockworkQuestResultsKeys.playerRanking(index)`
- `ClockworkQuestResultsKeys.playAgainButton`
- `ClockworkQuestResultsKeys.changeSettingsButton`
- `ClockworkQuestResultsKeys.backToMenuButton`

## State Management

Clockwork Quest uses Provider for state management:

**ClockworkQuestProvider:**
- Manages game state via `ClockworkQuestGame` model
- Processes dart hits and target advancement
- Handles lap progression and win detection
- Integrates with SaveGameService for persistence
- Coordinates with GameAnnouncementQueueService for audio

**Key Methods:**
- `startNewGame()` - Initialize new game
- `processDart()` - Handle dart throws
- `skipTurn()` - Skip current player's turn
- `saveGame()` - Save current state
- `resumeGame()` - Load saved state
