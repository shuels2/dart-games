import 'package:flutter/foundation.dart';

import '../models/saved_game_metadata.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/save_game_service.dart';

/// Scaffolding shared by every game provider.
///
/// Each of the ten providers re-implemented the same four flows, with enough
/// small divergences between them to keep producing bugs:
///
/// * **Takeout.** `_waitingForTakeout` plus the `darts >= max || hasWinner`
///   condition and the winner-short-circuit → advance → clear sequence.
/// * **Save.** The `_saving` re-entrancy guard, the `_resumedSavedGameId`
///   round-trip that keeps a resumed game overwriting its own slot instead of
///   spawning a new one, and the `finally` that must release the guard even
///   when the server call throws.
/// * **Restore.** Deserialize → restore the takeout flag → remember the slot id.
/// * **Skip.** Validate through [GameSkipTurnHelper], append the markers, and
///   land in the takeout state.
///
/// Subclasses own the game object and the rules; the base owns the plumbing.
abstract class GameProviderBase<G> extends ChangeNotifier {
  G? _game;
  bool _waitingForTakeout = false;
  String? _resumedSavedGameId;
  bool _saving = false;

  /// The active game, or null when no game is in progress. Subclasses expose
  /// this under their own historical name (`currentGame`).
  G? get game => _game;

  @protected
  set game(G? value) => _game = value;

  // ── Contract for subclasses ────────────────────────────────────────────────

  /// True when the game has reached a terminal, someone-has-won state.
  bool get hasWinner;

  /// True while the game is accepting darts.
  bool get isGameActive;

  /// Moves the turn on. Called by [handleTakeoutFinished] only when the game is
  /// still active and nobody has won.
  @protected
  void advanceToNextPlayer();

  /// Rebuilds [game] from a saved game's `gameState` map.
  @protected
  void loadGameState(Map<String, dynamic> json);

  /// Hook for post-restore fixups. Runs after [loadGameState] and after the
  /// takeout flag and slot id are restored, before listeners are notified.
  @protected
  void onRestored() {}

  // ── Takeout ───────────────────────────────────────────────────────────────

  /// Whether the board is waiting for the player to pull their darts.
  ///
  /// Backed by a provider field by default. Games whose model carries the flag
  /// (so it serializes with the game for free — Treasure Divide) override this
  /// pair to point at the model instead. Everything in this class goes through
  /// the getter/setter rather than the field, so an override takes effect
  /// everywhere.
  bool get shouldPromptTakeout => _waitingForTakeout;

  @protected
  set waitingForTakeout(bool value) => _waitingForTakeout = value;

  /// Latches the takeout state when the turn is over — either the player has
  /// used every dart, or the game has been won. Never clears the flag: only
  /// [handleTakeoutFinished] and a fresh game do that.
  @protected
  void checkTakeoutCondition({
    required int dartsThrown,
    required int maxDartsPerTurn,
  }) {
    if (dartsThrown >= maxDartsPerTurn || hasWinner) {
      waitingForTakeout = true;
    }
  }

  /// Called when the board reports the darts have been pulled.
  ///
  /// If the game is already won, this only clears the waiting state — the
  /// screen navigates to results and there is no next player to advance to.
  ///
  /// Games that must commit turn state *before* advancing (Treasure Divide
  /// commits the round haul and applies halving) override this outright; the
  /// rest of the class is still theirs.
  void handleTakeoutFinished() {
    if (_game == null) return;
    if (!shouldPromptTakeout) return;

    if (hasWinner) {
      waitingForTakeout = false;
      notifyListeners();
      return;
    }

    if (!isGameActive) return;

    advanceToNextPlayer();
    waitingForTakeout = false;
    notifyListeners();
  }

  // ── Skip ──────────────────────────────────────────────────────────────────

  /// Runs the shared skip-turn policy: validate, append one `'Skip'` marker
  /// per unthrown dart, then enter the takeout state.
  ///
  /// Returns false when the skip was rejected (no game, already waiting for a
  /// takeout, or the turn is already complete) — in which case nothing was
  /// mutated and no listeners were notified.
  ///
  /// [onSkipped] runs after the markers are appended and before the takeout
  /// flag is set, for games that also have to settle their own turn counters
  /// (Treasure Divide forces `dartsThrown` up to a full turn so the round
  /// commits as an all-miss).
  @protected
  bool runSkipTurn({
    required int dartsThrown,
    required int maxDartsPerTurn,
    required void Function(String marker) addVisualMarker,
    VoidCallback? onSkipped,
  }) {
    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: shouldPromptTakeout,
      currentDartCount: dartsThrown,
      maxDartsPerTurn: maxDartsPerTurn,
    )) {
      return false;
    }

    GameSkipTurnHelper.skipRemainingDarts(
      currentDartCount: dartsThrown,
      maxDartsPerTurn: maxDartsPerTurn,
      addVisualMarker: addVisualMarker,
    );

    onSkipped?.call();

    waitingForTakeout = true;
    notifyListeners();
    return true;
  }

  // ── Save / restore ────────────────────────────────────────────────────────

  /// Id of the saved-game slot this game was resumed from, or the slot it was
  /// last saved into. Keeps repeated saves overwriting one row.
  String? get resumedSavedGameId => _resumedSavedGameId;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  /// Persists the game, guarding against overlapping saves.
  ///
  /// [buildMetadata] receives the existing slot id — pass it straight through
  /// to `SavedGameMetadata.create(existingId: ...)` so a resumed game keeps
  /// its slot. The guard is released in a `finally`, so a failed server call
  /// leaves the provider able to save again rather than wedged.
  @protected
  Future<bool> persistSave(
    SaveGameService service,
    SavedGameMetadata Function(String? existingId) buildMetadata,
  ) async {
    if (_game == null || _saving) return false;
    _saving = true;
    try {
      final metadata = buildMetadata(_resumedSavedGameId);
      final saved = await service.saveGame(metadata);
      if (saved) {
        _resumedSavedGameId = metadata.id;
      }
      return saved;
    } finally {
      _saving = false;
    }
  }

  /// Restores a saved game: deserialize, restore the takeout flag, remember
  /// the slot, then notify.
  void restoreGame(SavedGameMetadata savedGame) {
    loadGameState(Map<String, dynamic>.from(savedGame.gameState));
    waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    onRestored();
    notifyListeners();
  }

  /// Drops the game entirely. Note this does NOT clear [resumedSavedGameId] —
  /// the results screens read it *after* the game object is gone (they delete
  /// the saved row and clear the id themselves at game completion). Games that
  /// DO want the slot forgotten call [clearResumedSavedGameId] in an override.
  ///
  /// The takeout flag is cleared before the game is dropped, so a model-owned
  /// flag is written while its model still exists.
  void clearGame() {
    waitingForTakeout = false;
    _game = null;
    notifyListeners();
  }
}
