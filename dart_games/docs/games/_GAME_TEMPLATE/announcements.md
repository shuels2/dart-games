# [Game Name] - Announcements and Sound Effects

## Announcement Helper

**Class:** `[GameName]AnnouncementHelper`
**File:** `lib/services/[game_name]_announcement_helper.dart`

### Initialization
```dart
class _[GameName]ScreenState extends State<[GameName]Screen> {
  [GameName]AnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = [GameName]AnnouncementHelper(globalQueue);
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

### Announcement Methods

#### announceGameStart()
**Priority:** [Priority level]
**Triggers:** [When this announcement plays]
**Message:** "[Example announcement text]"
**Sound Effect:** [Sound effect name or none]

#### announcePlayerTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** [When this announcement plays]
**Message:** "[Example: $playerName, your turn]"
**Sound Effect:** [Sound effect name or none]

#### announce[Event1](...)
**Priority:** [Priority level]
**Triggers:** [When this announcement plays]
**Message:** "[Example announcement text]"
**Sound Effect:** [Sound effect name or none]

#### announce[Event2](...)
**Priority:** [Priority level]
**Triggers:** [When this announcement plays]
**Message:** "[Example announcement text]"
**Sound Effect:** [Sound effect name or none]

[Add all announcement methods used by this game]

## Sound Effects

**Service:** `[GameName]SoundEffects`
**File:** `lib/services/[game_name]_sound_effects.dart`
**Base Path:** `assets/games/[game_name]/sounds/`

### Sound Effect Inventory

#### [SoundEffect1Name]
- **File:** `[FileName].mp3`
- **Duration:** [total duration]
- **Trim:** Start at [X]s, end at [Y]s (or null for full file)
- **Usage:** [When this sound plays]
- **Priority Context:** [Priority level when used]

#### [SoundEffect2Name]
- **File:** `[FileName].mp3`
- **Duration:** [total duration]
- **Trim:** Start at [X]s, end at [Y]s (or null for full file)
- **Usage:** [When this sound plays]
- **Priority Context:** [Priority level when used]

[Add all sound effects for this game]

### Configuration Example
```dart
class [GameName]SoundEffects {
  static const String _basePath = 'assets/games/[game_name]/sounds/';

  static const SoundEffectConfig [soundEffect1] = SoundEffectConfig(
    assetPath: '${_basePath}[FileName].mp3',
    startSeconds: [X.X],
    endSeconds: [Y.Y],
  );

  static const SoundEffectConfig [soundEffect2] = SoundEffectConfig(
    assetPath: '${_basePath}[FileName].mp3',
    startSeconds: [X.X],
    endSeconds: null,  // Use entire file
  );
}
```

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** - Turn start/end announcements
2. **hitConfirm (2)** - Immediate feedback for dart throws
3. **shieldStatus (3)** - Status changes (shields, tagged-in, etc.)
4. **statusChange (4)** - General game state changes
5. **victory (5)** - Game over and winner announcements

### Priority Usage in This Game
[Describe which priority levels are used for which types of announcements in this game]

## Voice Scripts

### Game Start
**Text:** "[Full announcement text]"
**Personality Variations:**
- Professional: "[Variation]"
- Excited: "[Variation]"
- Calm: "[Variation]"
- Funny: "[Variation]"
- Drill Sergeant: "[Variation]"

### Player Turn
**Text:** "[Full announcement text with $playerName]"

### [Event Type]
**Text:** "[Full announcement text]"

[Add key voice scripts for major game events]

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announce[EventName]();
```

### Announcement with Parameters
```dart
_audioQueue?.announce[EventName](playerName);
```

### Conditional Announcements
```dart
if ([condition]) {
  _audioQueue?.announce[EventName]();
}
```
