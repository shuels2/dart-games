/// What advancing the rotation landed on.
enum TeamRotationOutcome {
  /// Another player on the SAME team still has to play this period.
  nextPlayerSameTeam,

  /// This team is finished; play moves to the next team.
  nextTeam,

  /// Every team has played — the hole/round is over.
  periodComplete,
}

/// The result of one rotation step. Pure data; the caller applies it.
class TeamRotationStep {
  const TeamRotationStep({
    required this.outcome,
    required this.pointerForCurrentTeam,
    this.nextTeamIndex,
    this.nextTeamId,
    this.nextPlayerId,
  });

  final TeamRotationOutcome outcome;

  /// Where the current team's within-period pointer must be written back.
  /// Set on EVERY outcome, including [TeamRotationOutcome.nextTeam] — both
  /// providers advance the finished team's pointer past its last member, and
  /// dropping that write would let the team replay its final player.
  final int pointerForCurrentTeam;

  /// Only set for [TeamRotationOutcome.nextTeam].
  final int? nextTeamIndex;
  final String? nextTeamId;

  /// The player to hand the turn to. Null when the period is complete.
  final String? nextPlayerId;
}

/// The within-team-then-across-teams rotation Tiki Golf and Treasure Divide
/// both run.
///
/// WS03 §3.7. Both providers carried ~40 lines of identical pointer
/// arithmetic: bump the current team's within-period pointer; if it still
/// points inside the team, that team's next player is up; otherwise move to
/// the next team and start it at its first player; and if there is no next
/// team, the hole (Tiki) or round (TD) is over.
///
/// Only the arithmetic is shared. The SIDE EFFECTS are not, and deliberately
/// so — they are where the two games genuinely differ:
///
///   * Tiki resets `dartsThrown` for the incoming player and clears
///     `currentTurnEnded`.
///   * Treasure Divide applies crew-wide halving when a crew finishes and
///     captures the completed crew's haul for its announcements.
///
/// Folding those into a shared helper would mean one game silently running
/// the other's rules. The caller applies the step it gets back.
class RoundRobinTeamRotation {
  const RoundRobinTeamRotation._();

  /// Computes the next position. Does not mutate anything.
  ///
  /// [withinPeriodPointer] is read but never written — the caller writes
  /// [TeamRotationStep.pointerForCurrentTeam] back itself, so that the
  /// mutation stays visible at the call site.
  static TeamRotationStep advance({
    required List<String> teamIds,
    required String currentTeamId,
    required int currentTeamIndex,
    required Map<String, int> withinPeriodPointer,
    required Map<String, List<String>> teamPlayers,
  }) {
    final nextPointer = (withinPeriodPointer[currentTeamId] ?? 0) + 1;
    final members = teamPlayers[currentTeamId] ?? const <String>[];

    if (nextPointer < members.length) {
      return TeamRotationStep(
        outcome: TeamRotationOutcome.nextPlayerSameTeam,
        pointerForCurrentTeam: nextPointer,
        nextPlayerId: members[nextPointer],
      );
    }

    final nextTeamIndex = currentTeamIndex + 1;
    if (nextTeamIndex >= teamIds.length) {
      return TeamRotationStep(
        outcome: TeamRotationOutcome.periodComplete,
        pointerForCurrentTeam: nextPointer,
      );
    }

    final nextTeamId = teamIds[nextTeamIndex];
    final nextMembers = teamPlayers[nextTeamId] ?? const <String>[];
    return TeamRotationStep(
      outcome: TeamRotationOutcome.nextTeam,
      pointerForCurrentTeam: nextPointer,
      nextTeamIndex: nextTeamIndex,
      nextTeamId: nextTeamId,
      // `.first` would throw on an empty team; both games guarantee non-empty
      // crews, but returning null lets the caller fail visibly rather than
      // deep inside a rotation.
      nextPlayerId: nextMembers.isEmpty ? null : nextMembers.first,
    );
  }
}
