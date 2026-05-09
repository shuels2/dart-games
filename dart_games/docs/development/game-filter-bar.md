# Game Filter Bar

The home screen renders a sticky filter bar between the AppBar and the scrollable game grid. Users select values across multiple criteria to narrow the visible game list.

## Components

| File | Purpose |
|---|---|
| `lib/models/game_metadata.dart` | Enums (`MaxPlayersBucket`, `GameplayStyle`, `PlayerInteraction`, `GameLength`, `SoloTeamSupport`), the `FilterCriterion` enum, and the `GameMetadata` class with `matchesFilters(...)`. |
| `lib/constants/game_filter_registry.dart` | Authoritative `GameFilterRegistry` listing every game's `GameMetadata`. `byId(...)` lookup and `filter(...)` helper. |
| `lib/widgets/game_filter_bar/multi_select_filter_dropdown.dart` | Reusable pill-shaped dropdown that opens a `CheckboxListTile` menu. Toggling does not auto-dismiss. |
| `lib/widgets/game_filter_bar/game_filter_bar.dart` | The bar widget — stateless, takes the current `filters` map and an `onFiltersChanged` callback. Renders one `MultiSelectFilterDropdown` per `FilterCriterion`. |
| `lib/screens/home_screen.dart` | Owns the filter state. Body is `Column[GameFilterBar, Expanded(scrollable grid)]` so the bar stays sticky while the grid scrolls. |
| `lib/constants/test_keys.dart` | `HomeKeys.filterBar` + per-button keys + per-option key generators. |

## Filter criteria (current set)

| Criterion | Values | Bucket logic |
|---|---|---|
| **Max Players** | `2 (1v1)` / `Up to 8` / `Up to 10` | The game's max-player cap. |
| **Gameplay Style** | `Race` / `Versus` / `Strategy` | A game can carry multiple styles (the field is a `Set<GameplayStyle>`). Today every game has exactly one. |
| **Player Interaction** | `Parallel` / `Light` / `Heavy` | How much one player's actions affect others. |
| **Game Length** | `Quick` (< 10 min) / `Medium` (10–25 min) / `Long` (25+ min) | At default settings only — settings can push games between buckets. |
| **Solo / Team** | `Solo only` / `Solo or Team` | Whether the menu has a Team-mode toggle. |

See `lib/models/game_metadata.dart` for the enum docstrings on each value.

## Semantics

- **Empty selection** for a criterion = "no filter applied for that criterion" (matches all games).
- **Within a single criterion**, multiple selected values **OR** together — a game matches if any of its values is in the selected set.
- **Across criteria**, selections **AND** together — a game must satisfy every active criterion.
- **No matches** → home screen shows an empty-state message ("No games match the selected filters. Try clearing one or more filters.")

## Registering a new game

When you add a new game, you MUST add a `GameMetadata` entry to `lib/constants/game_filter_registry.dart` in the same edit pass that adds the home-screen card. Without an entry, the card shows in the unfiltered view (registry lookup falls back to "show all" on null) but never matches any filtered view.

```dart
// lib/constants/game_filter_registry.dart
GameMetadata(
  gameId: 'your_game',                 // matches the home_screen.dart card's gameId
  displayName: 'Your Game',
  maxPlayers: MaxPlayersBucket.upToEight,
  gameplayStyles: {GameplayStyle.race},
  playerInteraction: PlayerInteraction.parallel,
  gameLength: GameLength.medium,
  soloTeam: SoloTeamSupport.soloOnly,
),
```

You also need to update `test/models/game_metadata_test.dart`'s `expectedIds` set so the registry-coverage test still passes:

```dart
const expectedIds = {
  'carnival_derby',
  'clockwork_quest',
  ...
  'your_game',  // ← add this
};
```

The home-screen card map needs a matching `'gameId'` key:

```dart
// lib/screens/home_screen.dart
{
  'gameId': 'your_game',
  'title': 'Your Game',
  'key': HomeKeys.yourGameCard,
  'imageAssetPath': 'assets/games/your_game/icons/icon.png',
  'color': const Color(0xFF...),
  'onTap': dartboardProvider.canPlayGames
      ? () => _navigateToMenu('your_game')
      : null,
},
```

The game.build skill enforces this via Rule §42 — AR-4 greps all three locations and the new game's id must appear in each.

## Adding a new filter criterion

Adding a criterion is more work than registering a game but is straightforward:

1. **Add the enum + label** in `lib/models/game_metadata.dart`:
   ```dart
   enum YourCriterion {
     valueA('Value A'),
     valueB('Value B');
     const YourCriterion(this.label);
     final String label;
   }
   ```

2. **Add the field** to `GameMetadata`:
   ```dart
   final YourCriterion yourCriterion;
   ```
   (Required → constructor is positional; populate every existing entry in the registry in the same edit.)

3. **Add the `FilterCriterion` enum value:**
   ```dart
   enum FilterCriterion {
     // ...existing
     yourCriterion('Your Criterion');
   }
   ```

4. **Add the switch case** in `GameMetadata.matchesFilters`:
   ```dart
   case FilterCriterion.yourCriterion:
     if (!selected.contains(yourCriterion)) return false;
   ```
   The switch is exhaustive — Dart's analyzer fails the build if you forget this case.

5. **Populate every existing registry entry** in `lib/constants/game_filter_registry.dart`. Compile fails until every entry sets the new field.

6. **Add a dropdown** in `lib/widgets/game_filter_bar/game_filter_bar.dart`:
   ```dart
   MultiSelectFilterDropdown<YourCriterion>(
     buttonKey: HomeKeys.filterYourCriterionButton,
     menuItemKey: HomeKeys.filterYourCriterionOption,
     label: FilterCriterion.yourCriterion.label,
     options: {for (final v in YourCriterion.values) v: v.label},
     selected: (filters[FilterCriterion.yourCriterion] ?? <Object>{})
         .cast<YourCriterion>(),
     onChanged: (s) => _setSelection(FilterCriterion.yourCriterion, s),
   ),
   ```

7. **Add the test keys** to `lib/constants/test_keys.dart`'s `HomeKeys`:
   ```dart
   static const filterYourCriterionButton = Key('home_filter_your_criterion_button');
   static Key filterYourCriterionOption(Object value) =>
       Key('home_filter_your_criterion_option_${(value as Enum).name}');
   ```

8. **Add tests:**
   - In `test/models/game_metadata_test.dart`: an OR-within-criterion case + an orphan-bucket assertion (every value has ≥ 1 game).
   - In `integration_test/home_screen/filter_bar/`: a UI test exercising the new dropdown.

## Tests

- **Non-UI:** `test/models/game_metadata_test.dart` — 19 tests covering AND/OR semantics, registry coverage (all 7 games registered), orphan-bucket detection (every enum value has ≥ 1 game), unique gameIds, contradictory-filter empty result.
- **UI:** `integration_test/home_screen/filter_bar/` — 4 tests covering bar visibility, single-criterion OR, multi-criterion AND, no-match empty state.

## Past failure context

Earlier game builds had `dartboardProvider.useEmulator()` flip status asynchronously, causing the home-screen `DartboardPausedModal` to flash before transitioning to emulator state. That bug was unrelated to the filter bar but lives on the same screen — see `lib/providers/dartboard_provider.dart:178` for the synchronous-status fix and the rationale comment.

## Related

- [Widget Keys](widget-keys.md) — the `HomeKeys` class
- [Adding New Games](adding-games.md) — the Phase 4 / step 7a hook for registering metadata
- [Container App Architecture](../architecture/container-app.md) — overall screen layout
