# [Game Name] - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/[game_name]_provider.dart`

**State Management:**
- [Description of what state is managed]
- [Key state variables and their purpose]
- [How state updates flow through the app]

**Key Methods:**
- `startGame()` - [Description]
- `processDartThrow()` - [Description]
- `advanceTurn()` - [Description]
- `[otherMethod]()` - [Description]

### Models
**File:** `lib/models/[game_name]_game.dart`

**Data Structure:**
```dart
class [GameName]Game {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;
  // ... [other fields]

  // [Description of the model structure]
}
```

**Key Responsibilities:**
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/[game_name]/[game_name]_menu_screen.dart`

**Purpose:** [What this screen does]

**Key Components:**
- Player selection UI
- Game settings configuration
- [Other components]

**State Management:**
- Uses `PlayerProvider` for [...]
- Local state for [...]

#### Game Screen
**File:** `lib/screens/games/[game_name]/[game_name]_game_screen.dart`

**Purpose:** [What this screen does]

**Key Components:**
- Game board/play area
- Player status displays
- Turn management UI
- [Other components]

**State Management:**
- Uses `[GameName]Provider` for [...]
- Uses `DartboardProvider` for [...]
- Local state for [...]

#### Results Screen
**File:** `lib/screens/games/[game_name]/[game_name]_results_screen.dart`

**Purpose:** [What this screen does]

**Key Components:**
- Winner display
- Game statistics
- Action buttons
- [Other components]

## Complex Algorithms

### [Algorithm 1 Name]
**Purpose:** [What this algorithm does]

**Implementation:**
```dart
// [Pseudocode or actual code snippet]
```

**Complexity:** [Time/space complexity if relevant]

**Edge Cases:**
- [Edge case 1]: [How it's handled]
- [Edge case 2]: [How it's handled]

### [Algorithm 2 Name]
**Purpose:** [What this algorithm does]

**Implementation:**
```dart
// [Pseudocode or actual code snippet]
```

**Complexity:** [Time/space complexity if relevant]

**Edge Cases:**
- [Edge case 1]: [How it's handled]
- [Edge case 2]: [How it's handled]

## Gotchas and Quirks

### [Quirk 1 Title]
**Issue:** [Description of the quirk]

**Why it happens:** [Explanation]

**How to handle:** [Best practice for dealing with this]

**Code location:** [Where in the code this is relevant]

### [Quirk 2 Title]
**Issue:** [Description of the quirk]

**Why it happens:** [Explanation]

**How to handle:** [Best practice for dealing with this]

**Code location:** [Where in the code this is relevant]

## Performance Considerations

### [Consideration 1]
**Concern:** [What the performance concern is]

**Mitigation:** [How it's addressed]

**Monitoring:** [How to check if it's still performing well]

### [Consideration 2]
**Concern:** [What the performance concern is]

**Mitigation:** [How it's addressed]

**Monitoring:** [How to check if it's still performing well]

## Integration Points

### Global User Management
**Integration:** [How this game integrates with PlayerProvider]

**Key Methods Used:**
- `updatePlayerStats()` - [How/when called]
- `savePlayer()` - [How/when called]
- `allPlayers` - [How/when accessed]

### Announcer System
**Integration:** [How this game integrates with announcement queue]

**Helper Class:** `[GameName]AnnouncementHelper`

**Key Patterns:**
```dart
// [Example of how announcements are triggered]
```

### Victory Music
**Integration:** [How this game integrates with VictoryMusicService]

**Implementation:**
```dart
// [Example of how victory music is triggered]
```

### Dartboard Emulator
**Integration:** [How this game integrates with dartboard emulator]

**Configuration:** [Reference to component config]

## Data Persistence

### Game State
**Storage:** [How/where game state is persisted if applicable]

**Serialization:** [How game state is serialized]

### Player Stats
**Storage:** SharedPreferences via PlayerProvider

**Data Tracked:**
- Games played: [How tracked]
- Games won: [How tracked]
- Game duration: [How tracked]
- [Other stats]: [How tracked]

## Known Issues and Limitations

### [Issue 1]
**Description:** [What the issue is]

**Impact:** [How it affects gameplay/UX]

**Workaround:** [Temporary solution if any]

**Future Fix:** [Plan to fix if applicable]

### [Issue 2]
**Description:** [What the issue is]

**Impact:** [How it affects gameplay/UX]

**Workaround:** [Temporary solution if any]

**Future Fix:** [Plan to fix if applicable]

## Future Enhancements

### Planned Features
- [ ] [Feature 1]: [Description]
- [ ] [Feature 2]: [Description]
- [ ] [Feature 3]: [Description]

### Enhancement Ideas
- [ ] [Idea 1]: [Description]
- [ ] [Idea 2]: [Description]
- [ ] [Idea 3]: [Description]

### Technical Debt
- [ ] [Debt Item 1]: [Description and plan to address]
- [ ] [Debt Item 2]: [Description and plan to address]

## Migration Notes

### From Version X to Version Y
**Date:** [Migration date]

**Changes:**
- [Change 1]
- [Change 2]

**Migration Steps:**
1. [Step 1]
2. [Step 2]

**Backward Compatibility:**
[How backward compatibility is maintained]

## Development Tips

### Common Tasks

#### Adding a New Announcement
1. [Step 1]
2. [Step 2]
3. [Step 3]

#### Adding a New Sound Effect
1. [Step 1]
2. [Step 2]
3. [Step 3]

#### Modifying Game Rules
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Debugging Tips

#### [Common Issue 1]
**Symptom:** [What you'll observe]
**Debug Steps:**
1. [Step 1]
2. [Step 2]

#### [Common Issue 2]
**Symptom:** [What you'll observe]
**Debug Steps:**
1. [Step 1]
2. [Step 2]

## Reference Implementations

### Similar Patterns in Other Games
- [Pattern in Carnival Derby]: [Reference]
- [Pattern in Target Tag]: [Reference]

### External Resources
- [Resource 1]: [URL or description]
- [Resource 2]: [URL or description]
