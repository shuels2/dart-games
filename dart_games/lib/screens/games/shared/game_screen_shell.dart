import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_paused_modal/auto_save_on_pause.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';

/// The load-bearing chrome every game screen ends in.
///
/// All ten games built the same six-layer sandwich by hand. The layer ORDER is
/// behaviour, not decoration, and getting it wrong produces bugs that only show
/// up mid-takeout:
///
///   1. `Scaffold`             — app bar + game body
///   2. `RemoveDartsModal`     — BELOW the emulator, so the emulator's
///                               DARTS REMOVED button stays tappable on top of
///                               the takeout barrier
///   3. `DartboardEmulatorSection`
///   4. `DartboardEmulatorFAB` — above the emulator, so layer 2 can block the
///                               AppBar back arrow without also blocking the FAB
///   4b. [extraOverlays]       — game-specific overlays (Treasure Divide's
///                               layout editor, Tiki Golf's mulligan splash)
///   5. `SaveGameModal`
///   6. `DartboardPausedModal` — last child, paints over everything
///
/// The whole stack sits inside a `PopScope` that intercepts a back gesture
/// once any dart has been thrown, and an [AutoSaveOnPause] that saves when the
/// dartboard connection drops.
///
/// The shell reads [DartboardProvider] itself, so the game screen no longer has
/// to `watch` it — a dartboard status change now rebuilds this subtree instead
/// of the entire game body.
class GameScreenShell extends StatelessWidget {
  // ── Layer 1 ────────────────────────────────────────────────────────────────
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;

  // ── Back / save flow ───────────────────────────────────────────────────────

  /// True once the current game has any dart on record. Gates both the
  /// back-gesture interception and the auto-save-on-pause.
  final bool hasDartsThrown;

  /// Whether the save prompt is currently showing. Also makes the pop legal,
  /// so the modal's own "Don't Save" can pop the route.
  final bool showSaveModal;

  /// Called when the user tries to leave with darts thrown. The screen sets
  /// its `_showSaveModal` flag; the shell does not own that state because the
  /// screen's other affordances (its own back button) toggle it too.
  final VoidCallback onRequestSaveModal;

  final Future<void> Function() onSave;
  final VoidCallback onDontSave;
  final Key? saveGameModalKey;

  /// Fired on the connected → disconnected edge, only when [hasDartsThrown].
  final VoidCallback onAutoSave;

  final SaveGameModalConfig saveGameModalConfig;

  // ── Layer 2: remove-darts ──────────────────────────────────────────────────
  final bool shouldPromptTakeout;

  /// Whether to render the standard remove-darts modal. Defaults to
  /// [shouldPromptTakeout]. Games that replace the takeout prompt with their
  /// own overlay (Tiki Golf's mulligan splash) pass `false` here and supply
  /// the replacement through [extraOverlays].
  final bool? showRemoveDartsModal;

  final RemoveDartsModalConfig removeDartsConfig;
  final String removeDartsPlayerName;
  final Key? removeDartsModalKey;
  final Key? editScoreButtonKey;
  final VoidCallback? onEditScore;

  // ── Layers 3 & 4: emulator ─────────────────────────────────────────────────
  final DartboardEmulatorController emulatorController;
  final MockScoliaApiService? mockApi;
  final GlobalKey<InteractiveDartboardState>? dartboardKey;
  final DartboardSectionConfig emulatorSectionConfig;
  final DartboardFABConfig fabConfig;
  final VoidCallback onCancelAutoPlay;

  /// Name reported for emulator-generated throws. Only Treasure Divide sends
  /// the real player name; everyone else sends the literal `'Player'`.
  final String emulatorThrowPlayerName;

  final VoidCallback? onPlayToComplete;
  final PlayToCompleteButtonConfig? playToCompleteConfig;
  final VoidCallback? onPlayToTie;
  final PlayToTieButtonConfig? playToTieConfig;
  final bool playToTieEnabled;
  final List<BuffToggleSpec<Object>>? buffToggles;
  final void Function(Object buff)? onBuffToggle;

  // ── Layer 4b ───────────────────────────────────────────────────────────────
  final List<Widget> extraOverlays;

  // ── Layer 6 ────────────────────────────────────────────────────────────────
  final DartboardPausedModalConfig pausedModalConfig;

