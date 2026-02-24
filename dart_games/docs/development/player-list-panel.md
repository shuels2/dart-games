# Player List Panel Component

## Overview

The Player List Panel provides shared, configurable player management UI for game menu screens. It eliminates 250-400+ lines of duplicated layout code per game while allowing full visual customization through config classes.

Two patterns are supported:

1. **Dual-List Pattern** (`DualPlayerListPanel`) — Two side-by-side lists: "Available Players" on the left and "Selected Players" on the right. Used by Carnival Derby and Monster Mash.

2. **Team Game Pattern** (`TeamPlayerListPanel`) — A single player list with optional team assignment features. Used by Target Tag.

## File Location

`lib/widgets/player_list_panel/`

## Components

### Barrel File

`player_list_panel.dart` — Exports all components:
```dart
export 'dual_player_list_panel.dart';
export 'dual_player_list_panel_config.dart';
export 'team_player_list_panel.dart';
export 'team_player_list_panel_config.dart';
```

### DualPlayerListPanelConfig

Configuration class controlling all visual aspects of the dual-list player management area.

| Field | Type | Purpose |
|---|---|---|
| `containerColor` | `Color` | Background color for both list containers |
| `containerOpacity` | `double` | Opacity for container background |
| `containerBorderColor` | `Color` | Border color for containers |
| `containerBorderWidth` | `double` | Border width |
| `containerBorderRadius` | `double` | Border radius |
| `headerTextStyle` | `TextStyle` | Style for "Available Players" / "Selected Players" headers |
| `availableHeaderText` | `String` | Header text for left column (default: "Available Players") |
| `selectedHeaderText` | `String` | Header text for right column (default: "Selected Players") |
| `selectedBorderColorWhenReady` | `Color?` | Border color when min players selected |
| `selectedBorderWidthWhenReady` | `double?` | Border width when min players selected |
| `minPlayersForReady` | `int` | Min players to trigger ready styling (default: 2) |
| `selectedHeaderColorWhenReady` | `Color?` | Header text color when ready |
| `emptyStateTextStyle` | `TextStyle` | Style for empty state text |
| `availableEmptyText` | `String` | Empty state text for available list |
| `selectedEmptyText` | `String` | Empty state text for selected list |
| `addButtonColor` | `Color` | "NEW PLAYER" button background |
| `addButtonForegroundColor` | `Color` | "NEW PLAYER" button text/icon color |
| `addButtonBorderSide` | `BorderSide?` | Optional button border |
| `addButtonTextStyle` | `TextStyle` | Button text style |
| `addButtonIcon` | `IconData` | Button icon (default: `Icons.add`) |
| `addButtonLabel` | `String` | Button label (default: "NEW PLAYER") |
| `emptyStateAddButtonTextStyle` | `TextStyle?` | Larger text for empty state button |
| `selectedColor` | `Color?` | PlayerSelectionCard selected background |
| `selectedBorderColor` | `Color?` | PlayerSelectionCard selected border |
| `unselectedBackgroundColor` | `Color?` | PlayerSelectionCard unselected background |
| `unselectedBorderColor` | `Color?` | PlayerSelectionCard unselected border |
| `cardNameStyle` | `TextStyle?` | Player name text style |
| `cardStatsStyle` | `TextStyle?` | Player stats text style |
| `checkIconColor` | `Color?` | Check icon color |
| `removeIconColor` | `Color?` | Remove icon color |
| `nameStatsSpacing` | `double?` | Spacing between name and stats |
| `maxPlayers` | `int` | Maximum selectable players |
| `addPlayerDialogConfig` | `AddPlayerDialogConfig` | Config for the Add Player dialog |

**Factory methods:**
- `DualPlayerListPanelConfig.carnivalDerby()` — Navy containers, off-white borders, Lava Red add button with Canary Yellow border, Montserrat headers, max 8 players
- `DualPlayerListPanelConfig.monsterMash()` — Dark slate containers, beige borders, PirataOne headers, purple/lime card theming, Creepster names, dynamic lime border when >= 2 selected, max 8 players

### DualPlayerListPanel

StatefulWidget that renders the complete dual-list player management UI.

```dart
DualPlayerListPanel(
  config: DualPlayerListPanelConfig.carnivalDerby(),
  addPlayerButtonKey: CarnivalDerbyMenuKeys.addPlayerButton,
  addPlayerButtonEmptyStateKey: CarnivalDerbyMenuKeys.addPlayerButtonEmptyState,
  playerListViewKey: CarnivalDerbyMenuKeys.playerListView,
  playerTileKey: (id) => CarnivalDerbyMenuKeys.playerTile(id),
  removePlayerButtonKey: (id) => CarnivalDerbyMenuKeys.removePlayerButton(id),
)
```

**Parameters:**

| Parameter | Type | Purpose |
|---|---|---|
| `config` | `DualPlayerListPanelConfig` | Visual configuration |
| `addPlayerButtonKey` | `Key?` | Test key for header add button |
| `addPlayerButtonEmptyStateKey` | `Key?` | Test key for empty state add button |
| `playerListViewKey` | `Key?` | Test key for player ListView |
| `playerTileKey` | `Key Function(String)?` | Test key factory for player tiles |
| `removePlayerButtonKey` | `Key Function(String)?` | Test key factory for remove buttons |
| `customAddPlayerButton` | `Widget Function(...)? ` | Custom button builder (Monster Mash stone buttons) |
| `onPlayerAdded` | `void Function(Player)?` | Callback after player is added |

