# Shared Systems

## Overview

The Dart Games container app provides several shared systems that all games integrate with. These systems ensure consistency, reduce code duplication, and provide a unified user experience.

## 1. Dartboard Connection (`DartboardProvider`)

### Purpose
Manages connection to physical Scolia dartboard via API or provides emulator mode for development/testing.

### File Location
`lib/providers/dartboard_provider.dart`

### Key Responsibilities
- Connect to physical dartboard via API
- Manage connection state (connected, disconnected, connecting)
- Process dart throw events from hardware
- Provide emulator mode when no hardware available
- Emit dart events to games

### Usage in Games
```dart
final dartboardProvider = Provider.of<DartboardProvider>(context);

// Check connection status
if (dartboardProvider.isConnected) {
  // Using real dartboard
} else {
  // Using emulator mode
}

// Listen to dart events
dartboardProvider.addListener(() {
  // Process dart throw
});
```

### Connection States
- **Disconnected:** No dartboard connected
- **Connecting:** Attempting to connect
- **Connected:** Active connection to physical dartboard
- **Emulator:** Using software emulator

## 2. User Management (`PlayerProvider`)

### Purpose
Global player list shared across all games, manages player profiles, photos, statistics, and game history.

### File Location
`lib/providers/player_provider.dart`

### Key Responsibilities
- Store and retrieve player profiles
- Manage player photos
- Track game statistics (games played, games won, play time)
- Record game history with duration
- Persist data across app restarts
- Provide alphabetical sorting

### Data Model
```dart
class Player {
  final String id;
  final String name;
  final String? photoUrl;
  final int gamesPlayed;
  final int gamesWon;
  final List<GameHistoryEntry> gameHistory;
  // ...
}
```

### Key Methods

#### savePlayer(Player player)
Add a new player to the global list.

#### updatePlayerStats(String playerId, {required bool won, required String gameName, required Duration gameDuration})
Update player stats after a game completes.

**CRITICAL:** Call this for ALL players (both winners AND losers) with the same game duration.

#### allPlayers
Get list of all players (alphabetically sorted).

#### selectedPlayers
Get list of currently selected players.

#### selectPlayer(Player player, {required int maxPlayers})
Select a player for the current game.

### Usage in Games
```dart
final playerProvider = Provider.of<PlayerProvider>(context);

// Get all players
final players = playerProvider.allPlayers;

// Save new player
await playerProvider.savePlayer(newPlayer);

// Update stats after game
await playerProvider.updatePlayerStats(
  playerId,
  won: true,
  gameName: 'Target Tag',
  gameDuration: gameDuration,
);
```

### Statistics Tracked
- Total games played (for all players)
- Total games won (for winners only)
- Game history with duration (for all players)
- Total play time
- Average game duration per game type

## 3. Announcer System (`DartAnnouncerService`)

### Purpose
Voice announcements for game events with customizable voice and personality.

### File Location
`lib/services/dart_announcer_service.dart`

### Key Responsibilities
- Text-to-speech announcements
- Support multiple voice engines (Browser Voices, ResponsiveVoice)
- Customizable personality (Professional, Excited, Calm, Funny, Drill Sergeant)
- Voice enabled/disabled setting
- Persist settings

### Voice Engines
- **Browser Voices:** Built-in browser TTS (web)
- **ResponsiveVoice:** External TTS API
- **Future:** Native TTS for mobile

### Personalities
- **Professional:** Formal, clear announcements
- **Excited:** Enthusiastic, energetic commentary
- **Calm:** Relaxed, soothing tone
- **Funny:** Humorous, playful commentary
- **Drill Sergeant:** Commanding, military-style

### Usage
**DO NOT use directly in games.** Games should use `GameAnnouncementQueueService` instead.

## 4. Victory Music (`VictoryMusicService`)

### Purpose
Manage custom victory music files and play random music when a player wins any game.

### File Location
`lib/services/victory_music_service.dart`

### Key Responsibilities
- Upload and store victory music files on the server
- Random selection from user's library
- Music playback via server URLs
- Add/remove music files
- In-memory cache with lazy initialization

### File Handling
Music files are uploaded to the server as base64 and played back via server URLs (`/api/v1/music/{id}/file`).

### Usage in Games
```dart
final musicService = VictoryMusicService();

// Check if custom music available
if (await musicService.hasCustomMusic()) {
  // Get random music server URL
  final musicSource = await musicService.getRandomMusicSource();

  if (musicSource != null) {
    final player = AudioPlayer();
    await player.play(UrlSource(musicSource));
  }
}
```

