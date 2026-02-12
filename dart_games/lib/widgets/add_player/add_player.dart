/// Shared Add Player dialog component.
///
/// Provides a reusable dialog for adding new players across all games
/// and the System Settings screen.
///
/// Usage:
/// ```dart
/// final player = await showAddPlayerDialog(
///   context: context,
///   config: AddPlayerDialogConfig.carnivalDerby(),
/// );
///
/// if (player != null) {
///   await playerProvider.savePlayer(player);
///   // Handle auto-selection, scroll, etc.
/// }
/// ```
library add_player;

export 'add_player_dialog.dart';
export 'add_player_dialog_config.dart';
