# Treasure Divide - Asset Inventory

## Asset Location

**Base Path:** `assets/games/treasure_divide/`

## Asset Summary

- **Icons:** 1 file
- **Images (background + piece images):** 6 files (1 background + 5 pieces)
- **Theme accessory sprites:** 22 PNG files across 8 theme subdirectories
- **Team crests:** 6 PNG files
- **Sounds:** 8 files (some share the same source file with different trim points)
- **Total Assets:** 43 files

## Icons

**Location:** `assets/games/treasure_divide/icons/`

### TreasureDivide-Icon.png

- **Format:** PNG
- **Usage:** Home screen game card, app launcher (if applicable)
- **Description:** Treasure chest overflowing with gold coins and gems, with a rolled-up treasure map and compass beside it, tropical island in the background; bright colorful cartoon pirate style

## Images

**Location:** `assets/games/treasure_divide/images/`

### TreasureDivide-Background.png

- **Format:** PNG
- **Usage:** Menu, game, and results screen background
- **Description:** Wide panoramic tropical ocean with scattered islands, a pirate ship sailing in the distance, and a large treasure map in the foreground; warm sunset lighting; cartoon pirate adventure style; slightly blurred with dark overlay for UI readability

## Piece Images

**Location:** `assets/games/treasure_divide/pieces/`

### TreasureChestFull.png

- **Format:** PNG
- **Usage:** Treasure map corner display when player/crew has accumulated gold
- **Description:** Open treasure chest overflowing with gold coins, gems, and jewelry; warm golden glow; wooden chest with metal bands; cartoon pirate style

### TreasureChestEmpty.png

- **Format:** PNG
- **Usage:** Treasure map corner display when player/crew has 0 gold
- **Description:** Open treasure chest that is nearly empty with just a few scattered coins at the bottom; looks deflated; cartoon pirate style

### TreasureChestHalved.png

- **Format:** PNG
- **Usage:** Treasure map animation during halve/quarter event
- **Description:** Treasure chest tipping over with gold coins and gems spilling out dramatically; coins mid-air, water splashing; exciting but not scary; cartoon pirate style

### TreasureMap.png

- **Format:** PNG
- **Usage:** Background texture for the TreasureMapWidget (parchment base); also displayed in Captain's Log on menu
- **Description:** Weathered treasure map showing a dotted path between numbered islands; each island has a number representing a round; path leads to a big X at the end; parchment texture, hand-drawn style; wide format

### GoldCoin.png

- **Format:** PNG
- **Usage:** Coin icon beside the treasure score in the Active Player Panel
- **Description:** Single shiny gold doubloon with a pirate anchor embossed on it; gleaming with light; simple clean design; cartoon pirate style

## Theme Accessory Sprites

**Location:** `assets/games/treasure_divide/themes/<theme_name>/`

All sprites are transparent PNGs (white background removed by asset author before commit). Runtime: `PirateAvatarWidget` composites them over the player's avatar at landmark-derived anchor points.

### Theme 0 — Captain (`themes/captain/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `hat.png` | 1024×1024 | headTop | 1.6× faceScale |
| `eyepatch.png` | 512×512 | leftEye | 0.4× faceScale |
| `parrot.png` | 512×512 | upper-right frame corner | 0.35× avatar width |

### Theme 1 — First Mate (`themes/first_mate/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `bandana.png` | 1024×1024 | headTop (slightly lower) | 1.2× faceScale |
| `monkey.png` | 512×512 | upper-left frame corner | 0.3× avatar width |

### Theme 2 — Bosun (`themes/bosun/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `tricorn.png` | 1024×1024 | headTop | 1.4× faceScale |
| `crab.png` | 256×256 | above headTop by 0.1× avatar height | 0.25× faceScale |
| `scar.png` | 256×256 | between noseTip and rightEar | 0.2× faceScale |

### Theme 3 — Navigator (`themes/navigator/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `sailor_cap.png` | 1024×1024 | headTop | 1.1× faceScale |
| `monocle.png` | 512×512 | rightEye | 0.4× faceScale |
| `compass.png` | 512×512 | lower-right frame corner | 0.25× avatar width |

### Theme 4 — Lookout (`themes/lookout/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `lookout_bandana.png` | 1024×1024 | headTop | 1.2× faceScale |
| `telescope.png` | 1024×1024 | rightEye | 0.6× avatar width (length) |

### Theme 5 — Cook (`themes/cook/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `chef_hat.png` | 1024×1024 | headTop | 1.3× faceScale |
| `neckerchief.png` | 512×512 | chin | 0.9× faceScale |
| `spoon.png` | 1024×1024 | lower-left frame corner | 0.4× avatar width |

### Theme 6 — Gunner (`themes/gunner/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `floppy_hat.png` | 1024×1024 | headTop | 1.8× faceScale (exaggerated comic) |
| `cannonball.png` | 512×512 | lower-left frame corner | 0.25× avatar width |

### Theme 7 — Cabin Boy (`themes/cabin_boy/`)

| File | Nominal size | Anchor | Width factor |
|------|-------------|--------|-------------|
| `tiny_cap.png` | 512×512 | headTop (jaunty offset) | 0.7× faceScale (too small — funny) |
| `seahorse.png` | 512×512 | lower-right frame corner | 0.3× avatar width |
| `freckles.png` | 512×512 | between noseTip and ears | 0.6× faceScale |