### Supported Formats
- MP3 (recommended - best compatibility)
- WAV
- OGG
- M4A
- Other formats supported by audioplayers package

## 5. Game Announcement Queue (`GameAnnouncementQueueService`)

### Purpose
Global priority-based announcement queue that prevents announcement overlap and manages sound effects.

### File Location
`lib/services/game_announcement_queue_service.dart`

### Key Responsibilities
- Queue voice announcements with priority
- Prevent announcement overlap
- Play sound effects simultaneously with announcements
- Use `DartAnnouncerService` for voice output
- Manage announcement lifecycle

### Priority Levels
1. **turnTransition (1):** Turn start/end announcements - highest priority
2. **hitConfirm (2):** Immediate feedback for dart throws
3. **shieldStatus (3):** Status changes (shields, tagged-in, etc.)
4. **statusChange (4):** General game state changes
5. **victory (5):** Game over and winner announcements - lowest priority

### Game Integration Pattern

Each game creates a helper class that wraps the queue service:

```dart
class TargetTagAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  TargetTagAnnouncementHelper(this._queue);

  void announcePlayerTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: TargetTagSoundEffects.turnStart,
    );
  }

  void dispose() {
    _queue.dispose();
  }
}
```

### Usage in Games
```dart
// In game screen state
TargetTagAnnouncementHelper? _audioQueue;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = TargetTagAnnouncementHelper(globalQueue);
  });
}

@override
void dispose() {
  _audioQueue?.dispose();
  super.dispose();
}

// Trigger announcements
_audioQueue?.announcePlayerTurn(player.name);
```

See [Announcement System Integration](../development/announcement-system.md) for complete guide.

## 6. In-Game Dartboard Emulator Components

### Purpose
Shared, reusable dartboard emulator UI components for all games.

### File Location
`lib/widgets/dartboard_emulator/`

### Components

#### DartboardEmulatorController
- Manages show/hide state for dartboard emulator
- ChangeNotifier pattern
- Toggles dartboard visibility

#### DartboardEmulatorSection
- Renders dartboard container with optional disabled overlay
- Handles dart throw simulation
- "Remove Darts" button functionality
- Game-specific styling via config

#### DartboardEmulatorFAB
- Floating action button for show/hide toggle
- Only visible in emulator mode (when `dartboardProvider.isEmulator`)
- Game-specific styling via config

#### Configuration Classes
- **DartboardSectionConfig:** Styling for dartboard container
  - Factory methods: `.carnivalDerby()`, `.targetTag()`, `.monsterMash()`
- **DartboardFABConfig:** Styling for FAB button
  - Factory methods: `.carnivalDerby()`, `.targetTag()`, `.monsterMash()`

### Usage
See [Dartboard Emulator Integration](../development/dartboard-emulator.md) for complete guide.

### Important Notes
- **Only shown in emulator mode:** Automatically hidden when connected to real dartboard
- **For development/testing:** Not shown to end users with physical hardware
- **Consistent behavior:** All games use same dartboard logic

## 7. Add Player Dialog Component

### Purpose
Shared modal for adding new players across all games and System Settings.

### File Location
`lib/widgets/add_player/`

### Components

#### showAddPlayerDialog()
Function that displays the dialog and returns `Player?` or `null`.

#### AddPlayerDialogConfig
Configuration class for styling (colors, fonts, buttons).

**Factory methods:**
- `AddPlayerDialogConfig.carnivalDerby()` - Carnival theme
- `AddPlayerDialogConfig.targetTag()` - Tech/neon theme
- `AddPlayerDialogConfig.monsterMash()` - Gothic stone theme (uses StoneDialogButton)
- `AddPlayerDialogConfig.optionsScreen(context)` - Material Design defaults

**Monster Mash-specific config fields:**
- `customCancelButton` - Widget to replace standard cancel button (StoneDialogButton)
- `customAddButton` - Widget to replace standard add button (StoneDialogButton with lightning)
- `dialogInsetPadding` - Custom dialog edge insets for wider layout
- `dialogContentWidth` - Custom content width (380px for stone buttons)
- `photoIconShadows` - Shadow list for camera/gallery icons (green glow)
- `buttonPadding` - Custom padding around button row

### Features
- Photo upload via camera or gallery
- Name validation (empty check)
- Photo preview with remove button
- Returns Player object if created, null if cancelled

### Usage
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.targetTag(),
);

