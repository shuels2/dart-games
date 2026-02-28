import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../providers/player_provider.dart';
import '../add_player/add_player.dart';
import '../player_selection_card.dart';
import 'dual_player_list_panel_config.dart';

/// A widget that renders the complete dual-list player management UI
/// with "Available Players" on the left and "Selected Players" on the right.
///
/// Used by Carnival Derby and Monster Mash menu screens.
class DualPlayerListPanel extends StatefulWidget {
  final DualPlayerListPanelConfig config;

  // Test keys (passed through, not generated)
  final Key? addPlayerButtonKey;
  final Key? addPlayerButtonEmptyStateKey;
  final Key? playerListViewKey;
  final Key Function(String playerId)? playerTileKey;
  final Key Function(String playerId)? removePlayerButtonKey;

  // Custom add player button builder (Monster Mash stone buttons)
  final Widget Function({
    required Key key,
    required VoidCallback onPressed,
    required bool isEmptyState,
  })? customAddPlayerButton;

  // Optional callback after a player is added
  final void Function(Player player)? onPlayerAdded;

  const DualPlayerListPanel({
    super.key,
    required this.config,
    this.addPlayerButtonKey,
    this.addPlayerButtonEmptyStateKey,
    this.playerListViewKey,
    this.playerTileKey,
    this.removePlayerButtonKey,
    this.customAddPlayerButton,
    this.onPlayerAdded,
  });

  @override
  State<DualPlayerListPanel> createState() => _DualPlayerListPanelState();
}

class _DualPlayerListPanelState extends State<DualPlayerListPanel> {
  final ScrollController _availablePlayersScrollController = ScrollController();
  final ScrollController _selectedPlayersScrollController = ScrollController();

  @override
  void dispose() {
    _availablePlayersScrollController.dispose();
    _selectedPlayersScrollController.dispose();
    super.dispose();
  }

