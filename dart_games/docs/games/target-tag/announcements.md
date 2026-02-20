# Target Tag - Announcements and Sound Effects

## Announcement Helper

**Class:** `TargetTagAnnouncementHelper`
**File:** `lib/services/target_tag_announcement_helper.dart`

### Initialization
```dart
class _TargetTagGameScreenState extends State<TargetTagGameScreen> {
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
}
```

### Announcement Methods

#### announceGameStart()
**Priority:** victory (5)
**Triggers:** When game begins (after first turn announced)
**Message:** "Welcome to Target Tag! Fill those shields!"
**Sound Effect:** TargetTagSoundEffects.gameStart

#### announceTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each player's turn
**Message:** "$playerName, your turn"
**Sound Effect:** TargetTagSoundEffects.turnStart

#### announceHit(int number, String multiplier, {bool isMiss})
**Priority:** hitConfirm (2)
**Triggers:** After each dart lands on the board
**Message:** Varies by hit type:
  - Bullseye: "Bullseye!"
  - Outer Bull: "Outer bull"
  - Triple: "Triple [number]" (e.g., "Triple 20")
  - Double: "Double [number]" (e.g., "Double 15")
  - Single: "Single [number]" (e.g., "Single 20")
  - Miss: "Miss"
**Sound Effect:**
  - Bullseye: TargetTagSoundEffects.bullseye
  - Outer Bull: TargetTagSoundEffects.outerBull
  - Triple: TargetTagSoundEffects.tripleHit
  - Double: TargetTagSoundEffects.doubleHit
  - Single: TargetTagSoundEffects.singleHit
  - Miss: TargetTagSoundEffects.miss

#### announceShieldGained(String playerName, int shields, int shieldMax)
**Priority:** shieldStatus (3)
**Triggers:** When player hits their target number and gains shields
**Message:** "[shields] shields" (e.g., "3 shields")
**Sound Effect:** TargetTagSoundEffects.shieldGained

#### announceTaggedIn(List<String> playerNames)
**Priority:** statusChange (4)
**Triggers:** When player(s) reach Shield Max and become Tagged In
**Message:**
  - 1 player: "JACKPOT! [name] is TAGGED IN!"
  - 2 players: "JACKPOT! [name1] and [name2] are TAGGED IN!"
  - 3+ players: "JACKPOT! [name1], [name2], and [name3] are TAGGED IN!"
**Sound Effect:** TargetTagSoundEffects.taggedIn

#### announceTaggedOut(List<String> playerNames)
**Priority:** statusChange (4)
**Triggers:** When Tagged In player(s) drop below Shield Max
**Message:**
  - 1 player: "Shield compromised! [name] is back on the hunt."
  - 2+ players: "Shield compromised! [name1] and [name2] are back on the hunt."
**Sound Effect:** TargetTagSoundEffects.taggedOut

#### announceLowShields(List<String> playerNames)
**Priority:** shieldStatus (3)
**Triggers:** When player(s) have exactly 1 shield remaining
**Message:**
  - 1 player: "Warning! [name]'s shields are almost gone!"
  - 2+ players: "Warning! [name1] and [name2]'s shields are almost gone!"
**Sound Effect:** TargetTagSoundEffects.lowShields

#### announceVulnerable(List<String> playerNames)
**Priority:** shieldStatus (3)
**Triggers:** When player(s) have 0 shields (vulnerable to elimination)
**Message:**
  - 1 player: "DANGER! [name] is vulnerable! One more hit and you're out!"
  - 2+ players: "DANGER! [name1] and [name2] are vulnerable! One more hit and you're out!"
**Sound Effect:** TargetTagSoundEffects.lowShields

#### announceEliminated(List<String> playerNames)
**Priority:** statusChange (4)
**Triggers:** When player(s) are eliminated from the game
**Message:**
  - 1 player: "[name] is Tagged Out! Better luck next time!"
  - 2+ players: "[name1] and [name2] are Tagged Out! Better luck next time!"
**Sound Effect:** TargetTagSoundEffects.eliminated