  const GameScreenShell({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    required this.hasDartsThrown,
    required this.showSaveModal,
    required this.onRequestSaveModal,
    required this.onSave,
    required this.onDontSave,
    this.saveGameModalKey,
    required this.onAutoSave,
    required this.saveGameModalConfig,
    required this.shouldPromptTakeout,
    this.showRemoveDartsModal,
    required this.removeDartsConfig,
    required this.removeDartsPlayerName,
    this.removeDartsModalKey,
    this.editScoreButtonKey,
    this.onEditScore,
    required this.emulatorController,
    required this.mockApi,
    this.dartboardKey,
    required this.emulatorSectionConfig,
    required this.fabConfig,
    required this.onCancelAutoPlay,
    this.emulatorThrowPlayerName = 'Player',
    this.onPlayToComplete,
    this.playToCompleteConfig,
    this.onPlayToTie,
    this.playToTieConfig,
    this.playToTieEnabled = true,
    this.buffToggles,
    this.onBuffToggle,
    this.extraOverlays = const [],
    required this.pausedModalConfig,
  });

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final isConnected = !dartboardProvider.isEmulator;
    final showRemoveDarts = showRemoveDartsModal ?? shouldPromptTakeout;

    return AutoSaveOnPause(
      onPaused: () {
        if (!hasDartsThrown) return;
        onAutoSave();
      },
      child: PopScope(
        canPop: !hasDartsThrown || showSaveModal,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || showSaveModal) return;
          onRequestSaveModal();
        },
        child: Stack(
          children: [
            // ── 1. Scaffold ───────────────────────────────────────────────
            Scaffold(
              backgroundColor: backgroundColor,
              appBar: appBar,
              body: body,
            ),

            // ── 2. RemoveDartsModal — BELOW the emulator on purpose. ───────
            // These outer-Stack modals paint above the Scaffold (including
            // the AppBar and the FAB), so they block every screen
            // interaction while shown. DARTS REMOVED must stay reachable, so
            // the emulator sits on top of this one.
            if (showRemoveDarts)
              RemoveDartsModal(
                key: removeDartsModalKey,
                config: removeDartsConfig,
                playerName: removeDartsPlayerName,
                editScoreButtonKey: editScoreButtonKey,
                onEditScore: onEditScore,
              ),

            // ── 3. Emulator section ───────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DartboardEmulatorSection(
                controller: emulatorController,
                isConnected: isConnected,
                shouldPromptTakeout: shouldPromptTakeout,
                dartboardKey: dartboardKey,
                config: emulatorSectionConfig,
                onDartThrow: (score, multiplier, baseScore, position) {
                  mockApi?.simulateDartThrow(
                    score: score,
                    multiplier: multiplier,
                    playerName: emulatorThrowPlayerName,
                    baseScore: baseScore,
                    widgetX: position.dx,
                    widgetY: position.dy,
                    widgetSize: 250,
                  );
                },
                onRemoveDarts: () => mockApi?.simulateTakeoutFinished(),
                onPlayToComplete: onPlayToComplete,
                playToCompleteConfig: playToCompleteConfig,
                onPlayToTie: onPlayToTie,
                playToTieConfig: playToTieConfig,
                playToTieEnabled: playToTieEnabled,
                buffToggles: buffToggles,
                onBuffToggle: onBuffToggle,
              ),
            ),

            // ── 4. Emulator FAB — above the section so layer 2 can block ──
            // the AppBar back arrow without also blocking the FAB.
            Positioned(
              right: 16,
              bottom: 16,
              child: DartboardEmulatorFAB(
                controller: emulatorController,
                isConnected: isConnected,
                config: fabConfig,
                onCancelAutoPlay: onCancelAutoPlay,
              ),
            ),

            // ── 4b. Game-specific overlays ────────────────────────────────
            ...extraOverlays,

            // ── 5. Save Game Modal ────────────────────────────────────────
            if (showSaveModal)
              SaveGameModal(
                key: saveGameModalKey,
                config: saveGameModalConfig,
                onSave: onSave,
                onDontSave: onDontSave,
              ),

            // ── 6. Dartboard Paused Modal — last child, paints on top. ────
            if (!dartboardProvider.isEmulator &&
                dartboardProvider.status !=
                    DartboardConnectionStatus.connected &&
                dartboardProvider.status != DartboardConnectionStatus.emulator)
              DartboardPausedModal(config: pausedModalConfig),
          ],
        ),
      ),
    );
  }
}