if (player != null && mounted) {
  await playerProvider.savePlayer(player);
  // Optional: Auto-select player
  playerProvider.selectPlayer(player, maxPlayers: 10);
}
```

See [Add Player Dialog Integration](../development/add-player-dialog.md) for complete guide.

## 8. Edit Score Dialog Component

### Purpose
Shared modal for editing three dart scores during a turn across all games.

### File Location
`lib/widgets/edit_score/`

### Components

#### showEditScoreDialog()
Function that displays the dialog and calls `onSubmit` with new segments on confirm.

#### EditScoreDialogConfig
Configuration class for styling (colors, fonts, borders).

**Factory methods:**
- `EditScoreDialogConfig.carnivalDerby()` - Shows calculated point values
- `EditScoreDialogConfig.targetTag()` - Shows raw segment strings
- `EditScoreDialogConfig.monsterMash()` - Gothic theme, raw segment strings

### Features
- Ring/number picker for all 3 darts
- Per-dart score box border color overrides (optional)
- Optional score display transform
- Submit disabled until all 3 darts selected

### Segment Encoding
- `S20` - Outer single 20
- `s20` - Inner single 20 (Carnival Derby only)
- `D16` - Double 16
- `T19` - Triple 19
- `Bull` - Bullseye (50 points)
- `25` - Outer bull
- `Miss` - Miss

### Usage
```dart
showEditScoreDialog(
  context: context,
  playerName: currentPlayer.name,
  initialSegments: provider.getCurrentTurnDarts(playerId),
  onSubmit: (newSegments) => provider.updateAllDartScores(playerId, newSegments),
  config: EditScoreDialogConfig.targetTag(),
  dartBorderColors: _computeDartBorderColors(playerId), // Optional
);
```

See [Edit Score Dialog Integration](../development/edit-score-dialog.md) for complete guide.

## 10. Remove Darts Modal Component

### Purpose
Shared full-screen modal overlay prompting the current player to remove their darts from the board. Appears when the turn ends and no physical dartboard is connected.

### File Location
`lib/widgets/remove_darts_modal/`

### Components

#### RemoveDartsModal
- Full-screen semi-transparent overlay with centered game-themed container
- Shows `pan_tool` icon, player name, "Remove Your Darts" instruction
- Includes "Edit player score" button with game-specific callback
- Optional `ConstrainedBox` wrapping when `maxWidth` is not infinite
- Accepts `RemoveDartsModalConfig` for game-specific styling

#### RemoveDartsModalConfig
Configuration class with factory methods for each game's theme.

**Factory methods:**
- `RemoveDartsModalConfig.carnivalDerby()` — Canary Yellow border, LuckiestGuy/Bangers fonts, larger icon
- `RemoveDartsModalConfig.targetTag()` — Hot Pink border, Fredoka font, 400px max width
- `RemoveDartsModalConfig.monsterMash()` — Lime Green border with green glow, Creepster/PirataOne fonts
- `RemoveDartsModalConfig.reefRoyale()` — Seafoam Green border, Fredoka font

### Usage
```dart
if (shouldPromptTakeout && !dartboardProvider.isConnected)
  RemoveDartsModal(
    config: RemoveDartsModalConfig.targetTag(),
    playerName: currentPlayer?.name ?? 'Player',
    editScoreButtonKey: YourGameKeys.editScoreButton,
    onEditScore: () {
      // Call showEditScoreDialog() with game-specific provider/config
    },
  ),
```

See [Remove Darts Modal Integration](../development/remove-darts-modal.md) for complete guide.

## 11. Player List Panel Component

### Purpose
Shared, configurable player management UI for game menu screens. Supports two patterns: dual-list (Available + Selected) and single-list with team assignment.

### File Location
`lib/widgets/player_list_panel/`

### Components

#### DualPlayerListPanel
Two side-by-side lists: "Available Players" and "Selected Players" with selection, removal, and add player functionality. Used by Carnival Derby and Monster Mash.

#### DualPlayerListPanelConfig
Configuration class with factory methods for each game's theme.

**Factory methods:**
- `DualPlayerListPanelConfig.carnivalDerby()` — Navy containers, Bangers font, Lava Red button
- `DualPlayerListPanelConfig.monsterMash()` — Dark slate containers, PirataOne headers, Creepster names

#### TeamPlayerListPanel
Single player list with optional team assignment (team icons, team selection dialog, team assignment boxes). Used by Target Tag.

#### TeamPlayerListPanelConfig
Configuration class for team game pattern.

**Factory methods:**
- `TeamPlayerListPanelConfig.targetTag()` — Hot Pink/Neon Green theme, Fredoka font

### Features
- Custom button builders (Monster Mash stone buttons via `customAddPlayerButton`)
- Auto-select and auto-scroll on player add
- Team selection dialog with "FULL" badge and "Remove from Team"
- Fixed height or expanded layout modes
- All test keys passed through (not generated internally)

### Usage
```dart
// Dual-list pattern (Carnival Derby, Monster Mash)
DualPlayerListPanel(
  config: DualPlayerListPanelConfig.carnivalDerby(),
  addPlayerButtonKey: CarnivalDerbyMenuKeys.addPlayerButton,
  playerListViewKey: CarnivalDerbyMenuKeys.playerListView,
  playerTileKey: (id) => CarnivalDerbyMenuKeys.playerTile(id),
  removePlayerButtonKey: (id) => CarnivalDerbyMenuKeys.removePlayerButton(id),
)

