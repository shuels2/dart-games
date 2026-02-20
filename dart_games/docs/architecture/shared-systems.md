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
- Store victory music files
- Random selection from user's library
- Cross-platform file handling (web data URLs, native file paths)
- Add/remove music files
- Persist music library

### File Handling
- **Web:** Data URLs (base64-encoded music data)
- **Native:** File system paths

### Usage in Games
```dart
final musicService = VictoryMusicService();

// Check if custom music available
if (await musicService.hasCustomMusic()) {
  // Get random music file
  final musicSource = await musicService.getRandomMusicSource();

  if (musicSource != null) {
    // Play music using appropriate player
    final player = AudioPlayer();
    if (kIsWeb) {
      await player.play(UrlSource(musicSource));
    } else {
      await player.play(DeviceFileSource(musicSource));
    }
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
- Only visible in emulator mode (when `!dartboardProvider.isConnected`)
- Game-specific styling via config

#### Configuration Classes
- **DartboardSectionConfig:** Styling for dartboard container
  - Factory methods: `.carnivalDerby()`, `.targetTag()`
- **DartboardFABConfig:** Styling for FAB button
  - Factory methods: `.carnivalDerby()`, `.targetTag()`

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
- `AddPlayerDialogConfig.optionsScreen(context)` - Material Design defaults

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

### SharedPreferences Keys
- `players` - Player list (JSON)
- `selected_players` - Currently selected players
- `dartboard_connected` - Connection state
- `use_emulator` - Emulator mode preference
- `voice_enabled` - Announcer enabled/disabled
- `voice_engine` - Selected voice engine
- `announcer_personality` - Selected personality
- `victory_music_files` - Victory music library (JSON)

### Storage Pattern
```dart
final prefs = await SharedPreferences.getInstance();

// Save data
await prefs.setString('key', jsonEncode(data));

// Load data
final jsonString = prefs.getString('key');
if (jsonString != null) {
  final data = jsonDecode(jsonString);
}
```

## Cross-Platform Considerations

All shared systems support:
- ✅ Web browsers (Chrome, Safari, Firefox, Edge)
- ✅ iOS tablets (iPad)
- ✅ Android tablets

Platform-specific implementations handled internally.

## Related Documentation

- [Container App Architecture](container-app.md)
- [Game Integration Requirements](../development/game-integration.md)
- [Announcement System Integration](../development/announcement-system.md)
- [Dartboard Emulator Integration](../development/dartboard-emulator.md)
- [Add Player Dialog Integration](../development/add-player-dialog.md)
- [Edit Score Dialog Integration](../development/edit-score-dialog.md)
