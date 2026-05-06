# Pirate's Grid - Asset Inventory

## Asset Location
**Base Path:** `assets/games/pirates_grid/`

## Asset Summary
- **Icons:** 1 file (game selection icon)
- **Images:** 10 files (1 background + 8 characters + 1 background)
- **Pieces:** 3 files (2 flags + 1 empty square)
- **Sounds:** 7 files
- **Total Assets:** 21 files

## Icons

**Location:** `assets/games/pirates_grid/icons/`

### PiratesGrid-Icon.png
- **Format:** PNG with transparency
- **Usage:** Game selection card on the home screen
- **Description:** 3x3 tic-tac-toe grid drawn with thick ink lines on aged parchment paper, with a skull-and-crossbones flag in one cell and a compass rose in another. Small treasure chest in the corner with gold coins. Weathered, vintage warm brown and gold tones. Circle format with elements extending slightly outside the circle edge.

## Images

**Location:** `assets/games/pirates_grid/images/`

### PiratesGrid-Background.png
- **Format:** PNG
- **Usage:** Background image on all 3 screens (menu, game, results) with dark overlay
- **Description:** Wide treasure map background — aged parchment paper texture filling the entire image, with faded ink drawings of sea monsters, compass roses, dotted treasure trails, and small ship illustrations in the margins. Parchment transitions from lighter tan in the center to darker weathered brown at the edges. Includes subtle coffee-stain rings and ink splatters. No characters in the scene. Widescreen format.

## Characters

**Location:** `assets/games/pirates_grid/characters/`

Characters appear as decorative elements on the game screen (Player 1 and Player 2 mascots) and on the results screen. They are NOT used as player avatars — player avatars are the actual player photos set during player creation.

Naming convention: no game-prefix on character files (matches Lunar Lander convention).

### captain_crossbones.png
- **Format:** PNG
- **Usage:** Player 1 mascot — shown in game screen decoration, results screen winner display for P1
- **Description:** Bold, friendly pirate captain in cartoon style. Black tricorn hat with skull-and-crossbones emblem, red coat with gold trim, eye patch over one eye, big confident grin with gold tooth, holding a telescope. Adventurous and heroic feel. White background.

### captain_redbeard.png
- **Format:** PNG
- **Usage:** Player 2 mascot — shown in game screen decoration, results screen winner display for P2
- **Description:** Jolly, friendly pirate captain in cartoon style. Big bushy red beard braided with beads, teal bandana on head, teal sash across chest, two hook hands (one real hand holding a treasure map). Wide cheerful smile, rosy cheeks. Warm and boisterous feel. White background.

### pegleg_pete.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere, not a player mascot
- **Description:** Wiry, energetic pirate in cartoon style. Thin build, wooden peg leg, striped blue and white shirt, red bandana. Balancing on peg leg with arms spread wide, big toothy grin, parrot on shoulder. Agile and funny feel. White background.

### navigator_nora.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere
- **Description:** Smart, adventurous female pirate in cartoon style. Leather tricorn hat with feather, brown vest over white blouse, holding a compass and spyglass. Determined expression with clever smile. Capable and daring feel. White background.

### cannonball_cal.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere
- **Description:** Big, round, jolly pirate in cartoon style. Barrel-chested with a cannon under one arm, bushy black beard, wide smile, sleeveless vest showing muscular arms with anchor tattoos. Strong but friendly feel. White background.

### treasure_tess.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere
- **Description:** Glamorous pirate in cartoon style. Wide-brimmed hat with large feather, gold jewelry everywhere (necklaces, bracelets, rings), holding a jewel-encrusted goblet. Confident smirk, one eyebrow raised. Sassy and fun feel. White background.

### barnacle_bob.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere
- **Description:** Old, wise pirate in cartoon style. Long gray beard reaching his belt, weathered face with kind wrinkles, faded captain's coat with tarnished buttons, leaning on a carved walking stick. Wise storyteller feel. White background.

### monkey_mike.png
- **Format:** PNG
- **Usage:** Decorative character — game screen atmosphere
- **Description:** Small, mischievous monkey in cartoon style wearing a tiny pirate vest and miniature tricorn hat. Sitting on a pile of gold coins, holding a banana in one hand and a small cutlass in the other. Big bright eyes, cheeky grin. Playful and adorable feel. White background.

## Pieces

**Location:** `assets/games/pirates_grid/pieces/`

Grid piece images used inside the 3x3 game grid cells.

Naming convention: game-prefix on piece files (PiratesGrid-).

### PiratesGrid-Flag-Red.png
- **Format:** PNG
- **Usage:** Player 1's claimed cell — displayed inside a grid cell when P1 has planted their flag; shown with Blood Red border glow
- **Description:** Pirate flag (jolly roger style) planted on a small wooden post, hand-drawn ink illustration style. The flag is Blood Red with a white skull and crossbones. Flag waves slightly in the wind. Fits cleanly in a square frame. White background.