#### announceSuccessfulTag()
**Priority:** hitConfirm (2)
**Triggers:** When Tagged In player hits opponent's target number
**Message:** "Tag! Got 'em!"
**Sound Effect:** TargetTagSoundEffects.successfulTag

#### announceWinner(List<String> playerNames)
**Priority:** victory (5)
**Triggers:** When only one player/team remains (game over)
**Message:**
  - 1 player: "GAME OVER! [name] is the Target Tag Champion!"
  - 2 players (team): "GAME OVER! [name1] and [name2] are the Target Tag Champions!"
**Sound Effect:** None (allows victory music to play)

#### announceRemoveDarts()
**Priority:** turnTransition (1)
**Triggers:** After 3 darts thrown or turn skipped
**Message:** "Remove your darts"
**Sound Effect:** TargetTagSoundEffects.removeDarts

## Sound Effects

**Service:** `TargetTagSoundEffects`
**File:** `lib/services/target_tag_sound_effects.dart`
**Base Path:** `assets/games/target_tag/sounds/`

### Sound Effect Inventory

#### gameStart
- **File:** `TargetTag-Magical.mp3`
- **Duration:** 8.0 seconds (total file longer, trimmed)
- **Trim:** 0.0s to 8.0s
- **Usage:** Played at game start
- **Priority Context:** victory (5)

#### turnStart
- **File:** `TargetTag-Fanfare.mp3`
- **Duration:** ~1.3 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when announcing player's turn
- **Priority Context:** turnTransition (1)

#### removeDarts
- **File:** `TargetTag-Swipe.mp3`
- **Duration:** 3.0 seconds (total file longer, trimmed)
- **Trim:** 0.0s to 3.0s
- **Usage:** Played when prompting to remove darts
- **Priority Context:** turnTransition (1)

#### singleHit
- **File:** `TargetTag-Spring.mp3`
- **Duration:** From 3.5s to end
- **Trim:** 3.5s to end
- **Usage:** Played when single number is hit
- **Priority Context:** hitConfirm (2)

#### doubleHit
- **File:** `TargetTag-Blink.mp3`
- **Duration:** 0.75 seconds
- **Trim:** 0.5s to 1.25s
- **Usage:** Played when double ring is hit
- **Priority Context:** hitConfirm (2)

#### tripleHit
- **File:** `TargetTag-Dream.mp3`
- **Duration:** 2.0 seconds
- **Trim:** 0.0s to 2.0s
- **Usage:** Played when triple ring is hit
- **Priority Context:** hitConfirm (2)

#### bullseye
- **File:** `TargetTag-Choir.mp3`
- **Duration:** ~4.3 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when bullseye (50) is hit
- **Priority Context:** hitConfirm (2)

#### outerBull
- **File:** `TargetTag-Whistle.mp3`
- **Duration:** ~0.5 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when outer bull (25) is hit
- **Priority Context:** hitConfirm (2)

#### miss
- **File:** `TargetTag-Teasing.mp3`
- **Duration:** ~1.3 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when dart misses
- **Priority Context:** hitConfirm (2)

#### shieldGained
- **File:** `TargetTag-WindUp.mp3`
- **Duration:** 2.0 seconds
- **Trim:** 0.0s to 2.0s
- **Usage:** Played when player gains shields
- **Priority Context:** shieldStatus (3)

#### taggedIn
- **File:** `TargetTag-Launch.mp3`
- **Duration:** ~0.6 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when player reaches Tagged In status
- **Priority Context:** statusChange (4)

#### taggedOut
- **File:** `TargetTag-BananaSlip.mp3`
- **Duration:** ~0.7 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when player loses Tagged In status
- **Priority Context:** statusChange (4)

#### lowShields
- **File:** `TargetTag-Ominous.mp3`
- **Duration:** ~1.5 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played for low shields warning and vulnerable state
- **Priority Context:** shieldStatus (3)

#### eliminated
- **File:** `TargetTag-Villain.mp3`
- **Duration:** ~2.2 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when player is eliminated
- **Priority Context:** statusChange (4)

