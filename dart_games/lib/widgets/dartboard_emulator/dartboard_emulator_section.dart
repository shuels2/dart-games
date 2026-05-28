import 'package:flutter/material.dart';
import '../interactive_dartboard.dart';
import 'dartboard_emulator_controller.dart';
import 'dartboard_emulator_config.dart';
import 'buff_toggle_column.dart';
import 'package:dart_games/constants/test_keys.dart';

class DartboardEmulatorSection extends StatelessWidget {
  final DartboardEmulatorController controller;
  /// When true, the emulator is hidden (real dartboard handles input).
  /// Pass `!dartboardProvider.isEmulator` so the emulator only shows
  /// when the user explicitly chose emulator mode.
  final bool isConnected;
  final bool shouldPromptTakeout;
  final Function(int score, String multiplier, int baseScore, Offset position) onDartThrow;
  final VoidCallback onRemoveDarts;
  final GlobalKey<InteractiveDartboardState>? dartboardKey;
  final DartboardSectionConfig config;
  final VoidCallback? onPlayToComplete;
  final PlayToCompleteButtonConfig? playToCompleteConfig;
  // Play to Tie button — only set for tie-capable games (Tiki Golf,
  // Pirate's Grid, Monster Mash, Reef Royale). `playToTieEnabled`
  // lets the game screen disable the button when the current settings
  // make a tie unreachable (e.g. MM/RR without Speed Play). When the
  // controller is auto-playing (either runner is active), BOTH
  // auto-play buttons disable themselves — no toggling between
  // Complete and Tie mid-run.
  final VoidCallback? onPlayToTie;
  final PlayToTieButtonConfig? playToTieConfig;
  final bool playToTieEnabled;

  /// Optional buff-toggle specs (emulator-only debug control).
  /// Only games with bonus buffs (Monster Mash, Reef Royale) supply
  /// this; null/empty keeps the original dartboard-only layout.
  /// Generic over `dynamic` so this widget can host both enum types
  /// — game screens know which enum they're passing back.
  final List<BuffToggleSpec<Object>>? buffToggles;

  /// Called when a buff button is tapped. Receives the buff enum
  /// value. Cast to the game's enum type in the game-screen handler.
  final void Function(Object buff)? onBuffToggle;

  /// Max buttons per column before spilling into a new outer column.
  /// Defaults to 6 — neither Monster Mash (4) nor Reef Royale (3) hits
  /// this today, but future games can grow beyond it.
  final int maxButtonsPerColumn;

