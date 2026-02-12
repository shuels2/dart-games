import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';

class TeamSetupWidget extends StatefulWidget {
  final List<Player> availablePlayers;
  final Function(Map<String, List<Player>>) onTeamsChanged;

  const TeamSetupWidget({
    super.key,
    required this.availablePlayers,
    required this.onTeamsChanged,
  });

  @override
  State<TeamSetupWidget> createState() => _TeamSetupWidgetState();
}

class _TeamSetupWidgetState extends State<TeamSetupWidget> {
  // Team assignments (teamId -> list of players)
  final Map<String, List<Player>> teams = {
    'team1': [],
    'team2': [],
    'team3': [],
    'team4': [],
    'team5': [],
  };

  // Track which players are assigned
  final Set<String> assignedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final unassignedPlayers = widget.availablePlayers
        .where((p) => !assignedPlayerIds.contains(p.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Players to Teams',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Available players list
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Players',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: unassignedPlayers.isEmpty
                    ? Center(
                        child: Text(
                          'All players assigned',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: unassignedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = unassignedPlayers[index];
                          return _buildPlayerChip(player, isAssigned: false);
                        },
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Team buckets
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: teams.keys.map((teamId) {
            final teamIndex = teams.keys.toList().indexOf(teamId) + 1;
            return _buildTeamBucket(teamId, teamIndex);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTeamBucket(String teamId, int teamIndex) {
    final teamPlayers = teams[teamId]!;
    final iconPath = 'assets/games/target_tag/icons/TargetTag-TeamIcon-${teamIndex.toString().padLeft(2, '0')}.png';

    return Container(
      width: 140,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: teamPlayers.isEmpty ? Colors.white24 : const Color(0xFF00FFA3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Team icon
          Image.asset(
            iconPath,
            width: 32,
            height: 32,
          ),
          const SizedBox(height: 8),

          // Team players
          Expanded(
            child: teamPlayers.isEmpty
                ? Center(
                    child: Text(
                      'Empty',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: teamPlayers.length,
                    itemBuilder: (context, index) {
                      final player = teamPlayers[index];
                      return _buildPlayerChip(
                        player,
                        isAssigned: true,
                        teamId: teamId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerChip(Player player, {required bool isAssigned, String? teamId}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player avatar
          if (player.photoPath != null)
            CircleAvatar(
              radius: 10,
              backgroundImage: player.photoPath!.startsWith('data:')
                  ? MemoryImage(Uri.parse(player.photoPath!).data!.contentAsBytes())
                  : NetworkImage(player.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFFFF007A),
              child: Text(
                player.name[0].toUpperCase(),
                style: GoogleFonts.fredoka(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 6),

          // Player name
          Flexible(
            child: Text(
              player.name,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 4),

          // Add/Remove button
          if (isAssigned && teamId != null)
            GestureDetector(
              onTap: () => _removeFromTeam(teamId, player),
              child: const Icon(
                Icons.remove_circle,
                size: 16,
                color: Colors.red,
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.add_circle,
                size: 16,
                color: Color(0xFF00FFA3),
              ),
              iconSize: 16,
              itemBuilder: (context) => teams.keys.map((teamId) {
                final teamIndex = teams.keys.toList().indexOf(teamId) + 1;
                final teamPlayers = teams[teamId]!;
                return PopupMenuItem(
                  value: teamId,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/games/target_tag/icons/TargetTag-TeamIcon-${teamIndex.toString().padLeft(2, '0')}.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Team $teamIndex (${teamPlayers.length})'),
                    ],
                  ),
                );
              }).toList(),
              onSelected: (teamId) => _addToTeam(teamId, player),
            ),
        ],
      ),
    );
  }

  void _addToTeam(String teamId, Player player) {
    setState(() {
      teams[teamId]!.add(player);
      assignedPlayerIds.add(player.id);
      _notifyTeamsChanged();
    });
  }

  void _removeFromTeam(String teamId, Player player) {
    setState(() {
      teams[teamId]!.remove(player);
      assignedPlayerIds.remove(player.id);
      _notifyTeamsChanged();
    });
  }

  void _notifyTeamsChanged() {
    // Filter out empty teams and notify parent
    final nonEmptyTeams = <String, List<Player>>{};
    teams.forEach((teamId, players) {
      if (players.isNotEmpty) {
        nonEmptyTeams[teamId] = players;
      }
    });
    widget.onTeamsChanged(nonEmptyTeams);
  }
}
