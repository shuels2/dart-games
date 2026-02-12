# Claude Development Guidelines for Dart Games

## App Architecture Overview

### Container App Structure

**Dart Games is a container app that provides core infrastructure for multiple games.**

The app architecture consists of:

1. **Core Container App** (Dart Games)
   - Handles dartboard connection (physical Scolia dartboard or emulator)
   - Manages global user/player system
   - Provides centralized settings (announcer, victory music, user management)
   - Ensures consistent experience across all games

2. **Individual Games** (e.g., Carnival Derby)
   - Built on top of the container app
   - Use shared dartboard connection
   - Integrate with global user management
   - Use centralized announcer and victory music systems
   - Follow consistent design language and UX patterns

### Project Structure

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point, theme, navigation
│   ├── models/                      # Data models (Player, GameHistoryEntry, etc.)
│   ├── providers/                   # State management (DartboardProvider, PlayerProvider, etc.)
│   ├── services/                    # Shared services (DartAnnouncerService, VictoryMusicService, etc.)
│   ├── widgets/                     # Reusable widgets (dartboard components, status indicators)
│   └── screens/
│       ├── splash_screen.dart       # Initial loading screen
│       ├── dartboard_setup_screen.dart  # Connect to dartboard or emulator
│       ├── home_screen.dart         # Game selection menu
│       ├── options_screen.dart      # System Settings (announcer, music, users, admin)
│       ├── test_dartboard_screen.dart   # Dartboard emulator (admin tool)
│       └── games/
│           └── carnival_horse_race/ # Carnival Derby game
│               ├── horse_race_menu_screen.dart     # Game setup
│               ├── horse_race_game_screen.dart     # Active gameplay
│               └── horse_race_results_screen.dart  # Winner announcement
├── test/                            # Non-UI test suite (226 tests)
├── integration_test/                # UI automation tests (76 tests)
└── assets/                          # Images, icons, fonts
```

### Key Shared Systems

**1. Dartboard Connection (`DartboardProvider`)**
- Manages connection to physical Scolia dartboard via API
- Provides emulator mode for testing without hardware
- Status tracking (connected, disconnected, connecting)
- Used by all games for dart input

**2. User Management (`PlayerProvider`)**
- Global player list shared across all games
- Player profiles with photos and statistics
- Game history tracking with duration
- Stats aggregation (total wins, play time, average duration)

**3. Announcer System (`DartAnnouncerService`)**
- Voice announcements for game events
- Supports multiple voice engines (Browser Voices, ResponsiveVoice)
- Customizable personality (Professional, Excited, Calm, Funny, Drill Sergeant)
- Used by all games for consistent audio feedback

**4. Victory Music (`VictoryMusicService`)**
- Custom music file management
- Random selection from user's music library
- Plays when a player wins any game
- Cross-platform support (web data URLs, native file paths)

**5. Game Announcement Queue (`GameAnnouncementQueueService`)**
- Global priority-based announcement queue used by ALL games
- Manages voice announcements with optional sound effects
- Prevents announcement overlap with intelligent queuing
- Priority levels: turnTransition(1), hitConfirm(2), shieldStatus(3), statusChange(4), victory(5)
- Each game creates a helper that wraps this service with game-specific convenience methods
- Sound effects play simultaneously with announcements
- Uses the global `DartAnnouncerService` for voice output

**6. In-Game Dartboard Emulator Components (`lib/widgets/dartboard_emulator/`)**
- **Purpose**: Allows offline development and testing when a physical Scolia dartboard is NOT connected
- **When shown**: ONLY when `!dartboardProvider.isConnected` (emulator mode)
- **When hidden**: Automatically hidden when connected to a real Scolia dartboard
- Shared, reusable dartboard emulator UI components for all games
- Ensures consistent dartboard behavior across games while allowing game-specific styling
- **DartboardEmulatorController** - Manages show/hide state (ChangeNotifier pattern)
- **DartboardEmulatorSection** - Renders dartboard container with disabled overlay
- **DartboardEmulatorFAB** - Floating action button for show/hide toggle (only visible in emulator mode)
- **Configuration classes** - Game-specific styling via factory methods
  - `DartboardSectionConfig.carnivalDerby()` - Carnival Derby styling
  - `DartboardSectionConfig.targetTag()` - Target Tag styling
  - `DartboardFABConfig.carnivalDerby()` - Carnival Derby FAB styling
  - `DartboardFABConfig.targetTag()` - Target Tag FAB styling
- All games use identical dartboard logic from `InteractiveDartboard` widget
- See "Dartboard Emulator Component Integration" section for implementation guide

**7. Add Player Dialog Component (`lib/widgets/add_player/`)**
- **Purpose**: Shared modal for adding new players across all games and System Settings
- Ensures consistent player creation logic while allowing screen-specific styling
- **AddPlayerDialog** - Function that shows dialog and returns `Player?` or `null`
- **AddPlayerDialogConfig** - Configuration class for styling (colors, fonts, buttons)
- **Factory methods** - Pre-configured styling for each game/screen
  - `AddPlayerDialogConfig.carnivalDerby()` - Carnival theme (red/yellow/teal, Montserrat/Bangers fonts)
  - `AddPlayerDialogConfig.targetTag()` - Tech/neon theme (pink/green, Fredoka font)
  - `AddPlayerDialogConfig.optionsScreen(context)` - Material Design defaults
- Features:
  - Photo upload via camera or gallery (using PhotoService)
  - Name validation (empty check)
  - Photo preview with remove button
  - Returns Player object if created, null if cancelled
- Caller handles: `PlayerProvider.savePlayer()`, auto-selection, success feedback, scroll behavior
- Eliminates ~750 lines of duplicated code across 3 locations
- See "Add Player Dialog Integration" section for implementation guide

### Design System

**Dart Games Container App Design:**

The design system below applies to the core dart games app screens (splash, home, dartboard setup, system settings, emulator). These screens provide a consistent container experience.

**Theme & Colors:**
- Primary: Flame Orange (#FF6B35)
- Secondary: Tangerine Orange (#F7931E)
- Tertiary: Deep Ocean Blue (#004E89)
- Gradient AppBars: Red (#F44336) to Amber (#FFC107)

**Typography:**
- Font Family: Nunito (Google Fonts)
- Hero Headers: Black (900 weight), 32-40pt, negative letter spacing
- Screen Titles: Bold (700 weight), 24-28pt
- Live Scores: Semi-Bold (600 weight), 28pt+, tabular figures
- Body Text: Regular (400 weight), 16pt, 1.4x line height

**Individual Game Designs:**

Each game can and should have its own unique visual identity to create a distinct experience:
- **Custom color palettes** - Games can use any colors that fit their theme
- **Custom typography** - Games can use different fonts and text styles
- **Unique UI elements** - Games can have custom widgets, animations, and layouts
- **Theme consistency** - Games should maintain their own internal design consistency

**Example: Carnival Derby**
- Uses yellow/amber carnival theme colors
- Has carnival-specific visual elements
- Maintains distinct identity while integrating with shared systems (announcer, victory music, user management)

### Adding New Games

When adding a new game to the dart games app:

1. **Create game screens** in `lib/screens/games/[game_name]/`
2. **Design unique visual identity** - Each game should have its own color palette, typography, and theme to feel distinct
3. **Integrate with global systems** (see Game Integration Requirements section)
4. **Use shared services:**
   - `DartboardProvider` - Dartboard connection and events
   - `PlayerProvider` - Global user management
   - `GameAnnouncementQueueService` - Voice announcements with sound effects (see Announcement System Integration below)
   - `VictoryMusicService` - Victory music playback
5. **Organize game assets** following the asset structure pattern (see Asset Organization below)
6. **Add game card** to `home_screen.dart` for navigation
7. **Create tests** following existing patterns
8. **Update CLAUDE.md** with new test counts and game-specific notes

#### Asset Organization

**ALL game assets (images, sounds, icons) MUST be organized in game-specific folders.**

This prevents file name conflicts between games and creates a clear separation of concerns.

**Asset Structure:**
```
assets/
├── common/                          # Shared assets used across all games
│   ├── icons/
│   │   └── icon.png                # App icon
│   └── images/
│       ├── logo.png                # Dart Games logo
│       └── connect_dartboard_icon.png
│
└── games/
    ├── carnival_derby/             # Carnival Derby game assets
    │   ├── icons/
    │   │   ├── horse.png
    │   │   ├── track.png
    │   │   └── finish_line.png
    │   ├── images/
    │   │   └── CarnivalDerby-WoodPlanks.jpg
    │   └── sounds/
    │       ├── CarnivalDerby-HorseRace-Start.mp3
    │       └── CarnivalDerby-Horse-Gallop.mp3
    │
    ├── target_tag/                 # Target Tag game assets
    │   ├── icons/
    │   │   ├── TargetTag-Icon.png
    │   │   └── TargetTag-TeamIcon-01.png through TargetTag-TeamIcon-10.png
    │   └── sounds/
    │       └── (15 sound effect files)
    │
    └── your_game/                  # ← New game assets go here
        ├── icons/
        ├── images/
        └── sounds/
