import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../providers/player_provider.dart';
import '../add_player/add_player.dart';
import '../player_selection_card.dart';
import '../player_avatar_widget.dart';
import 'team_player_list_panel_config.dart';

/// A widget that renders a single-list player management UI with optional
/// team assignment features.
///
/// Used by Target Tag menu screen. Supports solo mode (simple selection list)
/// and manual team mode (selection list + team assignment dialog + team boxes).
class TeamPlayerListPanel extends StatefulWidget {
  final TeamPlayerListPanelConfig config;

  // Test keys
  final Key? addPlayerButtonKey;
  final Key? addPlayerButtonEmptyStateKey;
  final Key? playerListViewKey;
  final Key Function(String playerId)? playerTileKey;

  // Team mode state (controlled by parent)
  final bool isTeamMode;
  final bool isManualTeamAssignment;

  // Team icon paths (game-specific assets)
  final List<String> teamIconPaths;

  // Callbacks
  final void Function(Map<String, String> assignments)? onTeamAssignmentsChanged;
  final void Function(Player player)? onPlayerAdded;

  // Whether the panel should use a fixed height or expand to fill available space
  final bool useFixedHeight;

  // Team assignment dialog keys
  final Key? teamDialogContainerKey;
  final Key Function(String id)? teamDialogDropdownKey;
  final Key? teamDialogCancelKey;

  const TeamPlayerListPanel({
    super.key,
    required this.config,
    this.addPlayerButtonKey,
    this.addPlayerButtonEmptyStateKey,
    this.playerListViewKey,
    this.playerTileKey,
    this.isTeamMode = false,
    this.isManualTeamAssignment = false,
    this.teamIconPaths = const [],
    this.onTeamAssignmentsChanged,
    this.onPlayerAdded,
    this.useFixedHeight = true,
    this.teamDialogContainerKey,
    this.teamDialogDropdownKey,
    this.teamDialogCancelKey,
  });

  @override
  State<TeamPlayerListPanel> createState() => _TeamPlayerListPanelState();
}

