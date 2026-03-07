# Resume Game Button Integration

## Overview

**ALL games MUST use the shared ResumeGameButton component in their menu screen AppBars.**

The ResumeGameButton provides a consistent way for users to access saved games directly from each game's menu screen. It appears in the AppBar, positioned just to the left of the DartboardConnectionInfo widget.

## Integration Pattern

### Step 1: Import Component

```dart
import '../../../widgets/resume_game_button.dart';
```

### Step 2: Add State Variables

```dart
class _YourGameMenuScreenState extends State<YourGameMenuScreen> {
  bool _hasSavedGames = false;
  bool _showResumeModal = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check for saved games
      final hasSaved = await SaveGameService().hasSavedGames('your_game');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved; // Auto-show modal if games exist
        });
      }
    });
  }

  /// Check for saved games and update button state
  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('your_game');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }
}
```

### Step 3: Add to AppBar

```dart
AppBar(
  title: Text('Your Game Setup'),
  actions: [
    ResumeGameButton(
      key: YourGameMenuKeys.resumeGameButton,
      hasSavedGames: _hasSavedGames,
      onPressed: () => setState(() => _showResumeModal = true),
      color: yourGameThemeColor, // Game-specific color
    ),
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(
        config: DartboardConnectionInfoConfig.yourGame(),
      ),
    ),
  ],
)
```

### Step 4: Add Resume Modal to Widget Tree

```dart
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Scaffold(
        appBar: AppBar(/* ... */),
        body: /* ... */,
      ),
      // Resume game modal overlay - covers entire screen including AppBar
      if (_showResumeModal)
        ResumeGameModal(
          config: ResumeGameModalConfig.yourGame(),
          gameType: 'your_game',
          onStartNewGame: () {
            setState(() => _showResumeModal = false);
            _checkForSavedGames();
          },
          onResumeGame: (savedGame) {
            setState(() => _showResumeModal = false);
            _resumeGame(savedGame);
          },
          onClose: () {
            setState(() => _showResumeModal = false);
            _checkForSavedGames();
          },
        ),
    ],
  );
}
```

### Step 5: Implement Resume Game Handler

```dart
void _resumeGame(SavedGameMetadata savedGame) {
  context.read<YourGameProvider>().restoreGame(savedGame);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const YourGameScreen()),
  ).then((_) => _checkForSavedGames());
}
```

## Component Properties

### Required Properties

- **`hasSavedGames`** (bool) - Whether saved games exist for this game. Controls button enabled/disabled state.
- **`onPressed`** (VoidCallback) - Callback when button is pressed. Typically shows the ResumeGameModal.
- **`color`** (Color) - Icon color when enabled. Should match the game's theme color.

### Optional Properties

- **`key`** (Key) - Widget key for testing. Use `YourGameMenuKeys.resumeGameButton`.
- **`disabledColor`** (Color?) - Icon color when disabled. Defaults to `color.withOpacity(0.3)`.
- **`iconSize`** (double) - Size of the icon. Defaults to 28.

## Button States

### Enabled State
- **Condition:** `hasSavedGames == true`
- **Icon Color:** Full opacity (specified `color`)
- **Tooltip:** "Resume saved game"
- **Behavior:** Calls `onPressed` when tapped

### Disabled State
- **Condition:** `hasSavedGames == false`
- **Icon Color:** 30% opacity (grayed out)
- **Tooltip:** "No saved games"
- **Behavior:** Non-interactive (no tap response)

## Visual Consistency

The button uses the **history icon** (`Icons.history`) across all games, providing immediate visual recognition. Only the color changes to match each game's theme:

- **Target Tag:** White (`Colors.white`)
- **Carnival Derby:** Cedar (`const Color(0xFF8B5E3C)`)
- **Monster Mash:** Void Purple (`const Color(0xFF9D4EDD)`)
- **Reef Royale:** Pearl White (`const Color(0xFFFFF8F0)`)

## Testing Integration

### Widget Key

Each game must provide a widget key for the resume button:

```dart
class YourGameMenuKeys {
  static const resumeGameButton = Key('your_game_resume_game_button');
}
```

### UI Test Pattern

```dart
testWidgets('button is disabled when no saved games exist', (tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  final resumeButton = find.byKey(YourGameMenuKeys.resumeGameButton);
  expect(resumeButton, findsOneWidget);

  // Find the IconButton within ResumeGameButton
  final iconButtonFinder = find.descendant(
    of: resumeButton,
    matching: find.byType(IconButton),
  );
  final iconButton = tester.widget<IconButton>(iconButtonFinder);

  // Verify button is disabled
  expect(iconButton.onPressed, isNull);
  expect(iconButton.tooltip, 'No saved games');
});
```

## Benefits

- **Consistency:** Same icon, same position, same behavior across all games
- **Accessibility:** Button is only enabled when it can perform an action
- **User Experience:** Direct access to saved games from menu screen
- **Testing:** Standard widget key pattern for UI automation
- **Minimal Code:** Single line of code per game to integrate

## Reference Implementations

- **Target Tag:** `lib/screens/games/target_tag/target_tag_menu_screen.dart`
- **Carnival Derby:** `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart`
- **Monster Mash:** `lib/screens/games/monster_mash/monster_mash_menu_screen.dart`
- **Reef Royale:** `lib/screens/games/reef_royale/reef_royale_menu_screen.dart`

## Related Documentation

- [Save & Resume Game](save-resume-game.md) - Complete save/resume feature documentation
- [Adding New Games](adding-games.md) - Step 15 covers ResumeGameButton integration
- [Widget Keys](widget-keys.md) - Widget key requirements for testing
- [Dartboard Connection Info](dartboard-connection-info.md) - Adjacent component in AppBar

## Common Issues

### Issue: Button doesn't update after saving a game

**Problem:** The button stays disabled even after saving a game.

**Solution:** Call `_checkForSavedGames()` in the navigation callback:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const YourGameScreen()),
).then((_) => _checkForSavedGames()); // ← Add this
```

### Issue: Modal doesn't cover AppBar

**Problem:** Resume modal only covers the body area below the AppBar.

**Solution:** Wrap the entire Scaffold in a Stack and place the modal at the root level:

```dart
return Stack(  // ← Root Stack
  children: [
    Scaffold(/* ... */),
    if (_showResumeModal) ResumeGameModal(/* ... */),  // ← At root level
  ],
);
```

### Issue: Button briefly shows wrong state on screen load

**Problem:** Button flickers between states when navigating to menu.

**Solution:** Initialize `_hasSavedGames = false` and update in `addPostFrameCallback`:

```dart
bool _hasSavedGames = false;  // ← Initialize as false

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final hasSaved = await SaveGameService().hasSavedGames('your_game');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  });
}
```
