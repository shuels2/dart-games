# Target Tag - Announcement and Sound Effect List

This document lists all announcements made during Target Tag gameplay with their configured sound effects and start/end times.

## Announcement Types

### 1. Game Start
- **Text:** `"Welcome to Target Tag! Fill those shields!"`
- **Priority:** `victory` (5 - highest)
- **When:** Immediately after game initialization
- **Sound Effect:** `gameStart`
  - Asset path: `sounds/target_tag/TargetTag-Magical.mp3`
  - Start time: `0.0` seconds
  - End time: `8.0` seconds

---

### 2. Player Turn Announcement
- **Text:** `"{playerName}, your turn"`
- **Priority:** `turnTransition` (1 - lowest)
- **When:** 2500ms after game start (first player), then after each turn completes
- **Sound Effect:** `turnStart`
  - Asset path: `sounds/target_tag/TargetTag-Fanfare.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 3. Dart Hit - Miss
- **Text:** `"Miss"`
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart lands outside scoring areas
- **Sound Effect:** `miss`
  - Asset path: `sounds/target_tag/TargetTag-Teasing.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 4. Dart Hit - Single
- **Text:** `"Single {number}"` (e.g., "Single 14")
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart hits a single scoring area
- **Sound Effect:** `singleHit`
  - Asset path: `sounds/target_tag/TargetTag-Spring.mp3`
  - Start time: `3.5` seconds
  - End time: `null` (play from 3.5s to end)

---

### 5. Dart Hit - Double
- **Text:** `"Double {number}"` (e.g., "Double 14")
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart hits a double scoring area
- **Sound Effect:** `doubleHit`
  - Asset path: `sounds/target_tag/TargetTag-Blink.mp3`
  - Start time: `0.5` seconds
  - End time: `1.25` seconds

---

### 6. Dart Hit - Triple
- **Text:** `"Triple {number}"` (e.g., "Triple 14")
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart hits a triple scoring area
- **Sound Effect:** `tripleHit`
  - Asset path: `sounds/target_tag/TargetTag-Dream.mp3`
  - Start time: `0.0` seconds
  - End time: `2.0` seconds

---

### 7. Dart Hit - Bullseye
- **Text:** `"Bullseye!"`
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart hits the bullseye (50)
- **Sound Effect:** `bullseye`
  - Asset path: `sounds/target_tag/TargetTag-Choir.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 8. Dart Hit - Outer Bull
- **Text:** `"Outer bull"`
- **Priority:** `hitConfirm` (2)
- **When:** Immediately when dart hits the outer bull (25)
- **Sound Effect:** `outerBull`
  - Asset path: `sounds/target_tag/TargetTag-Whistle.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 9. Shield Gained
- **Text:** `"{shields} shields"` (e.g., "3 shields")
- **Priority:** `shieldStatus` (3)
- **When:** After a dart hits the player's target number and shields increase
- **Sound Effect:** `shieldGained`
  - Asset path: `sounds/target_tag/TargetTag-WindUp.mp3`
  - Start time: `0.0` seconds
  - End time: `2.0` seconds

---

### 10. Tagged In (Single Player)
- **Text:** `"JACKPOT! {playerName} is TAGGED IN!"`
- **Priority:** `statusChange` (4)
- **When:** When a player/team reaches maximum shields
- **Sound Effect:** `taggedIn`
  - Asset path: `sounds/target_tag/TargetTag-Launch.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 11. Tagged In (Multiple Players/Team)
- **Text:** `"JACKPOT! {player1} and {player2} are TAGGED IN!"` or `"JACKPOT! {p1}, {p2}, and {p3} are TAGGED IN!"`
- **Priority:** `statusChange` (4)
- **When:** When multiple players or a team reaches maximum shields
- **Sound Effect:** `taggedIn`
  - Asset path: `sounds/target_tag/TargetTag-Launch.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 12. Successful Tag on Opponent
- **Text:** `"Tag! Got 'em!"`
- **Priority:** `hitConfirm` (2)
- **When:** When a tagged-in player hits an opponent's target number
- **Sound Effect:** `successfulTag`
  - Asset path: `sounds/target_tag/TargetTag-PianoRoll.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 13. Low Shields Warning (Single Player)
- **Text:** `"Warning! {playerName}'s shields are almost gone!"`
- **Priority:** `shieldStatus` (3)
- **When:** When a player's shields drop to 1 or 2
- **Sound Effect:** `lowShields`
  - Asset path: `sounds/target_tag/TargetTag-Ominous.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 14. Low Shields Warning (Multiple Players/Team)