### PiratesGrid-Flag-Teal.png
- **Format:** PNG
- **Usage:** Player 2's claimed cell — displayed inside a grid cell when P2 has planted their flag; shown with Sea Foam Teal border glow
- **Description:** Pirate flag (jolly roger style) planted on a small wooden post, hand-drawn ink illustration style. The flag is teal/sea green with a white compass rose emblem. Flag waves slightly in the wind. Fits cleanly in a square frame. White background.

### PiratesGrid-EmptySquare.png
- **Format:** PNG
- **Usage:** Default empty cell state — displayed in each unclaimed grid cell
- **Description:** Empty square section of a treasure map in hand-drawn ink style. Parchment paper texture with faint dotted lines and a small "X" lightly sketched in the center, suggesting hidden treasure. Aged and weathered look. Fits cleanly in a square frame. White background.

## Sounds

**Location:** `assets/games/pirates_grid/sounds/`

Naming convention: game-prefix on sound files (PiratesGrid-).

### PiratesGrid-FlagPlant.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Flag Planted announcement; also used for Two in a Row announcement
- **Description:** Wooden thunk/flag planting sound — the satisfying sound of a flag post being driven into the ground

### PiratesGrid-CannonBoom.mp3
- **Trim:** Start 0s, End 2.0s
- **Format:** MP3
- **Usage:** Match Victory announcement (Best Of match win)
- **Description:** Distant cannon fire — booming and triumphant for a match victory

### PiratesGrid-WaveCrash.mp3
- **Trim:** Start 0s, End 5.0s
- **Format:** MP3
- **Usage:** Miss, Already Claimed, Round Draw, Match Draw announcements
- **Description:** Ocean wave crash — the sound of a dart "lost at sea"

### PiratesGrid-TreasureFound.mp3
- **Trim:** Start 0s, End 1.25s
- **Format:** MP3
- **Usage:** Round Victory announcement
- **Description:** Coins jingling celebration music — the joyful sound of treasure being found

### PiratesGrid-ShipBell.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Game Start, Player Turn, Round Transition announcements
- **Description:** Ship's bell — nautical and clear, marking important moments

### PiratesGrid-SwordClash.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Square Stolen (Mutiny!) announcement when Steal Mode is ON
- **Description:** Sword clashing sound — dramatic and intense for the moment of mutiny

### PiratesGrid-TimerTick.mp3
- **Trim:** Start 0s, End 2.0s
- **Format:** MP3
- **Usage:** Speed Play timer expired announcement; also played in-screen at 5, 4, 3, 2, 1 second countdown
- **Description:** Quick tick sound — urgent countdown urgency for the final seconds

## Asset Usage in Code

### Loading the Icon
```dart
Image.asset('assets/games/pirates_grid/icons/PiratesGrid-Icon.png')
```

### Loading the Background
```dart
decoration: BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/games/pirates_grid/images/PiratesGrid-Background.png'),
    fit: BoxFit.cover,
  ),
)
```

### Loading Characters
```dart
// P1 mascot
Image.asset('assets/games/pirates_grid/characters/captain_crossbones.png')

// P2 mascot
Image.asset('assets/games/pirates_grid/characters/captain_redbeard.png')
```

### Loading Piece Images
```dart
// Empty cell
Image.asset('assets/games/pirates_grid/pieces/PiratesGrid-EmptySquare.png')

// Player 1 flag
Image.asset('assets/games/pirates_grid/pieces/PiratesGrid-Flag-Red.png')

// Player 2 flag
Image.asset('assets/games/pirates_grid/pieces/PiratesGrid-Flag-Teal.png')
```

### Loading Sounds
```dart
class PiratesGridSoundEffects {
  static const String _basePath = 'assets/games/pirates_grid/sounds/';

  static const SoundEffectConfig flagPlant = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-FlagPlant.mp3',
    startSeconds: null,
    endSeconds: null,
  );
  // ... etc.
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other game assets ...

  # Pirate's Grid assets
  - assets/games/pirates_grid/
```

**Note:** Directory-level declaration includes all files within all subdirectories (icons/, images/, characters/, pieces/, sounds/).

## Asset Creation Guidelines

### Icons
- **Format:** PNG with transparency
- **Size:** 512x512px recommended for the icon
- **Style:** Hand-drawn ink illustration on parchment, circle format
- **Color Scheme:** Warm browns, golds, and Ink Black lines

### Character Images
- **Format:** PNG with transparency (or white background for removal)
- **Size:** At least 300x400px
- **Style:** Friendly cartoon pirate style, white background
- **Color Scheme:** Rich colors with Ink Black outlines

### Piece Images
- **Format:** PNG (white background or transparency)
- **Size:** Square format, at least 200x200px
- **Style:** Hand-drawn ink style on parchment
- **Color Scheme:** Flag Red uses `#8B0000` (Blood Red), Flag Teal uses `#2E8B8B` (Sea Foam Teal)

### Sounds
- **Format:** MP3 (cross-platform compatible)
- **Recommended Bitrate:** 128kbps
- **Sample Rate:** 44.1kHz
- **Duration:** Under 6 seconds for game sounds; longer ok for music
- **Volume Normalization:** Normalize to -14 LUFS for consistent playback volume

## Asset Credits

All character images, background, icon, piece images, and sound effects were generated specifically for Pirate's Grid. No third-party assets.