#### successfulTag
- **File:** `TargetTag-PianoRoll.mp3`
- **Duration:** ~0.5 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when Tagged In player hits opponent's target
- **Priority Context:** hitConfirm (2)

### Configuration Example
```dart
class TargetTagSoundEffects {
  static const String _basePath = 'games/target_tag/sounds/';

  static const SoundEffectConfig gameStart = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Magical.mp3',
    startSeconds: 0.0,
    endSeconds: 8.0,
  );

  static const SoundEffectConfig singleHit = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Spring.mp3',
    startSeconds: 3.5,
    endSeconds: null,
  );

  static const SoundEffectConfig taggedIn = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Launch.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );
}
```

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** - Turn start/end announcements, remove darts
2. **hitConfirm (2)** - Dart hit feedback, successful tags
3. **shieldStatus (3)** - Shield gains, low shields, vulnerable warnings
4. **statusChange (4)** - Tagged In, Tagged Out, eliminations
5. **victory (5)** - Game start, winner announcements

### Priority Usage in This Game
- **turnTransition:** Player turn announcements, remove darts prompts
- **hitConfirm:** All dart hits (singles, doubles, triples, bulls, misses), successful tags
- **shieldStatus:** Shield gains, low shields warnings (1 shield), vulnerable warnings (0 shields)
- **statusChange:** Tagged In achievements, Tagged Out losses, player eliminations
- **victory:** Game start welcome, final winner announcement

## Voice Scripts

### Game Start
**Text:** "Welcome to Target Tag! Fill those shields!"

### Player Turn
**Text:** "$playerName, your turn"
**Example:** "Alice, your turn"

### Dart Hit
**Text:** Varies by multiplier (see announceHit method above)

### Shield Gained
**Text:** "[shields] shields"
**Example:** "3 shields"

### Tagged In
**Text:** "JACKPOT! [name/names] [is/are] TAGGED IN!"
**Example:** "JACKPOT! Alice is TAGGED IN!"

### Tagged Out
**Text:** "Shield compromised! [name/names] [is/are] back on the hunt."
**Example:** "Shield compromised! Bob is back on the hunt."

### Low Shields
**Text:** "Warning! [name/names]'s shields [are] almost gone!"
**Example:** "Warning! Charlie's shields are almost gone!"

### Vulnerable
**Text:** "DANGER! [name/names] [is/are] vulnerable! One more hit and you're out!"
**Example:** "DANGER! Alice is vulnerable! One more hit and you're out!"

### Eliminated
**Text:** "[name/names] [is/are] Tagged Out! Better luck next time!"
**Example:** "Bob is Tagged Out! Better luck next time!"

### Successful Tag
**Text:** "Tag! Got 'em!"

### Winner
**Text:** "GAME OVER! [name/names] [is/are] the Target Tag Champion[s]!"
**Example:** "GAME OVER! Alice is the Target Tag Champion!"

### Remove Darts
**Text:** "Remove your darts"

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announceTurn(playerName);
_audioQueue?.announceGameStart();
```

### Announcement with Parameters
```dart
_audioQueue?.announceHit(number, multiplier, isMiss: false);
_audioQueue?.announceShieldGained(playerName, shields, shieldMax);
```

### Conditional Announcements
```dart
if (newlyTaggedIn.isNotEmpty) {
  _audioQueue?.announceTaggedIn(newlyTaggedInNames);
}

if (newlyEliminated.isNotEmpty) {
  _audioQueue?.announceEliminated(newlyEliminatedNames);
}
```

### Multiple Player Announcements
```dart
// Handles 1, 2, or 3+ players with proper grammar
_audioQueue?.announceTaggedIn(['Alice', 'Bob']);
// "JACKPOT! Alice and Bob are TAGGED IN!"

_audioQueue?.announceEliminated(['Charlie', 'Diana', 'Eve']);
// "Charlie, Diana, and Eve are Tagged Out! Better luck next time!"
```