```

**When adding a new game:**

1. **Create game-specific asset folders:**
   ```bash
   mkdir -p assets/games/your_game/icons
   mkdir -p assets/games/your_game/images
   mkdir -p assets/games/your_game/sounds
   ```

2. **Place ALL game assets in the game folder:**
   - Game-specific icons → `assets/games/your_game/icons/`
   - Game-specific images → `assets/games/your_game/images/`
   - Game-specific sounds → `assets/games/your_game/sounds/`
   - DO NOT mix game assets with other games' folders
   - DO NOT place game-specific assets in `assets/common/`

3. **Update pubspec.yaml with directory declaration:**
   ```yaml
   assets:
     # Shared/common assets
     - assets/common/icons/
     - assets/common/images/

     # Game-specific assets
     - assets/games/carnival_derby/
     - assets/games/target_tag/
     - assets/games/your_game/        # ← Add your game folder
   ```

4. **Reference assets using full paths in code:**
   ```dart
   // Game icon
   Image.asset('assets/games/your_game/icons/your_icon.png')

   // Background image
   AssetImage('assets/games/your_game/images/background.jpg')

   // Sound effects (in sound effects service)
   static const String _basePath = 'assets/games/your_game/sounds/';
   static const SoundEffectConfig yourSound = SoundEffectConfig(
     assetPath: '${_basePath}YourSound.mp3',
     startSeconds: 0.0,
     endSeconds: null,
   );
   ```

**Benefits:**
- No file name conflicts between games
- Clear ownership of assets
- Easy to add/remove entire games
- Consistent with code organization (`lib/screens/games/`, `lib/widgets/`)
- Simplified pubspec.yaml (directory-based vs individual file entries)

**Reference Implementations:**
- Carnival Derby: `assets/games/carnival_derby/` (6 assets: 3 icons, 1 image, 2 sounds)
- Target Tag: `assets/games/target_tag/` (26 assets: 11 icons, 15 sounds)

#### Announcement System Integration

**ALL games MUST use the global `GameAnnouncementQueueService` for announcements.**

Follow this pattern when adding a new game:

1. **Create a game-specific announcement helper** in `lib/services/[game_name]_announcement_helper.dart`:
```dart
import 'game_announcement_queue_service.dart';
import '[game_name]_sound_effects.dart'; // Optional, for sound effects

class YourGameAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  YourGameAnnouncementHelper(this._queue);

  // Add game-specific convenience methods
  void announcePlayerTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: YourGameSoundEffects.turnStart, // Optional
    );
  }

  void dispose() {
    _queue.dispose();
  }
}
```

2. **In your game screen, initialize the helper**:
```dart
class YourGameScreen extends StatefulWidget {
  // ...
}

class _YourGameScreenState extends State<YourGameScreen> {
  YourGameAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize global queue with game-specific helper
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = YourGameAnnouncementHelper(globalQueue);
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

3. **Use the helper throughout your game**:
```dart
_audioQueue?.announcePlayerTurn(player.name);
```

**Reference implementations:**
- Target Tag: `lib/services/target_tag_announcement_helper.dart`
- Carnival Derby: `lib/services/carnival_derby_announcement_helper.dart`

#### Dartboard Emulator Component Integration

**ALL games MUST use the shared dartboard emulator components.**

**IMPORTANT: The in-game dartboard emulator is ONLY for offline development and testing.**
- The dartboard emulator appears when you cannot connect to a physical Scolia dartboard
- It allows testing game logic without physical hardware
- It is automatically hidden when connected to a real dartboard (`dartboardProvider.isConnected`)
- The FAB button only appears in emulator mode to allow hiding/showing the on-screen dartboard

The dartboard emulator components provide a consistent UI and behavior across all games while allowing each game to customize the visual styling (colors, fonts, borders).

**Integration Pattern:**

1. **Import the dartboard emulator package**:
```dart
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
```

2. **In your game screen state, create a controller and dartboard key**:
```dart
class _YourGameScreenState extends State<YourGameScreen> {
  final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;

  @override
  void dispose() {
    _dartboardEmulatorController.dispose();
    // ... other dispose calls
    super.dispose();
  }
}
```

3. **Add the FAB (Floating Action Button) to your Scaffold**:
```dart
Scaffold(
  // ... appBar, body, etc.
  floatingActionButton: DartboardEmulatorFAB(
    controller: _dartboardEmulatorController,
    isConnected: dartboardProvider.isConnected,
    config: DartboardFABConfig.yourGame(), // Create factory for your game
  ),
)
```

4. **Add the dartboard section to your game UI**:
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: dartboardProvider.isConnected,
  shouldPromptTakeout: shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: (score, multiplier, baseScore, position) {
    if (_mockApi != null) {
      _mockApi!.simulateDartThrow(
        score: score,
        multiplier: multiplier,
        playerName: 'Player',
        baseScore: baseScore,
        widgetX: position.dx,
        widgetY: position.dy,
        widgetSize: 250,
      );
    }
  },
  onRemoveDarts: () {
    _mockApi?.simulateTakeoutFinished();
    _dartboardKey.currentState?.removeDarts();
  },
  config: DartboardSectionConfig.yourGame(), // Create factory for your game
),
```

5. **Create configuration factory methods for your game** in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`:
```dart
// Add to DartboardSectionConfig class
factory DartboardSectionConfig.yourGame() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    borderRadius: BorderRadius.circular(12), // Optional
    disabledOverlayBackgroundColor: const Color(0xYOURCOLOR).withOpacity(0.9),
    disabledOverlayBorderColor: const Color(0xYOURBORDER),
    removeButtonBackgroundColor: const Color(0xYOURBUTTON),
    removeButtonBorderColor: const Color(0xYOURBORDER),
    removeButtonTextStyle: GoogleFonts.yourFont(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}

// Add to DartboardFABConfig class
factory DartboardFABConfig.yourGame() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    iconColor: Colors.white,
    textColor: Colors.white,
    textStyle: GoogleFonts.yourFont(fontWeight: FontWeight.bold),
  );
}
```

**Benefits:**
- ~200 lines of code eliminated per game
- Consistent dartboard behavior across all games
- Bug fixes in shared component benefit all games
- Game-specific visual identity maintained through configuration
- Future games only need config objects