// Team pattern (Target Tag)
TeamPlayerListPanel(
  config: TeamPlayerListPanelConfig.targetTag(),
  isTeamMode: _isTeamMode,
  isManualTeamAssignment: !_isRandomTeams,
  teamIconPaths: _teamIconPaths,
  onTeamAssignmentsChanged: (assignments) { ... },
)
```

See [Player List Panel Integration](../development/player-list-panel.md) for complete guide.

## System Integration Requirements

All games MUST integrate with these systems:

### Required Integrations
✅ **PlayerProvider** - Use global player list, update stats
✅ **GameAnnouncementQueueService** - All announcements via queue
✅ **VictoryMusicService** - Play victory music on win
✅ **DartboardProvider** - Use for dart input

### Optional Integrations
- **DartboardEmulatorComponents** - For offline development (recommended)
- **AddPlayerDialog** - For adding players (recommended)
- **EditScoreDialog** - For editing scores (recommended)

### Integration Checklist

When adding a new game:

- [ ] Create game-specific announcement helper
- [ ] Call `updatePlayerStats()` for ALL players (winners and losers)
- [ ] Track game duration from start to end
- [ ] Play victory music on win
- [ ] Use dartboard emulator components
- [ ] Use add player dialog component
- [ ] Use edit score dialog component
- [ ] Create dartboard/dialog config factory methods

## Data Persistence

### Server-Side Architecture

All data is persisted via a Dart Shelf backend server with SQLite storage. The Flutter app communicates with the server through a REST API client (`ApiClient`).

#### Server Stack
- **Framework:** Dart Shelf with shelf_router
- **Database:** SQLite with WAL mode
- **Location:** `server/` directory in project root
- **Entry point:** `server/bin/server.dart`

#### API Endpoints (all under `/api/v1/`)
- `settings/` - Key-value app settings (voice, announcer, etc.)
- `dartboard/` - Singleton dartboard configuration + connection profiles
- `players/` - Player CRUD, photos (base64), game history, stats
- `games/` - Saved game state (save/resume feature)
- `music/` - Victory music upload/download/management
- `health/` - Server health check

#### Flutter API Client
- **File:** `lib/services/api/api_client.dart`
- **Config:** `lib/services/api/api_config.dart`
- Injected into providers via `initialize(ApiClient)` or constructor parameter
- Tests use `MockApiServer` (`test/shared/mock_api_helpers.dart`) for in-memory API simulation

#### Initialization Pattern
```dart
// In main.dart
ApiConfig.configure('http://localhost:8080');
apiClient = ApiClient();
AppSettings.initialize(apiClient);
StorageService.initialize(apiClient);
VictoryMusicService().initializeApi(apiClient);
```

#### Provider Injection
```dart
// Providers that use initialize()
DartboardProvider()..initialize(apiClient);
PlayerProvider()..initialize(apiClient);