class _TeamPlayerListPanelState extends State<TeamPlayerListPanel> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _playerTeamAssignments = {};

  TeamPlayerListPanelConfig get config => widget.config;

  bool get _isManualTeamMode => widget.isTeamMode && widget.isManualTeamAssignment;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final allPlayers = playerProvider.allPlayers;
        final selectedPlayers = playerProvider.selectedPlayers;
        final minPlayers = widget.isTeamMode ? config.minPlayersTeamMode : config.minPlayers;
        final isReady = selectedPlayers.length >= minPlayers;

        if (widget.useFixedHeight) {
          return _buildFixedHeightLayout(
            playerProvider, allPlayers, selectedPlayers, minPlayers, isReady,
          );
        } else {
          return _buildExpandedLayout(
            playerProvider, allPlayers, selectedPlayers, minPlayers, isReady,
          );
        }
      },
    );
  }

  Widget _buildFixedHeightLayout(
    PlayerProvider playerProvider,
    List<Player> allPlayers,
    List<Player> selectedPlayers,
    int minPlayers,
    bool isReady,
  ) {
    final listHeight = _isManualTeamMode ? config.teamListHeight : config.soloListHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(allPlayers, selectedPlayers, minPlayers, isReady),
        const SizedBox(height: 8),
        Container(
          height: listHeight,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: config.containerColor.withOpacity(config.containerOpacity),
            borderRadius: BorderRadius.circular(config.containerBorderRadius),
            border: Border.all(
              color: isReady ? config.containerBorderColorWhenReady : config.containerBorderColor,
              width: config.containerBorderWidth,
            ),
          ),
          child: _buildPlayerList(playerProvider, allPlayers, selectedPlayers),
        ),
        if (_isManualTeamMode) ...[
          const SizedBox(height: 16),
          Text(config.teamAssignmentLabel, style: config.teamAssignmentLabelStyle),
          const SizedBox(height: 8),
          _buildTeamAssignmentBoxes(selectedPlayers),
        ],
      ],
    );
  }

  Widget _buildExpandedLayout(
    PlayerProvider playerProvider,
    List<Player> allPlayers,
    List<Player> selectedPlayers,
    int minPlayers,
    bool isReady,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(allPlayers, selectedPlayers, minPlayers, isReady),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.containerColor.withOpacity(config.containerOpacity),
                borderRadius: BorderRadius.circular(config.containerBorderRadius),
                border: Border.all(
                  color: isReady ? config.containerBorderColorWhenReady : config.containerBorderColor,
                  width: config.containerBorderWidth,
                ),
              ),
              child: _buildPlayerList(playerProvider, allPlayers, selectedPlayers),
            ),
          ),
          if (_isManualTeamMode) ...[
            const SizedBox(height: 16),
            Text(config.teamAssignmentLabel, style: config.teamAssignmentLabelStyle),
            const SizedBox(height: 8),
            _buildTeamAssignmentBoxes(selectedPlayers),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    List<Player> allPlayers,
    List<Player> selectedPlayers,
    int minPlayers,
    bool isReady,
  ) {
    return Row(
      children: [
        Text(config.headerText, style: config.headerTextStyle),
        const SizedBox(width: 8),
        Text(
          '(${selectedPlayers.length}/${config.maxPlayers} selected)',
          style: config.headerCountStyle.copyWith(
            color: isReady ? config.headerCountColorWhenReady : null,
          ),
        ),
        const Spacer(),
        if (allPlayers.isNotEmpty)
          ElevatedButton.icon(
            key: widget.addPlayerButtonKey,
            onPressed: _handleAddPlayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: config.addButtonColor,
              foregroundColor: config.addButtonForegroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(config.addButtonIcon, size: 18),
            label: Text(config.addButtonLabel, style: config.addButtonTextStyle),
          ),
      ],
    );
  }

  Widget _buildPlayerList(
    PlayerProvider playerProvider,
    List<Player> allPlayers,
    List<Player> selectedPlayers,
  ) {
    if (allPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(config.emptyText, style: config.emptyStateTextStyle),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: widget.addPlayerButtonEmptyStateKey,
              onPressed: _handleAddPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.addButtonColor,
                foregroundColor: config.addButtonForegroundColor,
              ),
              icon: Icon(config.addButtonIcon),
              label: Text(
                config.addButtonLabel,
                style: config.emptyStateAddButtonTextStyle ?? config.addButtonTextStyle,
              ),
            ),
          ],
        ),
      );
    }

    if (_isManualTeamMode) {
      return ListView.builder(
        key: widget.playerListViewKey,
        controller: _scrollController,
        itemCount: allPlayers.length,
        itemBuilder: (context, index) {
          final player = allPlayers[index];
          final isSelected = selectedPlayers.any((p) => p.id == player.id);
          final assignedTeamId = _playerTeamAssignments[player.id];

          return _buildPlayerCardWithTeamIcon(
            player,
            isSelected,
            assignedTeamId,
            playerProvider,
          );
        },
      );
    }

    return ListView.builder(
      key: widget.playerListViewKey,
      controller: _scrollController,
      itemCount: allPlayers.length,
      itemBuilder: (context, index) {
        final player = allPlayers[index];
        final isSelected = selectedPlayers.any((p) => p.id == player.id);

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
          onTap: () {
            if (isSelected) {
              playerProvider.deselectPlayer(player.id);
            } else {
              playerProvider.selectPlayer(player, maxPlayers: config.maxPlayers);
            }
          },
        );
      },
    );
  }

  Widget _buildPlayerCardWithTeamIcon(
    Player player,
    bool isSelected,
    String? assignedTeamId,
    PlayerProvider playerProvider,
  ) {
    // Get team icon index if player is assigned to a team
    int? teamIconIndex;
    if (assignedTeamId != null) {
      final teamNumber = int.tryParse(assignedTeamId.replaceAll('team', ''));
      if (teamNumber != null && teamNumber >= 1 && teamNumber <= config.maxTeams) {
        teamIconIndex = teamNumber - 1;
      }
    }

    // Build trailing widget for team mode
    Widget? trailingWidget;
    if (teamIconIndex != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isSelected ? () => _showTeamSelectionDialog(player) : null,
            child: Container(
              width: config.teamIconSize,
              height: config.teamIconSize,
              decoration: BoxDecoration(
                color: config.teamIconBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: config.teamIconBorderColor,
                  width: 2,
                ),
              ),
              child: Image.asset(
                widget.teamIconPaths[teamIconIndex],
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
    } else if (isSelected) {
      trailingWidget = ElevatedButton(
        onPressed: () => _showTeamSelectionDialog(player),
        style: ElevatedButton.styleFrom(
          backgroundColor: config.assignTeamButtonColor,
          foregroundColor: config.assignTeamButtonForegroundColor,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          config.assignTeamButtonLabel,
          style: config.assignTeamButtonTextStyle,
        ),
      );
    }

    // For non-selected with no team: show nothing (no trailing needed)
    // For selected with no team: show "Assign team" button via trailing
    // For selected with team icon: show icon via trailing
    // We also need the check icon for selected solo/random mode, but in
    // manual team mode the trailing replaces the check icon entirely.

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? config.teamAccentColor.withOpacity(0.2)
            : const Color(0xFF2A2A3E),
        border: Border.all(
          color: isSelected ? config.teamAccentColor : Colors.white24,
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelected) {
              playerProvider.deselectPlayer(player.id);
              // Remove team assignment when deselecting
              setState(() {
                _playerTeamAssignments.remove(player.id);
              });
              _notifyTeamAssignmentsChanged();
            } else {
              playerProvider.selectPlayer(player, maxPlayers: config.maxPlayers);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                PlayerAvatarWidget(
                  player: player,
                  size: 22.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: GoogleFonts.fredoka(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Games: ${player.gamesPlayed} | Wins: ${player.gamesWon}',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null)
                  trailingWidget
                else if (isSelected)
                  Icon(Icons.check_circle, color: config.teamAccentColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamSelectionDialog(Player player) {
    // Get current team counts
    final teamCounts = <String, int>{};
    for (var entry in _playerTeamAssignments.entries) {
      final teamId = entry.value;
      teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? highlightedTeam;

          return AlertDialog(
            key: widget.teamDialogContainerKey,
            backgroundColor: config.dialogBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Select Team for ${player.name}',
              style: config.dialogTitleTextStyle,
            ),
            content: SizedBox(
              width: 400,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 0; i < config.maxTeams; i++)
                    Builder(
                      builder: (context) {
                        final teamId = 'team${i + 1}';
                        final currentPlayerTeam = _playerTeamAssignments[player.id];
                        final teamCount = teamCounts[teamId] ?? 0;
                        final isTeamFull = teamCount >= config.maxPlayersPerTeam && currentPlayerTeam != teamId;

                        return Opacity(
                          opacity: isTeamFull ? 0.4 : 1.0,
                          child: GestureDetector(
                            key: widget.teamDialogDropdownKey?.call(player.id + '_' + teamId),
                            onTap: isTeamFull ? null : () async {
                              setDialogState(() {
                                highlightedTeam = teamId;
                              });

                              setState(() {
                                _playerTeamAssignments[player.id] = teamId;
                              });
                              _notifyTeamAssignmentsChanged();

                              await Future.delayed(const Duration(milliseconds: 250));

                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: config.dialogTeamButtonSize,
                              height: config.dialogTeamButtonSize,
                              decoration: BoxDecoration(
                                color: highlightedTeam == teamId
                                    ? config.dialogHighlightGlowColor.withOpacity(0.3)
                                    : (isTeamFull
                                        ? const Color(0xFF1A1A2E)
                                        : config.dialogTeamButtonColor),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: highlightedTeam == teamId
                                      ? config.dialogHighlightGlowColor
                                      : (_playerTeamAssignments[player.id] == teamId
                                          ? config.dialogTeamButtonSelectedBorderColor
                                          : (isTeamFull
                                              ? config.dialogFullTeamColor.withOpacity(0.5)
                                              : config.dialogTeamButtonBorderColor)),
                                  width: highlightedTeam == teamId ? 4 : 3,
                                ),
                                boxShadow: highlightedTeam == teamId
                                    ? [
                                        BoxShadow(
                                          color: config.dialogHighlightGlowColor.withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Stack(
                                children: [
                                  if (i < widget.teamIconPaths.length)
                                    Image.asset(
                                      widget.teamIconPaths[i],
                                      fit: BoxFit.contain,
                                    ),
                                  if (isTeamFull)
                                    Positioned.fill(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: config.dialogFullTeamColor.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FULL',
                                            style: config.dialogFullTeamTextStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_playerTeamAssignments[player.id] != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _playerTeamAssignments.remove(player.id);
                          });
                          _notifyTeamAssignmentsChanged();
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.dialogRemoveButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Remove from Team',
                          style: config.dialogButtonTextStyle,
                        ),
                      ),
                    ),
                  if (_playerTeamAssignments[player.id] != null)
                    const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      key: widget.teamDialogCancelKey,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.dialogCancelButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: config.dialogCancelBorderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: config.dialogButtonTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamAssignmentBoxes(List<Player> selectedPlayers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < config.maxTeams; i++)
          _buildTeamBox(i, selectedPlayers),
      ],
    );
  }

  Widget _buildTeamBox(int teamIndex, List<Player> selectedPlayers) {
    final teamId = 'team${teamIndex + 1}';
    final teamPlayers = selectedPlayers
        .where((p) => _playerTeamAssignments[p.id] == teamId)
        .toList();

    return Column(
      children: [
        Container(
          width: config.teamBoxSize,
          height: config.teamBoxSize,
          decoration: BoxDecoration(
            color: config.teamBoxBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: teamPlayers.isNotEmpty
                  ? config.teamBoxActiveBorderColor
                  : config.teamBoxBorderColor,
              width: 2,
            ),
          ),
          child: teamIndex < widget.teamIconPaths.length
              ? Image.asset(
                  widget.teamIconPaths[teamIndex],
                  fit: BoxFit.contain,
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          '${teamPlayers.length}',
          style: teamPlayers.isNotEmpty
              ? config.teamBoxActiveCountStyle
              : config.teamBoxCountStyle,
        ),
      ],
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

      if (playerProvider.selectedPlayers.length < config.maxPlayers) {
        playerProvider.selectPlayer(player, maxPlayers: config.maxPlayers);
      }

      widget.onPlayerAdded?.call(player);

      _scrollToNewPlayer();
    }
  }

  void _scrollToNewPlayer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            final targetPosition = _scrollController.position.maxScrollExtent + 150;
            _scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  void _notifyTeamAssignmentsChanged() {
    widget.onTeamAssignmentsChanged?.call(Map.from(_playerTeamAssignments));
  }
}