**Reference Implementations:**
- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`
- Target Tag: `lib/screens/games/target_tag/target_tag_game_screen.dart`
- Component source: `lib/widgets/dartboard_emulator/`

## Critical Rules

### Dartboard Emulator Code Protection

**NEVER update the dartboard emulator code without explicit permission from the user.**

The dartboard emulator (`lib/widgets/interactive_dartboard.dart`) is working correctly and has been thoroughly tested. Any changes to this component must be explicitly requested and approved by the user before implementation.

Files that require explicit permission before modification:
- `lib/widgets/interactive_dartboard.dart` - Interactive dartboard widget
- Segment calculation logic
- Ring boundary detection
- Coordinate mapping and scaling

If a bug is suspected in the dartboard emulator, ask the user to verify the issue before making changes.

### Dartboard Emulator Integration in Games

**When integrating InteractiveDartboard widget into game screens, follow this exact structure pattern:**

The dartboard emulator must be structured correctly to ensure clickable areas align with visual elements. Based on successful implementations in Carnival Derby and Target Tag, use this pattern:

```dart
Widget _buildDartboardSection(bool disabled) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: YourGameBackgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,  // CRITICAL: Centers dartboard and modal
      children: [
        // Dartboard with optional disable state
        AbsorbPointer(
          absorbing: disabled,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: InteractiveDartboard(
              key: _dartboardKey,
              size: 250,  // MUST match widgetSize parameter
              onDartThrow: (score, multiplier, baseScore, position) {
                if (_mockApi != null) {
                  _mockApi!.simulateDartThrow(
                    score: score,
                    multiplier: multiplier,
                    playerName: 'Player',
                    baseScore: baseScore,
                    widgetX: position.dx,
                    widgetY: position.dy,
                    widgetSize: 250,  // MUST match size parameter
                  );
                }
              },
              onRemoveDarts: () {
                // Called when dartboard is cleared
              },
            ),
          ),
        ),
        // Modal overlay (if needed)
        if (disabled)
          Container(
            width: 250,  // MUST match dartboard size
            height: 250,
            decoration: BoxDecoration(
              color: YourGameColor.withOpacity(0.9),
              shape: BoxShape.circle,  // Circular overlay
              border: Border.all(
                color: YourGameBorderColor,
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your modal content here
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
```

**Critical Requirements:**

1. **Stack Alignment** - MUST use `alignment: Alignment.center` on Stack
   - Without this, clickable areas will NOT align with visual dartboard
   - Symptoms: Clicks register wrong segments (e.g., clicking 20 registers as 5)

2. **Direct Stack Children** - Dartboard and modal are direct children of Stack
   - NO Positioned wrappers
   - NO nested Container/SizedBox wrappers
   - This ensures proper coordinate mapping

3. **Consistent Sizing** - All sizes MUST match exactly:
   - InteractiveDartboard `size` parameter
   - simulateDartThrow `widgetSize` parameter
   - Modal overlay width/height
   - All should be 250 (or same value if different)

4. **Simplified Structure** - Avoid over-nesting:
   - Container (padding + decoration) → Stack → Children
   - NO extra layers between Stack and dartboard
   - NO SizedBox wrappers that change dimensions

5. **Modal Shape** - If using circular modal overlay:
   - Use `BoxShape.circle` decoration
   - Match dartboard dimensions exactly (250x250)
   - Center content with Column + MainAxisAlignment.center

**Reference Implementations:**
- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart` (lines 647-760)
- Target Tag: `lib/screens/games/target_tag/target_tag_game_screen.dart` (dartboard section)

**Common Mistakes to Avoid:**
- ❌ Wrapping Stack in SizedBox with different dimensions
- ❌ Using Positioned.fill for modal (breaks alignment)
- ❌ Forgetting `alignment: Alignment.center` on Stack
- ❌ Mismatched size values between dartboard and widgetSize
- ❌ Over-nesting with multiple Containers

#### Add Player Dialog Integration

**ALL games and System Settings MUST use the shared Add Player dialog component.**

The Add Player dialog provides consistent player creation logic across all games and screens while allowing each to customize the visual styling (colors, fonts, buttons).

**Integration Pattern:**

1. **Import the Add Player package**:
```dart
import '../../../widgets/add_player/add_player.dart';
```

2. **Create a handler method in your screen**:
```dart
void _handleAddPlayer() async {
  final player = await showAddPlayerDialog(
    context: context,
    config: AddPlayerDialogConfig.yourGame(), // Use appropriate factory
  );

  if (player != null && mounted) {
    final playerProvider = context.read<PlayerProvider>();
    await playerProvider.savePlayer(player);

    // Optional: Auto-select player (games only, not System Settings)
    if (playerProvider.selectedPlayers.length < maxPlayers) {
      playerProvider.selectPlayer(player, maxPlayers: maxPlayers);
    }

    // Optional: Show success feedback (System Settings only)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Player "${player.name}" added'),
        backgroundColor: Colors.green,
      ),
    );

    // Optional: Scroll to show new player
    _scrollToNewPlayer();
  }
}
```

3. **Call the handler from your Add Player button**:
```dart
ElevatedButton(
  onPressed: _handleAddPlayer,
  child: Text('Add Player'),
)
```

**Configuration Factory Methods:**

Create game-specific factory methods in `lib/widgets/add_player/add_player_dialog_config.dart`:

```dart
factory AddPlayerDialogConfig.yourGame() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xYOURCOLOR).withOpacity(0.95),
    textColor: Colors.white,
    titleStyle: GoogleFonts.yourFont(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    inputLabelStyle: GoogleFonts.yourFont(
      fontSize: 14,
      color: Colors.white70,
    ),
    inputBorderColor: const Color(0xYOURBORDER),
    inputFocusedBorderColor: const Color(0xYOURACCENT),
    inputErrorBorderColor: Colors.red,
    photoLabelStyle: GoogleFonts.yourFont(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    photoButtonColor: const Color(0xYOURBUTTON),
    photoButtonForegroundColor: Colors.white,
    photoButtonBorderColor: const Color(0xYOURBORDER),
    photoButtonTextStyle: GoogleFonts.yourFont(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    photoButtonWidth: 130.0, // Fixed width, or null for Expanded
    addButtonColor: const Color(0xYOURPRIMARY),
    addButtonForegroundColor: Colors.white,
    addButtonBorderColor: const Color(0xYOURPRIMARY),
    addButtonTextStyle: GoogleFonts.yourFont(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    cancelButtonColor: const Color(0xYOURSECONDARY),
    cancelButtonForegroundColor: Colors.white,
    cancelButtonBorderColor: const Color(0xYOURBORDER),
    cancelButtonTextStyle: GoogleFonts.yourFont(
      fontSize: 16,
    ),
    errorTextColor: Colors.red,
  );
}
```

**Usage Examples:**

**Carnival Derby (with auto-selection):**
```dart
void _handleAddPlayer() async {
  final player = await showAddPlayerDialog(
    context: context,
    config: AddPlayerDialogConfig.carnivalDerby(),
  );

  if (player != null && mounted) {
    final playerProvider = context.read<PlayerProvider>();
    await playerProvider.savePlayer(player);

    // Auto-select if room available
    if (playerProvider.selectedPlayers.length < 8) {
      playerProvider.selectPlayer(player, maxPlayers: 8);
    }

    _scrollToNewPlayer();
  }
}
```

**Target Tag (with auto-selection):**
```dart
void _handleAddPlayer() async {
  final player = await showAddPlayerDialog(
    context: context,
    config: AddPlayerDialogConfig.targetTag(),
  );

  if (player != null && mounted) {
    final playerProvider = context.read<PlayerProvider>();
    await playerProvider.savePlayer(player);

    // Auto-select if room available
    if (playerProvider.selectedPlayers.length < 10) {
      playerProvider.selectPlayer(player, maxPlayers: 10);
    }

    _scrollToNewPlayer();
  }
}
```

**System Settings (with snackbar, no auto-selection):**
```dart
void _handleAddPlayer() async {
  final player = await showAddPlayerDialog(
    context: context,
    config: AddPlayerDialogConfig.optionsScreen(context),
  );

  if (player != null && mounted) {
    final playerProvider = context.read<PlayerProvider>();
    await playerProvider.savePlayer(player);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Player "${player.name}" added'),
        backgroundColor: Colors.green,
      ),
    );

    _scrollToNewPlayer();
  }
}
```

**Benefits:**
- ~750 lines of duplicated code eliminated across 3 locations
- Consistent player creation and validation logic
- Game-specific visual identity maintained through configuration
- Centralized photo upload functionality
- Bug fixes in shared component benefit all games and screens
- Future games only need config objects

**Reference Implementations:**
- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart`
- Target Tag: `lib/screens/games/target_tag/target_tag_menu_screen.dart`
- System Settings: `lib/screens/options_screen.dart`
- Component source: `lib/widgets/add_player/`

### Mandatory Testing Before Any Build

**ALL NON-UI TESTS MUST PASS BEFORE ANY BUILD OR DEPLOYMENT.**

Before any build, commit, or deployment:

```bash
cd dart_games
flutter test
```

**CRITICAL REQUIREMENTS:**
- All 226 non-UI tests must pass (100% pass rate required)
- If ANY test fails, DO NOT proceed with build
- Fix all failing tests first, then re-run test suite
- Only build after confirming all tests pass

**UI Automation Tests (Optional):**

The 76 UI automation tests in `integration_test/` take longer to run (~43 minutes) and require chromedriver.

**Before running a build, ASK the user:**
- "Would you like me to run the UI automation tests before this build?"

**If the user says yes:**
```bash
# Terminal 1 - Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2 - Run UI tests (76 tests across 6 files, ~43 minutes total)
cd dart_games
# Target Tag tests (52 tests, ~31.5 minutes)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_menu_and_mechanics_test.dart \
  -d chrome
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_visual_validation_test.dart \
  -d chrome
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_gameplay_test.dart \
  -d chrome
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_add_player_test.dart \
  -d chrome
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_results_screen_test.dart \
  -d chrome
# Carnival Derby tests (24 tests, ~12 minutes)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/carnival_derby_ui_test.dart \
  -d chrome
```

**If the user says no:**
- Proceed with build after non-UI tests pass
- UI automation tests are supplementary and not required for every build

**Target Tag Regression Testing:**

ALL 41 Target Tag tests MUST pass before any build to prevent regressions:

```bash
flutter test test/screens/games/target_tag/
```

These tests validate:
- **Game logic AND announcements** (32 tests in `target_tag_game_with_announcements_test.dart`)
  - Solo mode (Tests 1-8): Shield building, tagged-in status, successful tags, low shields, losing tagged-in, victory
  - Team mode (Tests 9-14): Team setup, team tagged-in, team elimination, last team standing
  - Hero bonus (Tests 15-17): Fill to max, attacks while tagged-in, team hero attacks
  - Turn management (Tests 18-19): Skip turns, multiple skips in sequence
  - Edit score (Tests 20-24): Add/remove shields, undo, team adjustments
  - Edge cases (Tests 25-32): Simultaneous events, regaining tagged-in, all bullseyes, 10 players, 5 teams, multiple hero attacks
- **User management integration** (10 tests in `target_tag_user_management_test.dart`)
  - Win tracking for both winners and losers with game duration
  - Stats persistence across app restarts
  - Total play time and average duration calculations
  - Max 10 players selection enforcement

This is NON-NEGOTIABLE. Tests validate critical functionality including:
- User management system (43 tests - Player: 30, Carnival Derby: 11, Target Tag: 10)
- Victory music management (22 tests)
- Announcer settings (20 tests)
- Dartboard emulator accuracy (23 tests)
- Target Tag game logic, announcements, and user management (42 tests)
- Carnival Derby game logic, announcements, and user management (33 tests)
- Data persistence and serialization
- Cross-platform compatibility
- Game logic and scoring

### Handling Test Failures

**NEVER automatically update tests to make them pass without user approval.**

When tests fail after making code changes:

1. **STOP and analyze the failure**
   - Read the test failure messages carefully
   - Understand what functionality the test is validating
   - Determine if the test is catching a bug in the new code OR if the test is outdated

2. **Ask the user for direction**
   - Present the test failure details to the user
   - Ask: "The tests are failing. Would you like me to:
     - (A) Fix the application code to make the existing tests pass, OR
     - (B) Update the tests to match the new application behavior?"
   - Wait for explicit user choice before proceeding

3. **IMPORTANT: Do not assume tests need updating**
   - Tests often catch real bugs introduced by code changes
   - Automatically updating tests to pass could hide bugs in the application
   - The user knows the intended behavior - let them decide

4. **After user decision**
   - If (A): Fix the application code while preserving test requirements
   - If (B): Update tests AND update CLAUDE.md with new test count/descriptions
   - Re-run `flutter test` to verify 100% pass rate
   - Only then proceed with build/commit

**Example Workflow:**

```
Scenario: After updating player management, 3 tests fail

❌ WRONG approach:
- Automatically modify tests to pass
- Proceed with build

✅ CORRECT approach:
- Analyze the 3 failing tests
- Present to user: "Tests are failing because the new code changes how player names are validated.
  Would you like me to:
  (A) Revert the validation changes to match the test expectations, OR
  (B) Update the tests to accept the new validation logic?"
- Wait for user choice
- Implement the chosen solution
- Re-run tests to verify all pass
```

### Cross-Platform Compatibility

**All features must work on both web and tablet devices (iOS and Android).**

When implementing new features or modifying existing code:
- Ensure compatibility with web browsers (Chrome, Safari, Firefox, Edge)
- Ensure compatibility with iOS tablets (iPad)
- Ensure compatibility with Android tablets
- Use platform-specific code only when necessary, with proper conditional imports
- Test platform-specific features (like file picking, audio playback, storage) on all target platforms
- Use `kIsWeb` checks when web and native platforms require different implementations
- Avoid web-only APIs (like `dart:html`, `dart:js`) in shared code without conditional imports
- Avoid mobile-only APIs in web builds

Common cross-platform considerations:
- File storage: Use IndexedDB for web, file system for native
- Audio playback: Ensure audio formats are supported across all platforms
- File picking: Different APIs for web vs native
- Responsive layouts: Test on different screen sizes and orientations
- Touch vs mouse input: Both should work seamlessly

### Game Integration Requirements

**ALL games in the dart games app MUST integrate with the global systems.**

Every game (such as Target Tag, Carnival Derby, and any future games) must follow these integration requirements:

**IMPORTANT - Game Duration Tracking:**
- **ALL games MUST track game duration for BOTH winners AND losers**
- This is the current standard pattern (implemented in Target Tag and Carnival Derby)
- When implementing new games, follow this pattern shown below

#### 1. Global User Management
- **Use the global user list** (`PlayerProvider`) for available players
- **Add new players to the global list** - when a player is created in any game, they are added to the shared player list
- Players created in one game are immediately available in all other games
- Use `PlayerProvider.savePlayer()` to add new players
- Use `PlayerProvider.allPlayers` to get the list of available players

#### 2. Announcer Integration
- **Use the global `GameAnnouncementQueueService` for ALL announcements**
- **DO NOT use `DartAnnouncerService` directly** - the queue service manages it automatically
- Create a game-specific announcement helper that wraps the global queue service
- The queue service automatically respects user's announcer settings:
  - Voice engine selection (Browser Voices or ResponsiveVoice)
  - Announcer personality (Professional, Excited, Calm, Funny, Drill Sergeant)
  - Voice enabled/disabled setting
- See the "Announcement System Integration" section above for complete implementation guide
- **Reference implementations:**
  - Target Tag: `lib/services/target_tag_announcement_helper.dart`
  - Carnival Derby: `lib/services/carnival_derby_announcement_helper.dart`

#### 3. User Win Tracking and Game Duration
- **Track user wins and game duration for ALL players**
- **CRITICAL**: ALL players (both winners AND losers) MUST receive game duration tracking
- Call `PlayerProvider.updatePlayerStats()` for EVERY player in the game:
  - **For winners:**
    - `playerId` - the ID of the winning player
    - `won: true` - to increment games won
    - `gameName` - the name of the game (e.g., "Target Tag", "Carnival Derby")
    - `gameDuration` - the full game duration from start to finish
  - **For losers:**
    - `playerId` - the ID of the losing player
    - `won: false` - increments games played only
    - `gameName` - the name of the game
    - `gameDuration` - the SAME full game duration as winners
- **Important**: Both winners and losers receive identical `gameDuration` values representing the complete game time
- This enables accurate play time tracking and statistics for all participants

#### 4. Game Timer
- **Every game MUST implement a game timer**
- Track the start time when the game begins (e.g., when "Start Game" button is pressed)
- Track the end time when the game completes (winner determined)
- Calculate duration: `DateTime.now().difference(startTime)`
- Pass the duration to `updatePlayerStats()` for win tracking

#### 5. Victory Music
- **Use the dart games victory music list for victory music**
- Use `VictoryMusicService` singleton to access custom victory music
- Call `VictoryMusicService.getRandomMusicSource()` to get a random music file
- If custom music is available (`hasCustomMusic()` returns true), play it
- Handle both web (data URLs) and native (file paths) music sources
- Provide fallback behavior if no custom music is configured

#### Implementation Example (Target Tag Pattern - REQUIRED for all new games)

```dart
class GameScreen extends StatefulWidget {
  // Game provider with timer
  final GameProvider gameProvider;
  final PlayerProvider playerProvider = PlayerProvider();
  final VictoryMusicService musicService = VictoryMusicService();

  // Announcement helper
  YourGameAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize global announcement queue with game-specific helper
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = YourGameAnnouncementHelper(globalQueue);
    });
  }

  void _startGame() {
    // Start game with timer
    gameProvider.startGame(selectedPlayers, targetScore);
    // gameProvider.currentGame.startedAt is set to DateTime.now()

    // Announce game start
    _audioQueue?.announceGameStart();
  }

  void _onGameComplete() async {
    final game = gameProvider.currentGame!;
    final gameDuration = DateTime.now().difference(game.startedAt);

    // Get list of winners (may be multiple in team games)
    final winners = gameProvider.getWinners(playerProvider.allPlayers);
    final winnerIds = winners.map((p) => p.id).toSet();

    // CRITICAL: Update stats for ALL players (winners AND losers)
    // ALL players receive the same game duration
    for (final playerId in game.playerIds) {
      final isWinner = winnerIds.contains(playerId);
      await playerProvider.updatePlayerStats(
        playerId,
        won: isWinner,
        gameName: 'Your Game Name',
        gameDuration: gameDuration,  // ← SAME duration for winners AND losers
      );
    }

    // Announce game complete and winner
    _audioQueue?.announceGameComplete();
    if (winners.isNotEmpty) {
      _audioQueue?.announceWinner(winners.first.name);
    }

    // Play victory music
    if (await musicService.hasCustomMusic()) {
      final musicSource = await musicService.getRandomMusicSource();
      if (musicSource != null) {
        // Play music using appropriate player for web/native
      }
    }
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

#### Required Dependencies

Games must import and use:
- `package:dart_games/providers/player_provider.dart` - Global user management
- `package:dart_games/services/game_announcement_queue_service.dart` - Global announcement queue
- `package:dart_games/services/victory_music_service.dart` - Victory music
- `package:dart_games/services/app_settings.dart` - Settings persistence (used internally by queue service)

**NOTE:** Do NOT import `dart_announcer_service.dart` directly - the `GameAnnouncementQueueService` manages it internally.

#### Testing Requirements

When adding a new game:
1. Create integration tests that verify global system integration
2. Test that players added in the game appear in the global player list
3. **Test that ALL players (winners AND losers) receive game duration tracking**
4. Test that winners have `gamesWon` incremented correctly
5. Test that losers have `gamesPlayed` incremented but `gamesWon` unchanged
6. Test that game timer calculates duration correctly
7. Test that all players in the same game receive identical duration values
8. Test that stats persist across app restarts (SharedPreferences)
9. Follow the pattern established in `test/screens/games/target_tag/target_tag_user_management_test.dart`

**Reference Implementation:**
- See `target_tag_user_management_test.dart` for the complete pattern (10 tests)
- Tests validate both solo and team modes
- Tests verify that losers receive game history with duration (not just winners)

## Testing Requirements

### Complete Test Suite (226 Tests + 76 UI Automation Tests)

The dart games app has a comprehensive test suite covering all critical functionality:

**Non-UI Tests (226 tests in `test/` directory):**
- Run with `flutter test`
- Execute in seconds
- Required to pass before every build

**UI Automation Tests (76 tests in `integration_test/` directory):**
- Run with `flutter drive` and chromedriver
- Execute in ~43 minutes
- Optional for builds (ask user before running)

#### Model Tests (36 tests)
- `test/models/game_history_entry_test.dart` (8 tests)
  - Factory constructor creation
  - JSON serialization/deserialization
  - Round-trip serialization
  - Duration format handling
  - Timestamp validation

- `test/models/player_test.dart` (16 tests)
  - Player creation with/without photos
  - Game history serialization
  - Backward compatibility (missing gameHistory field)
  - copyWith() functionality
  - Equality operators and hashCode

- `test/models/victory_music_file_test.dart` (12 tests)
  - Instance creation and field validation
  - JSON serialization/deserialization
  - Round-trip serialization
  - File extensions and formats (mp3, wav, ogg, etc.)
  - Data URL sources (web) and file paths (native)
  - Special characters and long file names

#### Provider Tests (37 tests)
- `test/providers/player_provider_test.dart` (37 tests)
  - Player CRUD operations (save, update, delete)
  - Player selection (up to 8 players)
  - Game stats tracking (games played/won)
  - Game history methods (getPlayerHistory, getPlayerHistoryForGame, etc.)
  - Total play time and average duration calculations
  - Data persistence across provider instances
  - Alphabetical sorting (7 tests):
    - Sorts players alphabetically on load (case-insensitive)
    - New players appear at bottom during session
    - markPlayersSorted() updates timestamp
    - Returning to screen sorts all players
    - Handles empty lists and single players

#### Service Tests (42 tests)
- `test/services/app_settings_test.dart` (20 tests)
  - Google API key storage and retrieval
  - Voice engine preference management
  - Google voice selection
  - Voice enabled state
  - Settings persistence and isolation

- `test/services/victory_music_service_test.dart` (22 tests)
  - Singleton pattern
  - Music file management
  - Random music selection
  - Backward compatibility (deprecated methods)
  - Error handling and data persistence
  - Cross-platform file handling

#### Integration Tests (75 tests)
- `test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart` (22 tests)
  - Winner recording with game duration
  - Multiple games accumulation
  - Duration calculation accuracy
  - Multi-player game stats (both winners and losers receive duration)
  - Exact score mode duration tracking
  - Stats persistence across app restarts
  - Max 8 players selection enforcement
  - Skip turn records misses and advances turn
  - Skip multiple turns in sequence
  - Edit score on first turn preserves score correctly
  - Edit score preserves inner vs outer single distinction
  - Edit score increases player total score
  - Edit score decreases player total score
  - Edit score to add misses
  - Edit score to remove misses
  - Edit score with bulls (bullseye and outer bull)
  - Edit score maintains waiting for takeout state
  - Edit score does not affect other players
  - Edit score in exact mode handles bust correctly
  - Edit score can trigger win in exact mode

- `test/screens/games/carnival_horse_race/carnival_derby_game_with_announcements_test.dart` (11 tests)
  - Normal mode game logic and announcements (Tests 1-4)
  - Perfect Finish mode with busts and exact wins (Tests 5-10)
  - Results screen announcements (Test 11)
  - Validates BOTH game logic (scoring, busts, wins) AND announcement text with sound effects
  - Covers all dart types: single, double, triple, bullseye, outer bull, miss
  - Tests skip turn functionality with announcements
  - Tests bust behavior (score preservation) in exact score mode
  - Tests progressive scoring and close calls
  - Covers 1-3 players in various scenarios

- `test/screens/games/target_tag/target_tag_game_with_announcements_test.dart` (32 tests)
  - Solo mode game logic and announcements (Tests 1-8)
  - Team mode mechanics and announcements (Tests 9-14)
  - Hero bonus behavior and announcements (Tests 15-17)
  - Turn management and announcements (Tests 18-19)
  - Edit score functionality (Tests 20-24)
  - Edge cases and complex scenarios (Tests 25-32)
  - Validates BOTH game logic (shields, tagged-in status, eliminations) AND announcement text/timing
  - Covers 2-10 players and 2-5 teams

- `test/screens/games/target_tag/target_tag_user_management_test.dart` (10 tests)
  - Solo mode winner/loser stats with duration tracking (Tests 4-7)
  - Team mode stats for all players with duration (Test 8)
  - Mixed team compositions across games (Test 9)
  - 3-team game statistics (Test 10)
  - Total play time calculations (Test 11)
  - Average game duration by game name (Test 12)
  - Max 10 players selection enforcement (Test 13)
  - Both winners AND losers receive game history entries with duration
  - Stats persistence and data integrity validation

#### Widget Tests (23 tests)
- `test/widgets/interactive_dartboard_test.dart` (23 tests)
  - Dartboard rendering and scaling
  - Bulls detection (50 and 25 points)
  - Ring detection (double, triple, single)
  - Segment scoring accuracy across the board
  - Dart position persistence across window resize
  - Dart management (add/remove functionality)

#### UI Automation Tests (76 tests)
- `integration_test/target_tag_menu_and_mechanics_test.dart` (23 tests)
  - Player selection and auto-selection (1 test)
  - Menu settings and validations (6 tests)
  - Team mode - max 5 teams (3 tests)
  - Add player button states (2 tests)
  - Hero bonus toggle (1 test)
  - Edit score behavior (4 tests)
  - Player tile highlighting (6 tests)
  - **Execution time:** ~12 minutes

- `integration_test/target_tag_visual_validation_test.dart` (4 tests)
  - Test 1: Current Player Shows Badge When Tagged In
  - Test 2: Tagged In + Current Player - Combined Visual
  - Test 3: Eliminated Player Visual State
  - Test 4: Team Mode - Team Tagged In Visual
  - **Execution time:** ~2 minutes

- `integration_test/target_tag_gameplay_test.dart` (13 tests)
  - Hero buff & opponent targets tests (8 tests)
  - D1/D2/D3 dart highlighting tests (2 tests)
  - Game settings panel tests (1 test)
  - Victory screen tests (2 tests)
  - **Execution time:** ~10 minutes

- `integration_test/target_tag_add_player_test.dart` (6 tests)
  - Test 1: Navigation and Initial Player Setup
  - Test 2: Add Player with Name Only
  - Test 3: Add Player Photo UI Elements
  - Test 4: Add Player Empty Name Validation
  - Test 5: Add Player Whitespace-Only Name Validation
  - Test 6: Cancel Button Functionality
  - **Execution time:** ~2 minutes

- `integration_test/target_tag_results_screen_test.dart` (6 tests)
  - Test 1: Results Screen Content - Solo Mode Victory Display
  - Test 2: Play Again - Settings Preservation Solo Mode
  - Test 3: Change Settings - Return to Menu with Preserved Settings
  - Test 4: Results Screen Content - Team Mode Victory Display
  - Test 5: Play Again - Team Mode Settings and Team Assignment Preserved
  - Test 6: Play Again - Hero Bonus Setting Preserved
  - **Execution time:** ~5.5 minutes

- `integration_test/carnival_derby_ui_test.dart` (24 tests)
  - Test 1-2: Menu - Player Selection (2 tests)
  - Test 3-4: Menu - Target Score Settings (2 tests)
  - Test 5-7: Game - Basic Race Mechanics - Normal Mode (3 tests)
  - Test 8-11: Game - Perfect Finish Mode - Bust Mechanics (4 tests)
  - Test 12-14: Game - Skip Turn Functionality (3 tests)
  - Test 15-16: Game - Edit Score Functionality (2 tests)
  - Test 17-18: Game - Multi-Player Race (2 tests)
  - Test 19-21: Edge Cases (3 tests)
  - Test 22-24: Results Screen (3 tests)
  - **Execution time:** ~12 minutes

**Total UI Automation Test Execution Time:** ~43 minutes (varies based on system performance)
**Required setup:** ChromeDriver running on port 4444
**Run separately with chromedriver:** See UI Automation Testing Guidelines section

### Running Tests

**Run all non-UI tests (226 tests):**
```bash
cd dart_games
flutter test
```

**Run specific test suites:**
```bash
# Model tests
flutter test test/models/

# Provider tests
flutter test test/providers/

# Integration tests
flutter test test/screens/games/carnival_horse_race/

# Widget tests
flutter test test/widgets/
```

**Run UI automation tests (76 tests, ~43 minutes total):**
```bash
# Terminal 1: Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run UI automation tests (6 test files)
cd dart_games
# Target Tag tests (52 tests, ~31.5 minutes)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome
# Carnival Derby tests (24 tests, ~12 minutes)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome
```

### Test Expectations

**Non-UI Tests (226 tests):**
- **100% pass rate required** - All 226 non-UI tests must pass before every build
- Tests validate user management, victory music, announcer settings, dartboard accuracy, game logic, announcements, and data persistence
- No build or deployment without all non-UI tests passing
- Tests cover both web and native platform scenarios
- Backward compatibility is validated for data migrations
- Target Tag tests (41 tests total) validate game logic, announcement system integrity, and user management integration

**UI Automation Tests (76 tests):**
- Optional for builds - ask user if they want to run UI automation tests
- Execution time: ~43 minutes
- Tests validate Target Tag and Carnival Derby menu settings, gameplay mechanics, and user interactions end-to-end in Chrome
- Target Tag (52 tests): Covers all game modes (solo, team), settings persistence, edit score, skip turn, player highlighting, hero bonuses, victory conditions, results screen functionality, and visual validation (player tiles, badges, borders, opacity, glow effects)
- Carnival Derby (24 tests): Covers player selection, target score settings, Normal/Perfect Finish modes, bust mechanics, skip turn, edit score, multi-player races, edge cases, and results screen
- Require chromedriver setup on port 4444
- When run, must achieve 100% pass rate

### Maintaining Tests When Features Change

**CRITICAL: When updating features, tests MUST be updated to match.**

Whenever you update a feature of the dart games app or modify one of the games:

1. **Ask the user if they want to update the tests** to match the new functionality
   - Example: "I've updated the player selection feature. Would you like me to update the tests to cover the new functionality?"

2. **If the user says yes:**
   - Update existing tests that are affected by the changes
   - Add new tests to cover the new functionality
   - Ensure all tests pass with the updated code
   - Run `flutter test` to verify 100% pass rate

3. **Update CLAUDE.md with the new test count and requirements:**
   - Update the "Complete Test Suite" section header with new test counts
   - Update the test breakdown in the "Complete Test Suite" section
   - Add documentation for any new test files created
   - Update the "Test Expectations" section with the new totals
   - Update "Mandatory Testing Before Any Build" section if needed

4. **Commit the test updates:**
   - Include test updates in the same commit as the feature changes, OR
   - Create a separate commit specifically for test updates
   - Update CLAUDE.md in the same commit or immediately after

**Important Notes:**
- Never leave tests broken or outdated after a feature update
- If tests need to be temporarily disabled, document why and create a task to fix them
- Test coverage should never decrease - only increase or stay the same
- Breaking changes to features MUST have corresponding test updates

**Example Workflow:**

```
User: "Update the player photo feature to support GIF files"
Claude:
1. Updates the code to support GIF files
2. Asks: "I've updated the player photo feature to support GIF files.
   Would you like me to update the PlayerProvider tests to cover GIF file handling?"
User: "yes"
Claude:
1. Adds tests for GIF file handling to test/providers/player_provider_test.dart
2. Runs flutter test - now 183 tests (was 180)
3. Updates CLAUDE.md:
   - Line 45: "Test suite (183 tests)"
   - Provider Tests section: "player_provider_test.dart (33 tests)" (was 30)
   - Test Expectations: "All 183 tests must pass"
4. Commits changes with updated CLAUDE.md
```

## UI Automation Testing Guidelines (integration_test/ Directory)

**IMPORTANT: These rules ONLY apply to UI automation tests in the `integration_test/` directory that use `flutter drive` with chromedriver.**

**These rules DO NOT apply to:**
- Unit tests in `test/models/`
- Provider tests in `test/providers/`
- Service tests in `test/services/`
- Widget tests in `test/widgets/`
- Game logic integration tests in `test/screens/games/`

Those tests run with `flutter test` and can use `pumpAndSettle()` normally without issues.

---

### Test Directory Structure

```
dart_games/
├── test/                           # Regular tests - use flutter test
│   ├── models/                     # ✅ pumpAndSettle() safe
│   ├── providers/                  # ✅ pumpAndSettle() safe
│   ├── services/                   # ✅ pumpAndSettle() safe
│   ├── widgets/                    # ✅ pumpAndSettle() safe
│   └── screens/games/              # ✅ pumpAndSettle() safe
│
├── integration_test/               # UI automation tests - use flutter drive
│   └── target_tag_add_player_test.dart  # ⚠️ Follow continuous animation rules
│
└── test_driver/
    └── integration_test.dart       # Required driver for flutter drive
```

---

### Running UI Automation Tests (integration_test/)

UI automation tests require **chromedriver** and **flutter drive** (not `flutter test`).

#### Step 1: Install ChromeDriver

ChromeDriver should be installed at:
```
dart_games/chromedriver/chromedriver-win64/chromedriver.exe
```

If not present, download the matching version for your Chrome browser from [ChromeDriver Downloads](https://chromedriver.chromium.org/downloads).

#### Step 2: Start ChromeDriver

**CRITICAL: ChromeDriver must be running BEFORE you run the tests.**

```bash
# Navigate to chromedriver directory
cd dart_games/chromedriver/chromedriver-win64

# Start chromedriver on port 4444 (leave this running)
./chromedriver.exe --port=4444
```

You should see:
```
ChromeDriver was started successfully on port 4444.
```

**Leave this terminal window open** - chromedriver must continue running while tests execute.

#### Step 3: Run UI Automation Tests

In a **separate terminal**:

```bash
cd dart_games

# Run a specific UI automation test
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_add_player_test.dart \
  -d chrome
```

**Important flags:**
- `--driver=test_driver/integration_test.dart` - Points to the test driver
- `--target=integration_test/your_test.dart` - The UI test file to run
- `-d chrome` - Run in Chrome browser (requires chromedriver on port 4444)

#### Recommended: Launch Interactive UI Tests in Claude Code

When running UI tests interactively in Claude Code, use these commands in sequence:

**Command 1: Start ChromeDriver**
```bash
cd dart_games/chromedriver/chromedriver-win64 && ./chromedriver.exe --port=4444
```
Set to run in background: Yes

**Command 2: Wait for ChromeDriver to initialize**
```bash
sleep 5
```

**Command 3: Run the UI test**
```bash
cd dart_games && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/YOUR_TEST_FILE.dart -d chrome
```
Replace `YOUR_TEST_FILE.dart` with the actual test file you want to run (e.g., `target_tag_add_player_test.dart`, `temp_edit_score_test.dart`, etc.)

**Why this approach:**
- Running chromedriver in background allows the test to run in the same session
- The 5-second sleep ensures chromedriver is fully initialized before tests start
- All commands execute in the same Claude Code session without manual terminal switching

#### Step 4: Stop ChromeDriver

After tests complete:

```bash
# Windows
taskkill /F /IM chromedriver.exe

# Linux/Mac
killall chromedriver
```

#### Common Launch Issues

**"Unable to start a WebDriver session"**
- ChromeDriver is not running on port 4444
- Start chromedriver first (see Step 2)

**"Connection refused" or "Invalid session"**
- ChromeDriver version doesn't match Chrome browser version
- Download the correct chromedriver version for your Chrome

**Tests hang immediately**
- Using `pumpAndSettle()` on a screen with continuous animations
- See "Continuous Animation Rules" below

---

### Test Driver Setup (Required)

All UI automation tests require a test driver file at `test_driver/integration_test.dart`:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

This file should already exist. **Do not modify it.**

---

### Critical Rules for Screens with Continuous Animations

**NEVER use `pumpAndSettle()` on screens with infinite/repeating animations.**

This is the #1 cause of UI automation test hangs.

#### Identifying Continuous Animations

Screens with continuous animations will cause `pumpAndSettle()` to hang forever waiting for animations to complete.

**Look for this pattern in screen code:**
```dart
// This creates an infinite animation:
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);  // ← INFINITE - never settles
```

**Example screens with continuous animations:**
- Target Tag menu screen (pulse animation)
- Any screen with repeating/looping animations
- Screens with animated backgrounds or continuously moving elements

#### The Problem

```dart
// ❌ WRONG - Will hang forever on screens with continuous animations
await tester.tap(find.text('Target Tag'));
await tester.pumpAndSettle(); // ← HANGS FOREVER waiting for pulse animation to stop
```

The test will appear to freeze after navigating to the screen. No error message, just infinite waiting.

#### The Solution

Use explicit `pump()` sequences instead of `pumpAndSettle()`:

```dart
// ✅ CORRECT - Use explicit pump() calls
await tester.tap(find.text('Target Tag'));
await tester.pump(); // Process the tap
await tester.pump(const Duration(seconds: 1)); // Let navigation complete
await tester.pump(); // Process navigation
await tester.pump(const Duration(seconds: 5)); // Wait for async loading
await tester.pump(); // Process data loaded
await tester.pump(); // Rebuild widget tree
await tester.pump(); // Layout widgets
await tester.pump(); // Paint widgets
```

---

### Frame Pumping Patterns for UI Automation Tests

**Pattern 1: After navigation to a new screen**
```dart
await tester.tap(find.text('Screen Name'));
// Don't use pumpAndSettle() if screen has continuous animations
await tester.pump(); // Process the tap
await tester.pump(const Duration(seconds: 1)); // Let navigation complete
await tester.pump(); // Process navigation
await tester.pump(); // Build widget tree
```

**Pattern 2: After async operations (like loading data from SharedPreferences)**
```dart
// Wait for async data to load, then rebuild UI
await tester.pump(const Duration(seconds: 5)); // Wait for async operation (e.g., PlayerProvider.loadPlayers())
await tester.pump(); // Process data loaded
await tester.pump(); // Rebuild widget tree with new data
await tester.pump(); // Layout the new widgets
await tester.pump(); // Paint the widgets
```

**Pattern 3: After tapping a button that opens a dialog**
```dart
await tester.tap(buttonFinder);
await tester.pump(); // Process tap
await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
await tester.pump(); // Build dialog
await tester.pump(); // Layout dialog
await tester.pump(); // Paint dialog
```

**Pattern 4: After entering text in a field**
```dart
await tester.enterText(textFieldFinder, 'Text');
await tester.pump(); // Process text entry
await tester.pump(); // Update text field
```

**Pattern 5: After tapping a button that closes a dialog**
```dart
await tester.tap(buttonFinder);
await tester.pump(); // Process tap
await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
await tester.pump(); // Process dialog closing
```

---

### When pumpAndSettle() is Safe in UI Automation Tests

**Only use `pumpAndSettle()` when you're certain there are no continuous animations:**

```dart
// ✅ Safe - On splash screen or home screen before navigating
app.main();
await tester.pumpAndSettle();
await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for splash

// ❌ UNSAFE - After navigating to screen with continuous animations
await tester.tap(find.text('Target Tag'));
await tester.pumpAndSettle(); // ← WILL HANG if Target Tag has pulse animation
```

**General rule:** Once you navigate to any game screen, assume it might have continuous animations and **stop using `pumpAndSettle()`**. Use explicit `pump()` sequences instead.

---

### Widget Finder Best Practices for UI Automation Tests

**If a specific widget type isn't found, try finding by text:**

```dart
// If this fails (widget type doesn't match in integration test environment):
final button = find.widgetWithText(ElevatedButton, 'BUTTON TEXT');

// Try this instead (more reliable in UI automation tests):
final button = find.text('BUTTON TEXT');
```

The widget tree may render widgets differently in UI automation tests vs. regular widget tests, so finding by visible text is often more reliable.

**Use ensureVisible() for scrollable content:**
```dart
final button = find.text('BUTTON TEXT');
await tester.ensureVisible(button.first);
await tester.pump(); // Process ensureVisible
await tester.tap(button.first);
await tester.pump(); // Process tap
```

---

### Debugging UI Automation Tests

**Add temporary debug output to understand widget state:**

```dart
print('=== DEBUG ===');
print('Button found: ${find.text('BUTTON').evaluate().length}');
print('Dialogs found: ${find.byType(AlertDialog).evaluate().length}');
print('ListView found: ${find.byType(ListView).evaluate().length}');
```

**IMPORTANT: Remove all debug output before committing.**

**Common debug checks:**
- Check if expected widgets are rendered
- Verify dialog opened/closed
- Confirm list items loaded
- Check button enabled/disabled state

---

### Complete UI Automation Test Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Game Screen UI Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Pre-configure any required settings
      await prefs.setBool('use_emulator', true);
    });

    testWidgets('Test description', (WidgetTester tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle(); // ✅ Safe - on splash/home screen
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for splash

      // 2. Navigate to screen (assume it has continuous animations)
      await tester.tap(find.text('Screen Name'));
      // ⚠️ NO MORE pumpAndSettle() from here on
      await tester.pump(); // Process tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree
      await tester.pump(); // Layout widgets
      await tester.pump(); // Paint widgets

      // 3. Verify screen loaded
      expect(find.text('Expected Screen Element'), findsOneWidget);

      // 4. Interact with UI - open dialog
      await tester.tap(find.text('Button'));
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // 5. Enter text
      await tester.enterText(find.byType(TextField), 'Test Input');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // 6. Submit dialog
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog close
      await tester.pump(); // Process dialog closing

      // 7. Verify results
      expect(find.text('Test Input'), findsOneWidget);
    });
  });
}
```

---

### Common UI Automation Test Pitfalls

1. **Using `pumpAndSettle()` on screens with continuous animations**
   - Symptom: Test hangs forever after navigating to screen
   - Solution: Use explicit `pump()` sequences

2. **ChromeDriver not running**
   - Symptom: "Unable to start a WebDriver session"
   - Solution: Start chromedriver on port 4444 before running tests

3. **Not pumping enough frames after async operations**
   - Symptom: Widgets not found, "Expected 1 but found 0"
   - Solution: Add more `pump()` calls after async waits

4. **Assuming widget types match exactly**
   - Symptom: `find.widgetWithText(ElevatedButton, 'TEXT')` finds nothing
   - Solution: Use `find.text('TEXT')` instead

5. **Forgetting to wait for async data loading**
   - Symptom: Buttons/content not available, empty lists
   - Solution: Add `pump(Duration(seconds: 5))` followed by rebuild pumps

6. **Not using `ensureVisible()`**
   - Symptom: Tap fails or taps wrong element
   - Solution: Use `ensureVisible()` before tapping scrollable content

7. **Wrong test runner**
   - Symptom: Test doesn't connect to browser
   - Solution: Use `flutter drive`, NOT `flutter test`, for integration_test/ files

---

### UI Automation Test Checklist

Before committing UI automation tests:

- [ ] Tests run with `flutter drive` (not `flutter test`)
- [ ] ChromeDriver setup documented/working
- [ ] Tests pass consistently when run multiple times
- [ ] No `pumpAndSettle()` calls on screens with continuous animations
- [ ] All debug output removed
- [ ] Proper frame pumping sequences used throughout
- [ ] Tests complete in reasonable time (< 5 minutes)
- [ ] Test descriptions are clear and specific
- [ ] setUp() clears SharedPreferences for test isolation
- [ ] Temporary test files deleted

---

### Quick Reference

**Run regular tests (test/ directory):**
```bash
flutter test                                    # All tests
flutter test test/models/                       # Model tests
flutter test test/providers/                    # Provider tests
```

**Run UI automation tests (integration_test/ directory):**
```bash
# Terminal 1 - Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2 - Run UI tests
cd dart_games
# Example: Run a specific test file
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_add_player_test.dart \
  -d chrome