**Internal behavior:**
- Uses `Consumer<PlayerProvider>` for player data
- Manages two `ScrollController`s (available + selected lists)
- Auto-selects newly added players (if under max)
- Auto-scrolls both lists when a player is added or selected

### TeamPlayerListPanelConfig

Configuration class for the team game pattern.

**Factory methods:**
- `TeamPlayerListPanelConfig.targetTag()` — Hot Pink primary, Neon Green team accent, Fredoka font, dark navy backgrounds, 485/300 list heights, max 10 players, 5 teams

### TeamPlayerListPanel

StatefulWidget for single-list player management with optional team assignment.

```dart
TeamPlayerListPanel(
  config: TeamPlayerListPanelConfig.targetTag(),
  addPlayerButtonKey: TargetTagMenuKeys.addPlayerButton,
  addPlayerButtonEmptyStateKey: TargetTagMenuKeys.addPlayerButtonEmptyState,
  playerListViewKey: TargetTagMenuKeys.playerListView,
  playerTileKey: (id) => TargetTagMenuKeys.playerTile(id),
  isTeamMode: _isTeamMode,
  isManualTeamAssignment: !_isRandomTeams,
  teamIconPaths: _teamIconPaths,
  useFixedHeight: true,
  teamDialogContainerKey: TeamAssignmentDialogKeys.dialogContainer,
  teamDialogDropdownKey: (id) => TeamAssignmentDialogKeys.playerTeamDropdown(id),
  teamDialogCancelKey: TeamAssignmentDialogKeys.cancelButton,
  onTeamAssignmentsChanged: (assignments) {
    setState(() {
      _playerTeamAssignments = assignments;
    });
  },
)
```

**Parameters:**

| Parameter | Type | Purpose |
|---|---|---|
| `config` | `TeamPlayerListPanelConfig` | Visual configuration |
| `isTeamMode` | `bool` | Whether team mode is active |
| `isManualTeamAssignment` | `bool` | Whether manual team assignment is active |
| `teamIconPaths` | `List<String>` | Paths to team icon assets |
| `useFixedHeight` | `bool` | Fixed height (scrollable) or expanded layout |
| `onTeamAssignmentsChanged` | `void Function(Map<String, String>)?` | Callback when assignments change |
| `teamDialogContainerKey` | `Key?` | Test key for team dialog |
| `teamDialogDropdownKey` | `Key Function(String)?` | Test key factory for team buttons |
| `teamDialogCancelKey` | `Key?` | Test key for cancel button |

**Internal behavior:**
- Solo/Random mode: Simple selection list with `PlayerSelectionCard`
- Manual Team mode: Custom cards with "Assign team" button / team icon + team assignment boxes below
- Team selection dialog with 5 team icons, "FULL" badge, "Remove from Team" button
- Team assignments stored internally, notified via `onTeamAssignmentsChanged`

## PlayerSelectionCard Theming Parameters

The `PlayerSelectionCard` widget supports these optional theming parameters (all backward-compatible):

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `unselectedBackgroundColor` | `Color?` | `0xFF1D3557` | Card bg when not selected |
| `unselectedBorderColor` | `Color?` | `0xFF48CAE4` | Border when not selected |
| `statsStyle` | `TextStyle?` | Montserrat 11px | Stats line text style |
| `checkIconColor` | `Color?` | `0xFF48CAE4` | Check circle icon color |
| `removeIconColor` | `Color?` | `0xFFE63946` | Remove circle icon color |
| `trailing` | `Widget?` | null | Custom trailing widget |

## Custom Button Builder (Monster Mash)

Monster Mash uses a custom button builder for its stone tablet buttons:

```dart
DualPlayerListPanel(
  config: DualPlayerListPanelConfig.monsterMash(),
  customAddPlayerButton: ({
    required Key key,
    required VoidCallback onPressed,
    required bool isEmptyState,
  }) {
    return _buildStoneNewPlayerButton(
      key: key,
      onPressed: onPressed,
      fontSize: isEmptyState ? 24 : 18,
      iconSize: isEmptyState ? 24 : 18,
      width: isEmptyState ? 210 : 170,
      height: isEmptyState ? 44 : 36,
      seed: isEmptyState ? 'NEW_PLAYER_EMPTY'.hashCode : 'NEW_PLAYER_HEADER'.hashCode,
    );
  },
)
```

## Adding a New Game

1. Choose pattern: `DualPlayerListPanel` (two lists) or `TeamPlayerListPanel` (single list + teams)
2. Create a factory method in the appropriate config class with your game's colors, fonts, and sizes
3. Pass the config and test keys to the widget in your menu screen
4. For custom buttons, use the `customAddPlayerButton` builder parameter

## Related Documentation

- [Add Player Dialog](add-player-dialog.md) — Dialog used internally for adding players
- [Shared Systems](../architecture/shared-systems.md) — Overview of all shared systems
- [Widget Keys](widget-keys.md) — Key naming conventions for testing