  DualPlayerListPanelConfig get config => widget.config;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAvailablePlayersSection(playerProvider),
            ),
            SizedBox(width: config.listGap),
            Expanded(
              child: _buildSelectedPlayersSection(playerProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailablePlayersSection(PlayerProvider playerProvider) {
    final allPlayers = playerProvider.allPlayers;
    final selectedPlayers = playerProvider.selectedPlayers;

    return Container(
      margin: config.availableContainerMargin,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: config.containerColor.withOpacity(config.containerOpacity),
        border: Border.all(
          color: config.containerBorderColor,
          width: config.containerBorderWidth,
        ),
        borderRadius: BorderRadius.circular(config.containerBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  config.availableHeaderText,
                  style: config.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (allPlayers.isNotEmpty)
                _buildAddPlayerButton(isEmptyState: false),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: allPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          config.availableEmptyText,
                          style: config.emptyStateTextStyle,
                        ),
                        const SizedBox(height: 16),
                        _buildAddPlayerButton(isEmptyState: true),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: widget.playerListViewKey,
                    controller: _availablePlayersScrollController,
                    itemCount: allPlayers.length,
                    itemBuilder: (context, index) {
                      final player = allPlayers[index];
                      final isSelected =
                          selectedPlayers.any((p) => p.id == player.id);

                      return PlayerSelectionCard(
                        key: widget.playerTileKey?.call(player.id),
                        player: player,
                        isSelected: isSelected,
                        selectedColor: config.selectedColor,
                        selectedBorderColor: config.selectedBorderColor,
                        unselectedBackgroundColor: config.unselectedBackgroundColor,
                        unselectedBorderColor: config.unselectedBorderColor,
                        nameStyle: config.cardNameStyle,
                        statsStyle: config.cardStatsStyle,
                        checkIconColor: config.checkIconColor,
                        removeIconColor: config.removeIconColor,
                        nameStatsSpacing: config.nameStatsSpacing,
                        onTap: () {
                          if (isSelected) {
                            playerProvider.deselectPlayer(player.id);
                          } else {
                            playerProvider.selectPlayer(player,
                                maxPlayers: config.maxPlayers);
                            // Scroll selected players list to show newly selected player
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              if (mounted) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted &&
                                      _selectedPlayersScrollController
                                          .hasClients) {
                                    final targetPosition =
                                        _selectedPlayersScrollController
                                                .position.maxScrollExtent +
                                            150;
                                    _selectedPlayersScrollController.animateTo(
                                      targetPosition,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                            });
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlayersSection(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;
    final isReady = selectedPlayers.length >= config.minPlayersForReady;

    // Determine border color and width based on ready state
    final borderColor = isReady && config.selectedBorderColorWhenReady != null
        ? config.selectedBorderColorWhenReady!
        : config.containerBorderColor;
    final borderWidth = isReady && config.selectedBorderWidthWhenReady != null
        ? config.selectedBorderWidthWhenReady!
        : config.containerBorderWidth;

    // Determine header color based on ready state
    final headerStyle = isReady && config.selectedHeaderColorWhenReady != null
        ? config.headerTextStyle.copyWith(color: config.selectedHeaderColorWhenReady)
        : config.headerTextStyle;

    return Container(
      margin: config.selectedContainerMargin,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: config.containerColor.withOpacity(config.containerOpacity),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(config.containerBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${config.selectedHeaderText} (${selectedPlayers.length}/${config.maxPlayers})',
            style: headerStyle,
          ),
          const SizedBox(height: 8),
          if (selectedPlayers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  config.selectedEmptyText,
                  style: config.emptyStateTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _selectedPlayersScrollController,
                itemCount: selectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = selectedPlayers[index];
                  return PlayerSelectionCard(
                    key: widget.playerTileKey?.call(player.id),
                    player: player,
                    isSelected: true,
                    compact: false,
                    selectedColor: config.selectedColor,
                    selectedBorderColor: config.selectedBorderColor,
                    unselectedBackgroundColor: config.unselectedBackgroundColor,
                    unselectedBorderColor: config.unselectedBorderColor,
                    nameStyle: config.cardNameStyle,
                    statsStyle: config.cardStatsStyle,
                    checkIconColor: config.checkIconColor,
                    removeIconColor: config.removeIconColor,
                    nameStatsSpacing: config.nameStatsSpacing,
                    onTap: () {},
                    onRemove: () {
                      playerProvider.deselectPlayer(player.id);
                    },
                    removeButtonKey:
                        widget.removePlayerButtonKey?.call(player.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddPlayerButton({required bool isEmptyState}) {
    final key = isEmptyState
        ? widget.addPlayerButtonEmptyStateKey
        : widget.addPlayerButtonKey;

    // Use custom button builder if provided
    if (widget.customAddPlayerButton != null && key != null) {
      return widget.customAddPlayerButton!(
        key: key,
        onPressed: _handleAddPlayer,
        isEmptyState: isEmptyState,
      );
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: config.addButtonColor,
      foregroundColor: config.addButtonForegroundColor,
      padding: isEmptyState
          ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0)
          : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      side: config.addButtonBorderSide ??
          (isEmptyState
              ? BorderSide(
                  color: config.addButtonColor,
                  width: 4,
                )
              : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final textStyle = isEmptyState
        ? (config.emptyStateAddButtonTextStyle ?? config.addButtonTextStyle)
        : config.addButtonTextStyle;

    return ElevatedButton.icon(
      key: key,
      onPressed: _handleAddPlayer,
      style: buttonStyle,
      icon: Icon(config.addButtonIcon, size: isEmptyState ? 24 : 18),
      label: Text(config.addButtonLabel, style: textStyle),
    );
  }

  void _handleAddPlayer() async {
    final player = await showAddPlayerDialog(
      context: context,
      config: config.addPlayerDialogConfig,
    );

    if (player != null && mounted) {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.savePlayer(player);

      // Auto-select the newly added player only if max not reached
      if (playerProvider.selectedPlayers.length < config.maxPlayers) {
        playerProvider.selectPlayer(player, maxPlayers: config.maxPlayers);
      }

      // Notify parent if callback provided
      widget.onPlayerAdded?.call(player);

      // Scroll to show the new player after dialog closes in both lists
      _scrollToNewPlayer();
    }
  }

  void _scrollToNewPlayer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (_availablePlayersScrollController.hasClients) {
              final targetPosition =
                  _availablePlayersScrollController.position.maxScrollExtent +
                      150;
              _availablePlayersScrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            if (_selectedPlayersScrollController.hasClients) {
              final targetPosition =
                  _selectedPlayersScrollController.position.maxScrollExtent +
                      150;
              _selectedPlayersScrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
    });
  }
}
