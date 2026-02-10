# Carnival Derby - Announcement and Sound Effect List

This document lists all announcements made during Carnival Derby gameplay with placeholders for sound effects and their start/end times.

## Announcement Types

### 1. Player Turn Announcement
- **Text:** `"{playerName}, it's your turn"`
- **Priority:** `turnTransition` (1 - lowest)
- **When:**
  - 1000ms after game starts (first player)
  - 500ms after takeout finishes (subsequent players)
- **Sound Effect:** `horseraceStart`
  - Asset path: `C:\Users\shuels\Downloads/CarnivalDerby-HorseRace-Start.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 2. Dart Hit - Miss
- **Text:** `"Miss"`
- **Priority:** `dartScore` (2)
- **When:** Immediately when dart lands outside scoring areas
- **Sound Effect:** `miss`
  - Asset path: `sounds/target_tag/TargetTag-Teasing.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 3. Dart Hit - Score (Single/Double/Triple)
- **Text:** Dynamic based on dart (e.g., "Single 20", "Double 18", "Triple 19")
- **Priority:** `dartScore` (2)
- **When:** Immediately when dart hits a scoring area
- **Note:** Uses `DartAnnouncerService.announceDart()` method
- **Sound Effect Options:**
  - **Single Hit:**
    - Asset path: `sounds/target_tag/TargetTag-Spring.mp3`
    - Start time: `3.5` seconds
    - End time: `null` (play from 3.5s to end)
  - **Double Hit:**
    - Asset path: `sounds/target_tag/TargetTag-Blink.mp3`
    - Start time: `0.5` seconds
    - End time: `1.25` seconds
  - **Triple Hit:**
    - Asset path: `sounds/target_tag/TargetTag-Dream.mp3`
    - Start time: `0.0` seconds
    - End time: `2.0` seconds
  - **Bullseye (50):**
    - Asset path: `sounds/target_tag/TargetTag-Choir.mp3`
    - Start time: `0.0` seconds
    - End time: `null` (play entire file)
  - **Outer Bull (25):**
    - Asset path: `sounds/target_tag/TargetTag-Whistle.mp3`
    - Start time: `0.0` seconds
    - End time: `null` (play entire file)

---

### 4. Player Bust
- **Text:** `"{playerName}, you busted and your turn is over"`
- **Priority:** `statusUpdate` (3)
- **When:** 1500ms after the dart score that caused the bust
- **Sound Effect:** `lowShields`
  - Asset path: `sounds/target_tag/TargetTag-Ominous.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 5. Remove Darts - After Bust
- **Text:** `"{playerName}, remove your darts"`
- **Priority:** `turnTransition` (1)
- **When:** 3000ms after bust announcement (total 4500ms from bust dart)
- **Sound Effect:** `removeDarts`
  - Asset path: `sounds/target_tag/TargetTag-Swipe.mp3`
  - Start time: `0.0` seconds
  - End time: `3.0` seconds

---

### 6. Remove Darts - After Winning
- **Text:** `"{playerName}, remove your darts"`
- **Priority:** `turnTransition` (1)
- **When:** 2500ms after winning dart is scored
- **Sound Effect:** `removeDarts`
  - Asset path: `sounds/target_tag/TargetTag-Swipe.mp3`
  - Start time: `0.0` seconds
  - End time: `3.0` seconds

---

### 7. Remove Darts - After 3rd Dart (Normal Turn End)
- **Text:** `"{playerName}, remove your darts"`
- **Priority:** `turnTransition` (1)
- **When:** 2500ms after 3rd dart is scored (no win/bust)
- **Sound Effect:** `removeDarts`
  - Asset path: `sounds/target_tag/TargetTag-Swipe.mp3`
  - Start time: `0.0` seconds
  - End time: `3.0` seconds

---

### 8. Remove Darts - Skip Turn (with darts thrown)
- **Text:** `"{playerName}, remove your darts"`
- **Priority:** `turnTransition` (1)
- **When:** 1500ms after Skip Turn button is pressed (if darts were thrown)
- **Sound Effect:** `removeDarts`
  - Asset path: `sounds/target_tag/TargetTag-Swipe.mp3`
  - Start time: `0.0` seconds
  - End time: `3.0` seconds

---

### 9. Game Complete Announcement
- **Text:** `"The game is complete"`
- **Priority:** `victory` (4 - highest)
- **When:** Immediately upon entering results screen
- **Sound Effect:** `[PLACEHOLDER]`
  - Asset path: `C:\Users\shuels\Downloads/CarnivalDerby-Horse-Gallop.mp3`
  - Start time: `0.0` seconds
  - End time: `null` (play entire file)

---

### 10. Winner Announcement
- **Text:** `"{playerName} is the winner"`
- **Priority:** `victory` (4 - highest)
- **When:** 3000ms after game complete announcement
- **Sound Effect:** `[PLACEHOLDER]`
  - Asset path: none
  - Start time: none
  - End time: none

---

## Game Flow Timeline Example

```
Game Start
    ↓
1000ms → "{Player}, it's your turn" [SFX: Turn Start]
    ↓
[Dart 1 thrown]
    ↓
0ms → "Double 20" [SFX: Double Hit]
    ↓
[Dart 2 thrown]
    ↓
0ms → "Triple 19" [SFX: Triple Hit]
    ↓
[Dart 3 thrown - Player Wins]
    ↓
0ms → "Single 2" [SFX: Single Hit]
    ↓
2500ms → "{Player}, remove your darts" [SFX: Remove Darts]
    ↓
[Takeout] → Navigate to results screen
    ↓
0ms → "The game is complete" [SFX: Game Complete]
    ↓
3000ms → "{Player} is the winner" [SFX: Winner]
```

## Priority Levels

1. **turnTransition (1):** Turn changes, remove darts instructions
2. **dartScore (2):** Dart hit/miss announcements
3. **statusUpdate (3):** Bust notifications
4. **victory (4):** Game completion, winner announcements

## Notes

- All announcements use the global announcer settings (voice engine, announcer style)
- Sound effects play simultaneously with voice announcements
- The queue system ensures announcements don't overlap
- Higher priority announcements will play before lower priority ones if multiple are queued