**Total accessory sprites: 22 PNGs**

## Team Crests

**Location:** `assets/games/treasure_divide/teams/`

Each crest has an associated team color for crew box styling.

| File | Team Color | Description |
|------|-----------|-------------|
| `CrossedCutlasses.png` | Blood Red `#C41E3A` | Round wooden medallion with two crossed gold cutlass swords on a deep red field |
| `GoldDoubloon.png` | Treasure Gold `#FFD700` | Round emblem with a gleaming gold doubloon coin anchored, ringed by braided rope |
| `CompassRose.png` | Ocean Teal `#008B8B` | Round emblem with ornate navigator's compass rose in gold and white on teal field |
| `ShipsWheel.png` | Plank Brown `#8B6914` | Round emblem with wooden ship's wheel with brass fittings on warm brown field |
| `Anchor.png` | Sail White `#FFF8E7` | Round emblem with white-and-silver ship's anchor wrapped with golden chain on cream field |
| `Kraken.png` | Island Green `#228B22` | Round emblem with friendly cartoon green kraken with curling tentacles, smiling |

## Sounds

**Location:** `assets/games/treasure_divide/sounds/`

| File | Source trim | Usage |
|------|------------|-------|
| `TreasureDivide-CoinClink.mp3` | 0s – 0.24s | Coin Clink (standard hit, Safe) |
| `TreasureDivide-CoinClink.mp3` | 2.0s – 3.0s | Coin Shower (triple/bull hits, crew plunder) — same file, different trim |
| `TreasureDivide-Splash.mp3` | 0.5s – 2.0s, 500ms fade | Splash (score halved, crew wipeout) |
| `TreasureDivide-MapUnfurl.mp3` | 0s – 1.25s, 500ms fade | Map Unfurl (game start, new round, special rounds) |
| `TreasureDivide-MissSplash.mp3` | 0s – 0.2s | Miss Splash (single dart miss) |
| `TreasureDivide-Bell.mp3` | 0s – 0.1s, 250ms fade | Turn Bell (player/crew turn start) |
| `TreasureDivide-Fanfare.mp3` | 0s – 4.0s, 500ms fade | Victory Fanfare (game winner) |
| `TreasureDivide-Storm.mp3` | 0s – 1.5s, 500ms fade | Quarter Storm (score quartered penalty) |

**Note:** Coin Clink and Coin Shower share the same source MP3 file (`TreasureDivide-CoinClink.mp3`) but are defined as two separate `SoundEffectConfig` entries with different `startSeconds` / `endSeconds` values.

## Asset Usage in Code

### Loading Icons

```dart
Image.asset('assets/games/treasure_divide/icons/TreasureDivide-Icon.png')
```

### Loading Piece Images

```dart
Image.asset('assets/games/treasure_divide/pieces/TreasureChestFull.png')
Image.asset('assets/games/treasure_divide/pieces/TreasureChestHalved.png')
Image.asset('assets/games/treasure_divide/pieces/TreasureChestEmpty.png')
```

### Loading Theme Sprites (via PirateAvatarWidget / pirate_themes.dart)

```dart
// In lib/widgets/treasure_divide/pirate_themes.dart
const List<PirateTheme> kPirateThemes = [
  PirateTheme(name: 'Captain', accessories: [
    PirateAccessory(
      'assets/games/treasure_divide/themes/captain/hat.png',
      anchor: AnchorPoint.headTop,
      widthFactor: 1.6,
    ),
    // ...
  ]),
  // Themes 1..7 follow the same pattern
];
```

### Loading Team Crests

```dart
Image.asset('assets/games/treasure_divide/teams/CrossedCutlasses.png')
```

### Loading Sounds

```dart
class TreasureDivideSoundEffects {
  static const String _basePath = 'assets/games/treasure_divide/sounds/';

  static const SoundEffectConfig coinClink = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 0.0,
    endSeconds: 0.24,
  );

  static const SoundEffectConfig coinShower = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 2.0,
    endSeconds: 3.0,
  );
  // ...
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # Treasure Divide assets
  - assets/games/treasure_divide/
```

The directory-level declaration covers all subdirectories: `icons/`, `images/`, `pieces/`, `sounds/`, `teams/`, and `themes/<theme>/`.

## Asset Creation Notes

### Theme Sprites

- Source images generated with AI using "Solid pure white (#FFFFFF) background" prompts
- Background removal performed MANUALLY by the asset author (Photoshop, `remove.bg`, `rembg`, etc.) BEFORE committing
- Only transparent PNGs are committed to `assets/games/treasure_divide/themes/`
- The Flutter runtime does NOT perform background removal — white-bg source PNGs are NOT what ships
- Sprite size standard: Large items 1024×1024; Medium items 512×512; Small decals 256×256 (sized for 4K displays)

### Team Crests

- Round shape with rope border; heraldic family-friendly cartoon pirate style; no skulls
- Each crest uses its associated team color as the primary field color
- White backgrounds removed before committing (same workflow as theme sprites)

### Sounds

- Format: MP3, 128kbps, 44.1kHz
- Coin Clink source file contains both the short clink (0–0.24s) and the coin shower section (2.0–3.0s) — trim points are defined in `TreasureDivideSoundEffects`
