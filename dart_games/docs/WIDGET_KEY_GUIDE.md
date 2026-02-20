# Widget Key Naming Guide

## Naming Convention

Format: `{screen}_{widget_purpose}_{widget_type}`

### Screen Prefixes
- `home_` - Home screen (game selection)
- `menu_cd_` - Carnival Derby menu screen
- `menu_tt_` - Target Tag menu screen
- `game_cd_` - Carnival Derby game screen
- `game_tt_` - Target Tag game screen
- `results_cd_` - Carnival Derby results screen
- `results_tt_` - Target Tag results screen
- `dialog_edit_` - Edit score dialog
- `dialog_add_player_` - Add player dialog
- `dialog_team_` - Team assignment dialog
- `options_` - Options/settings screen
- `dartboard_` - Dartboard emulator components

### Widget Type Suffixes
- `_button` - All button types (ElevatedButton, TextButton, IconButton)
- `_switch` - Switch widgets
- `_slider` - Slider widgets
- `_field` - TextField widgets
- `_tile` - ListTile, player tiles
- `_card` - Card widgets
- `_fab` - FloatingActionButton

### Examples
- `home_carnival_derby_card` - Carnival Derby game card on home
- `menu_tt_add_player_button` - Add Player button on Target Tag menu
- `menu_cd_target_score_slider` - Target Score slider on Carnival Derby menu
- `menu_tt_team_mode_switch` - Team Mode switch on Target Tag menu
- `game_cd_dart_single_20_button` - Single 20 dart button in Carnival Derby
- `game_tt_skip_turn_button` - Skip Turn button in Target Tag
- `results_tt_play_again_button` - Play Again button on Target Tag results
- `dialog_edit_update_button` - Update button in edit score dialog

## Key Assignment Rules

### MUST Have Keys
- ✅ All interactive buttons
- ✅ All input controls (Switch, Slider, TextField, Checkbox)
- ✅ All navigation elements
- ✅ All dialog action buttons
- ✅ Dart throw buttons (all 60+)
- ✅ Player tiles/cards
- ✅ Settings controls

### Should Have Keys (If Tested)
- Game status displays
- Score displays
- Player name displays
- Turn indicators

### SKIP Keys (Never Tested)
- ❌ Pure layout widgets (Container, Padding, Column)
- ❌ Decorative images/icons
- ❌ Static text labels
- ❌ Background widgets

## Validation

Every new widget key must:
1. Follow naming convention
2. Be unique across entire app
3. Use const Key() constructor
4. Be documented in this guide