  const DartboardEmulatorSection({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.shouldPromptTakeout,
    required this.onDartThrow,
    required this.onRemoveDarts,
    this.dartboardKey,
    required this.config,
    this.onPlayToComplete,
    this.playToCompleteConfig,
    this.onPlayToTie,
    this.playToTieConfig,
    this.playToTieEnabled = true,
    this.buffToggles,
    this.onBuffToggle,
    this.maxButtonsPerColumn = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Don't render if connected or hidden
        if (isConnected || !controller.isVisible) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auto-play buttons row — Play to Complete and Play to Tie
            // sit side-by-side when both are wired. When only Play to
            // Complete is wired (most games), it renders alone with
            // the same padding as before. Both buttons disable
            // themselves while `controller.isAutoPlaying` so once one
            // runner has started the user can't kick off the other.
            if (onPlayToComplete != null && playToCompleteConfig != null)
              _buildAutoPlayButtonsRow(),
            _buildDartboardWithBuffColumns(),
          ],
        );
      },
    );
  }

  /// Builds the dartboard Container, optionally flanked by columns of
  /// buff-toggle buttons (left + right of the dartboard). When
  /// [buffToggles] is null/empty the result is just the dartboard
  /// Container, identical to the original layout.
  Widget _buildDartboardWithBuffColumns() {
    final dartboardContainer = Container(
      padding: config.padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: config.borderRadius,
        border: config.border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AbsorbPointer(
            absorbing: shouldPromptTakeout || controller.isAutoPlaying,
            child: Opacity(
              opacity: shouldPromptTakeout ? 0.5 : 1.0,
              child: InteractiveDartboard(
                key: dartboardKey,
                size: 250,
                onDartThrow: onDartThrow,
                onRemoveDarts: onRemoveDarts,
              ),
            ),
          ),
          if (shouldPromptTakeout) _buildDisabledOverlay(),
        ],
      ),
    );

    final toggles = buffToggles;
    if (toggles == null || toggles.isEmpty || onBuffToggle == null) {
      return dartboardContainer;
    }

    // Split index-parity left vs right (even indexes left, odd right)
    // then break each side into stacked columns of at most
    // [maxButtonsPerColumn] buttons each. Innermost column hugs the
    // dartboard; later columns spill outward.
    final leftSpecs = <BuffToggleSpec<Object>>[];
    final rightSpecs = <BuffToggleSpec<Object>>[];
    for (int i = 0; i < toggles.length; i++) {
      (i.isEven ? leftSpecs : rightSpecs).add(toggles[i]);
    }
    final leftColumns = _chunkIntoColumns(leftSpecs, maxButtonsPerColumn);
    final rightColumns = _chunkIntoColumns(rightSpecs, maxButtonsPerColumn);

    // Row with Expanded spacers keeps the dartboard centered regardless
    // of how many buff columns exist on each side.
    final leftWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = leftColumns.length - 1; i >= 0; i--) ...[
          if (i < leftColumns.length - 1) const SizedBox(width: 8),
          BuffToggleColumn<Object>(
            specs: leftColumns[i],
            onToggle: onBuffToggle!,
          ),
        ],
        if (leftColumns.isNotEmpty) const SizedBox(width: 8),
      ],
    );
    final rightWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rightColumns.isNotEmpty) const SizedBox(width: 8),
        for (int i = 0; i < rightColumns.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          BuffToggleColumn<Object>(
            specs: rightColumns[i],
            onToggle: onBuffToggle!,
          ),
        ],
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Align(alignment: Alignment.centerRight, child: leftWidget)),
        dartboardContainer,
        Expanded(child: Align(alignment: Alignment.centerLeft, child: rightWidget)),
      ],
    );
  }

  /// Split [specs] into chunks of at most [maxPerColumn] entries each.
  /// First chunk is the innermost column (closest to dartboard).
  static List<List<BuffToggleSpec<Object>>> _chunkIntoColumns(
    List<BuffToggleSpec<Object>> specs,
    int maxPerColumn,
  ) {
    if (specs.isEmpty) return const [];
    final chunks = <List<BuffToggleSpec<Object>>>[];
    for (int i = 0; i < specs.length; i += maxPerColumn) {
      chunks.add(
        specs.sublist(
          i,
          (i + maxPerColumn).clamp(0, specs.length),
        ),
      );
    }
    return chunks;
  }

  /// Render Play to Complete and (if wired) Play to Tie side-by-side.
  /// Both buttons disable when `controller.isAutoPlaying` so the user
  /// can't switch modes mid-run.
  Widget _buildAutoPlayButtonsRow() {
    final hasTie = onPlayToTie != null && playToTieConfig != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayToCompleteButton(),
          if (hasTie) ...[
            const SizedBox(width: 12),
            _buildPlayToTieButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayToCompleteButton() {
    final btnConfig = playToCompleteConfig!;
    // Disabled while a takeout is pending OR a runner (either kind)
    // is already auto-playing — once Play to Tie has started the user
    // can't kick off Play to Complete and vice versa.
    final disabled = shouldPromptTakeout || controller.isAutoPlaying;
    return ElevatedButton.icon(
      key: DartboardEmulatorKeys.playToCompleteButton,
      onPressed: disabled ? null : onPlayToComplete,
      icon: Icon(btnConfig.icon, color: btnConfig.foregroundColor),
      label: Text(btnConfig.buttonText, style: btnConfig.textStyle),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnConfig.backgroundColor,
        disabledBackgroundColor: btnConfig.backgroundColor.withOpacity(0.5),
        side: BorderSide(color: btnConfig.borderColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildPlayToTieButton() {
    final btnConfig = playToTieConfig!;
    // Disable when:
    //   - takeout pending,
    //   - any auto-play runner is already active (mutual exclusion),
    //   - or the game's current settings can't produce a tie (e.g.
    //     Monster Mash / Reef Royale with Speed Play off). The game
    //     screen owns that last signal and passes it as
    //     `playToTieEnabled`.
    final disabled = shouldPromptTakeout ||
        controller.isAutoPlaying ||
        !playToTieEnabled;
    return ElevatedButton.icon(
      key: DartboardEmulatorKeys.playToTieButton,
      onPressed: disabled ? null : onPlayToTie,
      icon: Icon(btnConfig.icon, color: btnConfig.foregroundColor),
      label: Text(btnConfig.buttonText, style: btnConfig.textStyle),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnConfig.backgroundColor,
        disabledBackgroundColor: btnConfig.backgroundColor.withOpacity(0.5),
        side: BorderSide(color: btnConfig.borderColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildDisabledOverlay() {
    // The outer Material(transparency) prevents Flutter's debug
    // double-underline from leaking onto the prompt and button text
    // when this overlay renders without a Material ancestor in scope.
    // Matches the fix applied to other shared modals (see
    // remove_darts_modal.dart, save_game_modal.dart, etc.).
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: config.disabledOverlayBackgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: config.disabledOverlayBorderColor,
            width: config.disabledOverlayBorderWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              config.promptIcon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              config.promptText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: DartboardEmulatorKeys.removeDartsButton,
              onPressed: () => dartboardKey?.currentState?.removeDarts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.removeButtonBackgroundColor,
                side: BorderSide(
                  color: config.removeButtonBorderColor,
                  width: 2,
                ),
              ),
              child: Text(
                config.removeButtonText,
                style: config.removeButtonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
