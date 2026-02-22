# Monster Mash - Announcements and Sound Effects

## Announcement Helper

**Class:** `MonsterMashAnnouncementHelper`
**File:** `lib/services/monster_mash_announcement_helper.dart`

### Initialization
```dart
class _MonsterMashGameScreenState extends State<MonsterMashGameScreen> {
  MonsterMashAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = MonsterMashAnnouncementHelper(globalQueue);
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
**Triggers:** When game begins
**Message:** "Welcome to Monster Mash! Let the battle begin!"
**Sound Effect:** MonsterMashSoundEffects.gameStart (Organ)

#### announceTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each player's turn
**Message:** "$playerName, your turn"
**Sound Effect:** MonsterMashSoundEffects.turnStart (MonsterScream)

#### announceHit(int number, String multiplier, {bool isMiss})
**Priority:** hitConfirm (2)
**Triggers:** After each dart lands on the board
**Message:** Varies by hit type:
  - Bullseye: "Bullseye!"
  - Outer Bull: "Outer bull"
  - Triple: "Triple [number]"
  - Double: "Double [number]"
  - Single: "Single [number]"
  - Miss: "Miss"
**Sound Effect:** MonsterMashSoundEffects.dartHit (Spring, borrowed from Target Tag)

#### announceHealing(String multiplier, int amount)
**Priority:** hitConfirm (2)
**Triggers:** When player heals (hits own target, bullseye, outer bull)
**Message:** Varies by amount:
  - Full heal (>=50): "Max Health!"
  - +5: "Plus 5!"
  - Other: "Plus [amount]!"
**Sound Effect:** MonsterMashSoundEffects.healing (Whistle, borrowed from Target Tag)

#### announceAttack(String playerName, String multiplier, int damage)
**Priority:** hitConfirm (2)
**Triggers:** When hitting an opponent's target
**Message:** Varies by multiplier:
  - 0 damage (Shadow Walk): "The shadows protect [name]!"
  - Triple: "Devastating strike! [name] takes [damage] damage!"
  - Double: "Powerful hit! [name] feels the pain!"
  - Single: "A glancing blow! [name] feels the sting."
**Sound Effect:** MonsterMashSoundEffects.attack (Growl)

#### announceHealthWarning(String playerName, double percentage)
**Priority:** shieldStatus (3)
**Triggers:** When player's health drops to threshold levels
**Message:** Varies by HP percentage:
  - <=10%: "[name] is barely clinging to life!"
  - <=30%: "[name] is in critical condition!"
  - <=70%: "[name] is starting to weaken!"
  - >70%: No announcement
**Sound Effect:** MonsterMashSoundEffects.healthWarning (Ominous, borrowed from Target Tag)

#### announceElimination(String playerName)
**Priority:** statusChange (4)
**Triggers:** When player reaches 0 HP
**Message:** "[name]! Back to the shadows!"
**Sound Effect:** MonsterMashSoundEffects.elimination (Villain, borrowed from Target Tag)

#### announceHatTrick(String playerName)
**Priority:** statusChange (4)
**Triggers:** When all 3 darts in a turn hit the same opponent
**Message:** "MONSTROUS! Triple strike on [name]!"
**Sound Effect:** MonsterMashSoundEffects.hatTrick (MonsterRoar)

#### announceClutchHeal(String playerName)
**Priority:** statusChange (4)
**Triggers:** When player heals while below 10 HP
**Message:** "[name] rises from near death!"
**Sound Effect:** MonsterMashSoundEffects.clutchHeal (Dream, borrowed from Target Tag)

#### announceBuff(BonusBuff buff)
**Priority:** statusChange (4)
**Triggers:** When a buff activates at round start
**Message:** Varies by buff:
  - Blood Moon: "Blood Moon rises! Attack damage doubled!"
  - Ancient Bandages: "Ancient Bandages discovered! Healing boosted to 5!"
  - Shadow Walk: "Shadow Walk activated! Attacks deal no damage!"
  - Laboratory Spark: "Laboratory Spark! Bullseye zaps all opponents!"
**Sound Effect:** MonsterMashSoundEffects.buffActivation (Fanfare, borrowed from Target Tag)

#### announceRemoveDarts()
**Priority:** turnTransition (1)
**Triggers:** After 3 darts thrown or turn skipped
**Message:** "Remove your darts"
**Sound Effect:** MonsterMashSoundEffects.removeDarts (Swipe, borrowed from Target Tag)

#### announceWinner(String playerName) / announceWinners(List<String> playerNames)
**Priority:** victory (5)
**Triggers:** When game ends (last player standing or Speed Play limit)
**Message:**
  - 1 player: "GAME OVER! The night belongs to [name]!"
  - Multiple (tie): "GAME OVER! The night is shared by [name1] and [name2]!"
**Sound Effect:** None (allows victory music to play)

## Sound Effects

**Service:** `MonsterMashSoundEffects`
**File:** `lib/services/monster_mash_sound_effects.dart`

### Native Sound Effects (4)
**Base Path:** `assets/games/monster_mash/sounds/`

| Effect | File | Trim | Usage |
|--------|------|------|-------|
| gameStart | MonsterMash-Organ.mp3 | 1.75s-9.0s | Game start |
| turnStart | MonsterMash-MonsterScream.mp3 | 3.0s-7.5s | Turn announcements |
| attack | MonsterMash-Growl.mp3 | Full file | Opponent attacks |
| hatTrick | MonsterMash-MonsterRoar.mp3 | 0.0s-2.5s | Hat trick events |

### Borrowed from Target Tag (7)
**Base Path:** `assets/games/target_tag/sounds/`

| Effect | File | Trim | Usage |
|--------|------|------|-------|
| removeDarts | TargetTag-Swipe.mp3 | 0.0s-3.0s | Remove darts prompt |
| dartHit | TargetTag-Spring.mp3 | 3.5s-end | All dart hits |
| healing | TargetTag-Whistle.mp3 | Full file | Healing events |
| healthWarning | TargetTag-Ominous.mp3 | Full file | Health warnings |
| elimination | TargetTag-Villain.mp3 | Full file | Eliminations |
| clutchHeal | TargetTag-Dream.mp3 | 0.0s-2.0s | Clutch heal events |
| buffActivation | TargetTag-Fanfare.mp3 | Full file | Buff activations |

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** - Turn start/end announcements, remove darts
2. **hitConfirm (2)** - Dart hit feedback, healing, attacks
3. **shieldStatus (3)** - Health warnings at threshold levels
4. **statusChange (4)** - Eliminations, hat tricks, clutch heals, buff activations
5. **victory (5)** - Game start, winner announcements

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announceTurn(playerName);
_audioQueue?.announceGameStart();
```

### Announcement with Parameters
```dart
_audioQueue?.announceHit(number, multiplier, isMiss: false);
_audioQueue?.announceHealing(multiplier, healAmount);
_audioQueue?.announceAttack(opponentName, multiplier, damage);
```

### Conditional Announcements
```dart
if (healthPercentage <= 0.70) {
  _audioQueue?.announceHealthWarning(playerName, healthPercentage);
}

if (isHatTrick) {
  _audioQueue?.announceHatTrick(opponentName);
}
```