// Providers that accept constructor parameter
HorseRaceProvider(apiClient: apiClient);
TargetTagProvider(apiClient: apiClient);
```

### Data Migrations

The app includes a schema versioning system to safely evolve stored data across deployments. On startup, `MigrationRunner.runMigrations()` runs in `main()` before `runApp()` to execute any pending migrations.

- **Adding optional fields** with `??` defaults in `fromJson()` does NOT require a migration
- **Breaking changes** (key renames, type changes, restructuring) require a new migration
- See [Data Migrations](../development/data-migrations.md) for the full guide

## Cross-Platform Considerations

All shared systems support:
- ✅ Web browsers (Chrome, Safari, Firefox, Edge)
- ✅ iOS tablets (iPad)
- ✅ Android tablets

Platform-specific implementations handled internally.

## Promoted and Shared Widgets

### StoneDialogButton
**File:** `lib/widgets/stone_dialog_button.dart`

A reusable button widget styled as a chipped stone tablet with optional lightning animation. Created for Monster Mash and placed at the shared widget level for potential reuse by future games.

### Promoted Widgets
The following widgets were promoted from game-specific to shared during Monster Mash development:
- `lib/widgets/player_selection_card.dart` - Player selection card (previously in `lib/widgets/horse_race/`)
- `lib/widgets/player_avatar_widget.dart` - Player avatar display (previously in `lib/widgets/horse_race/`)

## 9. Dartboard Connection Info Component

### Purpose
Shared widget that displays dartboard name, type (emulator/hardware), and connection status in a compact row. Replaces the need for screens to individually compose `CompactDartboardInfo` and `DartboardStatusIndicator`.

### File Location
`lib/widgets/dartboard_connection_info/`

### Components

#### DartboardConnectionInfo
- Combined widget using `Consumer<DartboardProvider>` internally
- Shows dartboard name, type icon, emulator label, and connection status
- Returns `SizedBox.shrink()` if no dartboard configured
- Accepts `DartboardConnectionInfoConfig` for game-specific styling

#### DartboardConnectionInfoConfig
Configuration class with factory methods for each game's theme.

**Factory methods:**
- `DartboardConnectionInfoConfig.homeScreen()` - White background, standard styling
- `DartboardConnectionInfoConfig.carnivalDerby()` - Carnival theme (Rye font, Lava Red/Canary Yellow)
- `DartboardConnectionInfoConfig.targetTag()` - Tech/neon theme (Luckiest Guy font, Hot Pink/Neon Green)
- `DartboardConnectionInfoConfig.monsterMash()` - Gothic theme (Creepster font, Lime Green/Beige)
- `DartboardConnectionInfoConfig.reefRoyale()` - Ocean theme (Fredoka font, Seafoam Green/Ocean Blue)

### Usage
```dart
AppBar(
  title: Text('Your Game'),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(
        config: DartboardConnectionInfoConfig.yourGame(),
      ),
    ),
  ],
),
```

See [Dartboard Connection Info Integration](../development/dartboard-connection-info.md) for complete guide.

## 12. Dartboard Paused Modal Component

### Purpose
Shared full-screen modal overlay shown when the dartboard connection is lost mid-game. Pauses gameplay with a "Game Paused" message and auto-dismisses when the dartboard reconnects. Only appears for real dartboard connections (never in emulator mode).

### File Location
`lib/widgets/dartboard_paused_modal/`

### Components

#### DartboardPausedModal
- Full-screen semi-transparent overlay with centered game-themed container
- Shows `wifi_off` icon, "Game Paused" title, and reconnection message
- Auto-shows when connection status becomes `error` or `disconnected`
- Auto-dismisses when dartboard reconnects (driven by `context.watch<DartboardProvider>()`)
- Accepts `DartboardPausedModalConfig` for game-specific styling

#### DartboardPausedModalConfig
Configuration class with factory methods for each game's theme.

**Factory methods:**
- `DartboardPausedModalConfig.carnivalDerby()` — Canary Yellow border, LuckiestGuy/Bangers fonts
- `DartboardPausedModalConfig.targetTag()` — Hot Pink border, LuckiestGuy/Fredoka fonts
- `DartboardPausedModalConfig.monsterMash()` — Ecto-Green border with green glow, Creepster/PirataOne fonts
- `DartboardPausedModalConfig.reefRoyale()` — Seafoam Green border, Fredoka font

### Usage
```dart
// In your game screen's Stack (after RemoveDartsModal):
if (!dartboardProvider.isEmulator &&
    dartboardProvider.status != DartboardConnectionStatus.connected &&
    dartboardProvider.status != DartboardConnectionStatus.emulator)
  DartboardPausedModal(
    config: DartboardPausedModalConfig.yourGame(),
  ),
```

See [Dartboard Paused Modal Integration](../development/dartboard-paused-modal.md) for complete guide.

## Related Documentation

- [Container App Architecture](container-app.md)
- [Game Integration Requirements](../development/game-integration.md)
- [Announcement System Integration](../development/announcement-system.md)
- [Dartboard Emulator Integration](../development/dartboard-emulator.md)
- [Add Player Dialog Integration](../development/add-player-dialog.md)
- [Edit Score Dialog Integration](../development/edit-score-dialog.md)
- [Dartboard Connection Info Integration](../development/dartboard-connection-info.md)
- [Remove Darts Modal Integration](../development/remove-darts-modal.md)
- [Dartboard Paused Modal Integration](../development/dartboard-paused-modal.md)
- [Player List Panel Integration](../development/player-list-panel.md)
