# Target Tag - Asset Inventory

## Asset Location
**Base Path:** `assets/games/target_tag/`

## Asset Summary
- **Icons:** 11 files (1 main icon + 10 team icons)
- **Images:** 0 files
- **Sounds:** 15 files
- **Total Assets:** 26 files (~11MB total)

## Icons

**Location:** `assets/games/target_tag/icons/`

### TargetTag-Icon.png
- **Size:** 956 KB
- **Format:** PNG with transparency
- **Usage:** Main game icon displayed on home screen game card
- **Description:** Target Tag logo with neon tech aesthetic

### TargetTag-TeamIcon-01.png through TargetTag-TeamIcon-10.png
- **Size:** ~865-940 KB each
- **Format:** PNG with transparency
- **Usage:** Team identification icons in team mode
- **Description:** Unique team icons randomly assigned to teams
- **Icon Assignment:** Shuffled and assigned to teams at game start
- **Files:**
  - TargetTag-TeamIcon-01.png (941 KB)
  - TargetTag-TeamIcon-02.png (899 KB)
  - TargetTag-TeamIcon-03.png (917 KB)
  - TargetTag-TeamIcon-04.png (864 KB)
  - TargetTag-TeamIcon-05.png (889 KB)
  - TargetTag-TeamIcon-06.png (880 KB)
  - TargetTag-TeamIcon-07.png (905 KB)
  - TargetTag-TeamIcon-08.png (890 KB)
  - TargetTag-TeamIcon-09.png (913 KB)
  - TargetTag-TeamIcon-10.png (927 KB)

## Images

**Location:** `assets/games/target_tag/images/`

No image assets currently used. Target Tag uses solid color backgrounds and gradients rather than texture images.

## Sounds

**Location:** `assets/games/target_tag/sounds/`

### TargetTag-Magical.mp3
- **Duration:** ~13 seconds (total file)
- **Trim:** 0.0s to 8.0s
- **Format:** MP3
- **Usage:** Game start announcement
- **Description:** Magical ascending musical theme
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Fanfare.mp3
- **Duration:** ~1.3 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Turn start announcement
- **Description:** Brief trumpet fanfare
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Swipe.mp3
- **Duration:** ~0.8 seconds (total file longer, trimmed)
- **Trim:** 0.0s to 3.0s
- **Format:** MP3
- **Usage:** Remove darts prompt
- **Description:** Swipe/whoosh sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Spring.mp3
- **Duration:** From 3.5s to end (total file ~7s)
- **Trim:** 3.5s to end
- **Format:** MP3
- **Usage:** Single hit confirmation
- **Description:** Spring bounce sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Blink.mp3
- **Duration:** 0.75 seconds (total file longer)
- **Trim:** 0.5s to 1.25s
- **Format:** MP3
- **Usage:** Double hit confirmation
- **Description:** Quick blink/pop sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Dream.mp3
- **Duration:** 2.0 seconds (total file longer)
- **Trim:** 0.0s to 2.0s
- **Format:** MP3
- **Usage:** Triple hit confirmation
- **Description:** Dreamy ascending chime
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Choir.mp3
- **Duration:** ~4.3 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Bullseye (50) hit confirmation
- **Description:** Angelic choir sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Whistle.mp3
- **Duration:** ~0.5 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Outer bull (25) hit confirmation
- **Description:** Quick whistle sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Teasing.mp3
- **Duration:** ~1.3 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Miss announcement
- **Description:** Teasing/playful sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-WindUp.mp3
- **Duration:** 2.0 seconds (total file longer)
- **Trim:** 0.0s to 2.0s
- **Format:** MP3
- **Usage:** Shield gained announcement
- **Description:** Wind-up mechanical sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Launch.mp3
- **Duration:** ~0.6 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Tagged In status achieved
- **Description:** Launch/blast-off sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-BananaSlip.mp3
- **Duration:** ~0.7 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Tagged Out (lost Tagged In status)
- **Description:** Comedic slip sound
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Ominous.mp3
- **Duration:** ~1.5 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Low shields and vulnerable warnings
- **Description:** Ominous warning tone
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-Villain.mp3
- **Duration:** ~2.2 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Player elimination
- **Description:** Villain/defeat theme
- **Source:** Sound effect library
- **License:** Project asset

### TargetTag-PianoRoll.mp3
- **Duration:** ~0.5 seconds
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Successful tag on opponent
- **Description:** Piano roll ascending scale
- **Source:** Sound effect library
- **License:** Project asset

## Asset Usage in Code

### Loading Icons
```dart
// Main game icon
Image.asset('assets/games/target_tag/icons/TargetTag-Icon.png')

// Team icons (dynamically selected)
Image.asset('assets/games/target_tag/icons/TargetTag-TeamIcon-01.png')
```

### Loading Sounds
```dart
// In sound effects service
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
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other assets ...

  # Target Tag assets
  - assets/games/target_tag/
```

**Note:** Directory-level declaration includes all files within subdirectories (icons/, sounds/).

## Asset Creation Guidelines

### Icons
- **Format:** PNG with transparency
- **Size:** ~900KB optimized for web and native
- **Style:** Neon tech aesthetic, vibrant colors (Hot Pink, Neon Green)
- **Color Scheme:** Match Target Tag palette (Hot Pink #FF007A, Neon Green #00FFA3)

### Sounds
- **Format:** MP3 (best cross-platform compatibility)
- **Bitrate:** 128-192 kbps
- **Sample Rate:** 44.1kHz
- **Duration:** Keep most sounds under 3 seconds for quick feedback
- **Volume Normalization:** Normalize to -6dB to maintain consistent volume
- **Trimming:** Many sounds trimmed to remove silence or extract specific portions

## Shared Assets Used by Other Games

Target Tag sound effects are reused by Carnival Derby:
- TargetTag-Swipe.mp3 (remove darts)
- TargetTag-Teasing.mp3 (miss)
- TargetTag-Spring.mp3 (single hit)
- TargetTag-Blink.mp3 (double hit)
- TargetTag-Dream.mp3 (triple hit)
- TargetTag-Choir.mp3 (bullseye)
- TargetTag-Whistle.mp3 (outer bull)
- TargetTag-Ominous.mp3 (bust)

This reduces asset duplication and maintains consistency across games.

## Future Asset Needs
- [ ] Animated shield visual effects
- [ ] Additional team icon variations (beyond 10)
- [ ] Elimination celebration effects
- [ ] Background music loops
- [ ] Champion victory fanfare

## Asset Credits

### Icons
- **TargetTag-Icon.png:** Custom neon tech design
- **TargetTag-TeamIcon-01.png through 10:** Custom team identification icons

### Sounds
- All sound effects from licensed sound effect library
- Trimmed and optimized for game use

### Licenses
All assets are project assets licensed for use in Dart Games.