- **Text:** `"Warning! {player1} and {player2}'s shields are almost gone!"`
- **Priority:** `shieldStatus` (3)
- **When:** When multiple players or a team's shields drop to 1 or 2
- **Sound Effect:** `lowShields`
  - Asset path: `sounds/target_tag/TargetTag-Ominous.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 15. Tagged Out (Lost Tagged-In Status)
- **Text:** `"Shield compromised! {playerName} is back on the hunt."` or `"{p1} and {p2} are back on the hunt."`
- **Priority:** `statusChange` (4)
- **When:** When a tagged-in player/team loses tagged-in status (shields drop below max)
- **Sound Effect:** `taggedOut`
  - Asset path: `sounds/target_tag/TargetTag-BananaSlip.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 16. Player Eliminated (Single Player)
- **Text:** `"{playerName} is Tagged Out! Better luck next time!"`
- **Priority:** `statusChange` (4)
- **When:** When a player's shields reach 0
- **Sound Effect:** `eliminated`
  - Asset path: `sounds/target_tag/TargetTag-Villain.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 17. Player Eliminated (Multiple Players/Team)
- **Text:** `"{player1} and {player2} are Tagged Out! Better luck next time!"`
- **Priority:** `statusChange` (4)
- **When:** When multiple players or a team's shields reach 0
- **Sound Effect:** `eliminated`
  - Asset path: `sounds/target_tag/TargetTag-Villain.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 18. Winner Announcement (Single Player)
- **Text:** `"GAME OVER! {playerName} is the Target Tag Champion!"`
- **Priority:** `victory` (5)
- **When:** When only one player/team remains
- **Sound Effect:** None configured (could add victory music)

---

### 19. Winner Announcement (Multiple Winners/Team)
- **Text:** `"GAME OVER! {player1} and {player2} are the Target Tag Champions!"`
- **Priority:** `victory` (5)
- **When:** When only one team remains
- **Sound Effect:** None configured (could add victory music)

---

### 20. Remove Darts
- **Text:** `"Remove your darts"`
- **Priority:** `turnTransition` (1)
- **When:** After 3 darts are thrown or game state changes
- **Sound Effect:** `removeDarts`
  - Asset path: `sounds/target_tag/TargetTag-Swipe.mp3`
  - Start time: `0.0` seconds
  - End time: `3.0` seconds

---

## Game Flow Timeline Example (Solo Mode)

```
Game Start
    ↓
0ms → "Welcome to Target Tag! Fill those shields!" [SFX: Magical (0s-8s)]
    ↓
2500ms → "Alice, your turn" [SFX: Fanfare]
    ↓
[Dart 1 thrown - hits target]
    ↓
0ms → "Single 14" [SFX: Spring (3.5s-end)]
    ↓
0ms → "1 shields" [SFX: WindUp (0s-2s)]
    ↓
[Dart 2 thrown - hits target]
    ↓
0ms → "Double 14" [SFX: Blink (0.5s-1.25s)]
    ↓
0ms → "3 shields" [SFX: WindUp (0s-2s)]
    ↓
[Dart 3 thrown - hits target]
    ↓
0ms → "Triple 14" [SFX: Dream (0s-2s)]
    ↓
0ms → "JACKPOT! Alice is TAGGED IN!" [SFX: Launch]
    ↓
0ms → "Remove your darts" [SFX: Swipe (0s-3s)]
    ↓
→ "Bob, your turn" [SFX: Fanfare]
```

## Game Flow Timeline Example (Attack Scenario)

```
Alice's turn (tagged-in, 5 shields)
    ↓
"Alice, your turn" [SFX: Fanfare]
    ↓
[Dart 1 thrown - hits Bob's target 20]
    ↓
0ms → "Single 20" [SFX: Spring (3.5s-end)]
    ↓
0ms → "Tag! Got 'em!" [SFX: PianoRoll]
    ↓
0ms → "Warning! Bob's shields are almost gone!" [SFX: Ominous]
    ↓
[Dart 2 thrown - hits Bob's target 20]
    ↓
0ms → "Single 20" [SFX: Spring (3.5s-end)]
    ↓
0ms → "Tag! Got 'em!" [SFX: PianoRoll]
    ↓
0ms → "Bob is Tagged Out! Better luck next time!" [SFX: Villain]
    ↓
[Dart 3 thrown - miss]
    ↓
0ms → "Miss" [SFX: Teasing]
    ↓
0ms → "Remove your darts" [SFX: Swipe (0s-3s)]
    ↓
→ "Carol, your turn" [SFX: Fanfare]
```

## Priority Levels

1. **turnTransition (1):** Turn changes, remove darts instructions
2. **hitConfirm (2):** Dart hit/miss announcements, successful tags
3. **shieldStatus (3):** Shield gains, low shield warnings
4. **statusChange (4):** Tagged-in, tagged-out, eliminations
5. **victory (5):** Game start, game over, winners

## Notes

- All announcements use the global announcer settings (voice engine, announcer style)
- Sound effects play simultaneously with voice announcements
- The queue system ensures announcements don't overlap (priority-based FIFO)
- Higher priority announcements will play before lower priority ones if multiple are queued
- Target Tag has significantly more announcement types than Carnival Derby due to its complex shield/tag mechanics