# Or run Carnival Derby UI tests
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/carnival_derby_ui_test.dart \
  -d chrome
```

## Git Workflow

### Push Permission Required

**NEVER push to the master branch without explicit permission from the user.**

Before pushing any commits to the remote repository:
1. Ask the user for permission to push
2. Wait for explicit approval
3. Only push after receiving confirmation

This applies to all git operations that modify the remote repository, including:
- `git push origin master`
- `git push`
- Force pushes or any other push commands

## Development Workflow

### Standard Development Process

1. Make code changes (excluding protected dartboard emulator code)
2. **MANDATORY: Run full non-UI test suite**
   ```bash
   cd dart_games
   flutter test
   ```
3. **Verify ALL 226 non-UI tests pass (100% pass rate required)**
4. **OPTIONAL: Ask user if they want to run UI automation tests (76 tests, ~43 minutes)**
5. If ANY tests fail:
   - DO NOT proceed
   - Investigate and fix the failing tests
   - Re-run the test suite
   - Only continue after all tests pass
6. Commit changes locally (if appropriate)
7. **Ask user for permission before pushing to remote**
8. Wait for explicit user approval
9. Only then proceed with build/deployment

### Build Process

**NEVER build without running non-UI tests first.**

Before any `flutter run` or `flutter build` command:
1. Run `flutter test` (226 non-UI tests)
2. Confirm all 226 non-UI tests pass
3. Ask user if they want to run UI automation tests (76 tests, ~43 minutes)
4. Only then run the build command

### Quick Reference

✅ **Always run tests before:**
- Committing changes
- Building the app
- Deploying to production
- Creating pull requests
- Pushing to remote

❌ **Never:**
- Build without running tests
- Commit with failing tests
- Push to remote without user permission
- Modify dartboard emulator without permission

## Notes

- The dartboard emulator has been validated to work correctly
- Test results are documented in `TEST_RESULTS.md`
- Any dartboard-related issues should be reported to the user for approval before fixing
