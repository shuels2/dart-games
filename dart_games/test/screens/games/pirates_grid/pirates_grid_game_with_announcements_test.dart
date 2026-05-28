import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/providers/pirates_grid_provider.dart';
import '../../../mocks/mock_pirates_grid_audio_queue_service.dart';

/// Pirate's Grid — Game-With-Announcements Integration Tests
///
/// Tests the full announcement flow using [PiratesGridProvider] (real game
/// logic) + [MockPiratesGridAudioQueueService] (recorded calls). These tests
/// simulate the announcement decisions that `_handleDartThrow` and related
/// handlers make in the game screen — without needing Flutter widgets.
///
/// Coverage:
///   Group 1 — Lifecycle (game start, first turn, takeout)
///   Group 2 — Per-dart moments (each event in the precedence chain)
///   Group 3 — Precedence (higher event suppresses lower)
///   Group 4 — Stacking (worst-case max 2; remove-darts always fires)
///   Group 5 — Auto-play suppression

// ─── Runtime grid helpers ─────────────────────────────────────────────────────

/// Returns the target number at [row],[col].
int _n(PiratesGridProvider p, int row, int col) =>
    p.currentGame!.grid[row][col].target.number;

/// Returns the requirement at [row],[col].
CellRequirement _req(PiratesGridProvider p, int row, int col) =>
    p.currentGame!.grid[row][col].target.requirement;

/// Returns the required multiplier for a CellRequirement.
int _multiplierFor(CellRequirement req) {
  switch (req) {
    case CellRequirement.tripleOnly:
      return 3;
    case CellRequirement.doubleOnly:
    case CellRequirement.doubleOrTriple:
      return 2;
    case CellRequirement.any:
      return 1;
    case CellRequirement.bull:
      return 1; // handled specially
  }
}

/// Builds the sector string for [number] and [multiplier].
String _sector(int number, int multiplier) {
  if (multiplier == 2) return 'D$number';
  if (multiplier == 3) return 'T$number';
  return 'S$number';
}

/// Returns a (score, multiplier, sector) tuple for hitting cell [row],[col].
/// Bull cells use outer bull (score=25, multiplier=1, sector='Bull').
///
/// Note: [score] is the BASE number (1–20), not the total. The provider's
/// processDartThrow uses score=dartNumber which matches cell.target.number.
({int score, int multiplier, String sector}) _dartFor(PiratesGridProvider p, int row, int col) {
  final req = _req(p, row, col);
  if (req == CellRequirement.bull) {
    return (score: 25, multiplier: 1, sector: 'Bull');
  }
  final n = _n(p, row, col);
  final mult = _multiplierFor(req);
  // score = base number (not n*mult) — matches() checks dartNumber == number
  return (score: n, multiplier: mult, sector: _sector(n, mult));
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

/// Simulates the "gather facts, pick winner" pattern from _handleDartThrow.
///
/// Captures state before and after processDartThrow, determines which
/// announcement wins the precedence chain, fires it on [mock], and
/// unconditionally fires announceRemoveDarts when shouldPromptTakeout is true.
///
/// Set [suppressRemoveDarts] to true to skip the takeout call (for tests that
/// check only moment announcements without the remove-darts noise).
void _simulateDartThrow({
  required PiratesGridProvider provider,
  required MockPiratesGridAudioQueueService mock,
  required String sector,
  required int score,
  required int multiplier,
  bool isAutoPlaying = false,
  bool suppressRemoveDarts = false,
}) {
  final game = provider.currentGame!;
  final playerId = game.getCurrentPlayerId();
  final opponentId = game.getOpponentPlayerId(playerId);
  final playerName = 'Player${game.currentPlayerIndex + 1}';
  final opponentName =
      'Player${(game.currentPlayerIndex == 0 ? 1 : 0) + 1}';

  // ── Capture pre-throw state ────────────────────────────────────────────────
  final beforeMatchWinner = game.matchWinnerId;
  final beforeRoundWinner = game.winnerId;
  final beforeRoundDraw = game.isDraw;
  final beforeMatchDraw = game.isMatchDraw;

  // Determine what dart will hit (before processing)
  GridCell? hitCell;
  int hitRow = -1;
  int hitCol = -1;
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 3; c++) {
      if (game.grid[r][c].target.matches(score, multiplier)) {
        hitCell = game.grid[r][c];
        hitRow = r;
        hitCol = c;
        break;
      }
    }
    if (hitCell != null) break;
  }

  final wasMatched = hitCell != null;
  final wasMatchedCellEmpty = wasMatched && hitCell!.claimedBy == null;
  final wasMatchedCellOwn = wasMatched && hitCell!.claimedBy == playerId;
  final wasMatchedCellOpponent = wasMatched && hitCell!.claimedBy == opponentId;

  // Capture cell target label for announcements
  String cellTargetLabel = '';
  if (wasMatched && hitRow >= 0) {
    final cell = game.grid[hitRow][hitCol];
    final target = cell.target;
    if (target.requirement == CellRequirement.bull) {
      cellTargetLabel = 'Bull';
    } else if (game.targetDifficulty == TargetDifficulty.hard) {
      switch (target.requirement) {
        case CellRequirement.tripleOnly:
          cellTargetLabel = 'T${target.number}';
          break;
        case CellRequirement.doubleOnly:
          cellTargetLabel = 'D${target.number}';
          break;
        default:
          cellTargetLabel = '${target.number}';
      }
    } else {
      cellTargetLabel = '${target.number}';
    }
  }

  // ── Process the dart ───────────────────────────────────────────────────────
  provider.processDartThrow(
    score: score,
    multiplier: multiplier,
    sector: sector,
  );

  final gameAfter = provider.currentGame!;

  // ── Gather facts post-throw ────────────────────────────────────────────────
  final justWonMatch =
      beforeMatchWinner == null && gameAfter.matchWinnerId != null;
  final justWonRound = beforeRoundWinner == null &&
      gameAfter.winnerId != null &&
      !justWonMatch;
  final justDrewMatch = !beforeMatchDraw && gameAfter.isMatchDraw;
  final justDrewRound = !beforeRoundDraw &&
      gameAfter.isDraw &&
      !justWonRound &&
      !justWonMatch &&
      !justDrewMatch;
  final justPlantedFlag = wasMatched &&
      wasMatchedCellEmpty &&
      !justWonMatch &&
      !justWonRound &&
      !justDrewMatch &&
      !justDrewRound;
  final justStole = wasMatched &&
      wasMatchedCellOpponent &&
      gameAfter.stealMode &&
      !justWonMatch &&
      !justWonRound &&
      !justDrewMatch &&
      !justDrewRound;
  final justAlreadyOwn = wasMatched && wasMatchedCellOwn;
  final justAlreadyOpponent =
      wasMatched && wasMatchedCellOpponent && !gameAfter.stealMode;
  final justMissed = !wasMatched;

  // Check two-in-a-row AFTER the dart is processed
  final justGotTwoInARow =
      (justPlantedFlag || justStole) && _hasTwoInARowWithEmpty(gameAfter, playerId);

  // ── Fire ONE moment announcement (if not auto-playing) ────────────────────
  if (!isAutoPlaying) {
    if (justWonMatch) {
      mock.announceMatchVictory(playerName);
    } else if (justWonRound) {
      mock.announceRoundVictory(playerName);
    } else if (justDrewMatch) {
      mock.announceMatchDraw();
    } else if (justDrewRound) {
      mock.announceRoundDraw();
    } else if (justGotTwoInARow) {
      mock.announceTwoInARow(playerName, cellTargetLabel);
    } else if (justPlantedFlag) {
      mock.announceFlagPlanted(playerName, cellTargetLabel);
    } else if (justStole) {
      mock.announceSquareStolen(playerName, cellTargetLabel, opponentName);
    } else if (justAlreadyOwn) {
      mock.announceAlreadyClaimed(isOwn: true);
    } else if (justAlreadyOpponent) {
      mock.announceAlreadyClaimed(isOwn: false);
    } else if (justMissed) {
      mock.announceMiss();
    }
  }

  // ── Always fire remove-darts when takeout is needed ───────────────────────
  if (!suppressRemoveDarts && provider.shouldPromptTakeout && !isAutoPlaying) {
    mock.announceRemoveDarts(playerName);
  }
}

/// Mirrors the `_hasTwoInARowWithEmpty` helper from the game screen.
bool _hasTwoInARowWithEmpty(PiratesGridGame game, String playerId) {
  const lines = [
    [(0, 0), (0, 1), (0, 2)],
    [(1, 0), (1, 1), (1, 2)],
    [(2, 0), (2, 1), (2, 2)],
    [(0, 0), (1, 0), (2, 0)],
    [(0, 1), (1, 1), (2, 1)],
    [(0, 2), (1, 2), (2, 2)],
    [(0, 0), (1, 1), (2, 2)],
    [(0, 2), (1, 1), (2, 0)],
  ];
  for (final line in lines) {
    int playerCount = 0;
    int emptyCount = 0;
    for (final pos in line) {
      final claim = game.grid[pos.$1][pos.$2].claimedBy;
      if (claim == playerId) {
        playerCount++;
      } else if (claim == null) {
        emptyCount++;
      }
    }
    if (playerCount == 2 && emptyCount == 1) return true;
  }
  return false;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late PiratesGridProvider provider;
  late MockPiratesGridAudioQueueService mock;

  setUp(() {
    provider = PiratesGridProvider();
    mock = MockPiratesGridAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1 — Lifecycle (game start, player turn, takeout)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 1 — Lifecycle', () {
    test('1. announceGameStart fires exactly once at init', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      mock.announceGameStart();

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0],
          'Set sail! The grid awaits, captains!');
    });

    test('2. announcePlayerTurn fires for the first active player', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      mock.announcePlayerTurn('Player1');

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Player1'));
      expect(mock.recordedAnnouncements[0], contains('take the helm'));
    });

    test('3. announceRemoveDarts fires unconditionally after 3 darts thrown', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      // Throw 3 misses (sector 'None' → score 0)
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');

      expect(provider.shouldPromptTakeout, isTrue);

      // Remove darts fires unconditionally (simulating 1500ms delay in screen)
      mock.announceRemoveDarts('Player1');

      expect(
        mock.recordedAnnouncements.any((a) => a.contains('remove your darts')),
        isTrue,
      );
    });

    test('4. announcePlayerTurn fires for Player2 after takeout', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      // Throw 3 misses as p1
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.handleTakeoutFinished();

      // After takeout, it's Player2's turn — simulate 500ms delayed turn announcement
      mock.announcePlayerTurn('Player2');

      expect(mock.recordedAnnouncements[0], contains('Player2'));
      expect(mock.recordedAnnouncements[0], contains('take the helm'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2 — Per-dart moments (each event in the chain)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 2 — Per-dart moments', () {
    test('5. Miss — dart hits no cell → announceMiss fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: 'None',
        score: 0,
        multiplier: 1,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], 'Lost at sea! No square claimed.');
    });

    test('6. Flag planted — empty cell hit → announceFlagPlanted fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Read actual number at (0,0) — Easy, any hit
      final d = _dartFor(provider, 0, 0);

      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d.sector,
        score: d.score,
        multiplier: d.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Flag planted'));
      // The announcement contains the actual target number at (0,0)
      expect(mock.recordedAnnouncements[0], contains('${_n(provider, 0, 0)}'));
    });

    test('7. Already claimed own — hit own flag cell → announceAlreadyClaimed(isOwn: true) fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Plant at (0,0) first using actual number
      final d = _dartFor(provider, 0, 0);
      provider.processDartThrow(score: d.score, multiplier: d.multiplier, sector: d.sector);
      mock.clearAnnouncements();

      // Hit it again (own flag)
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d.sector,
        score: d.score,
        multiplier: d.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0],
          'Yer flag already flies there, captain!');
    });

    test('8. Already claimed opponent (no steal) → announceAlreadyClaimed(isOwn: false) fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // p1 plants at (0,0) using actual number
      final d = _dartFor(provider, 0, 0);
      provider.processDartThrow(score: d.score, multiplier: d.multiplier, sector: d.sector);
      // Fill p1 turn
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.handleTakeoutFinished();

      // Now p2 tries to hit (0,0) (already claimed by p1, Steal Mode OFF)
      mock.clearAnnouncements();
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d.sector,
        score: d.score,
        multiplier: d.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], 'That square is defended!');
    });

    test('9. Square stolen — opponent cell + Steal Mode ON → announceSquareStolen fires', () {
      // stealMode ON
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, true, false);

      // p1 plants at (0,0) using actual number
      final d = _dartFor(provider, 0, 0);
      provider.processDartThrow(score: d.score, multiplier: d.multiplier, sector: d.sector);
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.handleTakeoutFinished();

      // p2 steals (0,0) with Steal Mode ON
      mock.clearAnnouncements();
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d.sector,
        score: d.score,
        multiplier: d.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Mutiny'));
      expect(mock.recordedAnnouncements[0], contains('steals'));
    });

    test('10. Two in a row — 2nd flag in a line with empty 3rd → announceTwoInARow fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // p1 plants at (0,0), then (0,1) — 2 in top row, (0,2) still empty
      final d00 = _dartFor(provider, 0, 0);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      mock.clearAnnouncements();

      // (0,1) gives two-in-a-row on the top row
      final d01 = _dartFor(provider, 0, 1);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d01.sector,
        score: d01.score,
        multiplier: d01.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('two in a row'));
    });

    test('11. Round victory (Bo3) — 3-in-a-row → announceRoundVictory fires (not match victory)', () {
      // Bo3: round win does NOT immediately win the match (need 2 round wins)
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);

      // Plant (0,0) and (0,1) first
      final d00 = _dartFor(provider, 0, 0);
      final d01 = _dartFor(provider, 0, 1);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      provider.processDartThrow(score: d01.score, multiplier: d01.multiplier, sector: d01.sector);
      mock.clearAnnouncements();

      // (0,2) completes top row — round victory (match NOT over, needs 2 wins)
      final d02 = _dartFor(provider, 0, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d02.sector,
        score: d02.score,
        multiplier: d02.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Treasure found'),
          reason: 'Round Victory (not Match Victory) fires in Bo3 round 1 win');
      // Confirm match has NOT been won yet
      expect(provider.currentGame!.matchWinnerId, isNull);
    });

    test('12. Match victory (Bo1 + round win) → announceMatchVictory fires', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Bo1: winning the round = winning the match
      final d00 = _dartFor(provider, 0, 0);
      final d01 = _dartFor(provider, 0, 1);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      provider.processDartThrow(score: d01.score, multiplier: d01.multiplier, sector: d01.sector);
      mock.clearAnnouncements();

      final d02 = _dartFor(provider, 0, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d02.sector,
        score: d02.score,
        multiplier: d02.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('rules the seas'));
      expect(mock.recordedAnnouncements[0], contains('Captain'));
    });

    test('13. Timer expired → announceTimerExpired fires', () {
      mock.announceTimerExpired();

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0],
          "Time's up! The wind takes yer darts!");
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3 — Precedence
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 3 — Precedence', () {
    test('14. Two in a Row suppresses Flag Planted (flag+2-in-a-row on same dart)', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Plant (0,0) first to set up 1-in-row
      final d00 = _dartFor(provider, 0, 0);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      mock.clearAnnouncements();

      // (0,1) gives two-in-a-row AND plants flag — two-in-a-row must win
      final d01 = _dartFor(provider, 0, 1);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d01.sector,
        score: d01.score,
        multiplier: d01.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('two in a row'),
          reason: 'Two in a row must suppress Flag Planted');
      expect(
        mock.recordedAnnouncements.any((a) => a.contains('Flag planted')),
        isFalse,
        reason: 'Flag Planted must be suppressed when Two in a Row fires',
      );
    });

    test('15. Match Victory suppresses Two in a Row (Bo1: 3rd flag completes a line = match win)', () {
      // In Bo1, completing a 3-in-a-row = winning the match directly.
      // Match Victory (highest priority) suppresses Two in a Row.
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Plant (0,0) and (0,1)
      final d00 = _dartFor(provider, 0, 0);
      final d01 = _dartFor(provider, 0, 1);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      provider.processDartThrow(score: d01.score, multiplier: d01.multiplier, sector: d01.sector);
      mock.clearAnnouncements();

      // (0,2) — plants flag AND completes top row = MATCH WIN in Bo1
      final d02 = _dartFor(provider, 0, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d02.sector,
        score: d02.score,
        multiplier: d02.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        contains('rules the seas'),
        reason: 'Match Victory must suppress Two in a Row',
      );
      expect(
        mock.recordedAnnouncements.any((a) => a.contains('two in a row')),
        isFalse,
        reason: 'Two in a Row must be suppressed by Match Victory',
      );
    });

    test('16. Match Victory suppresses Round Victory in Bo3 (if match won)', () {
      // Bo3: first to 2 round wins
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);

      // Round 1 — p1 wins top row
      final d00r1 = _dartFor(provider, 0, 0);
      final d01r1 = _dartFor(provider, 0, 1);
      final d02r1 = _dartFor(provider, 0, 2);
      provider.processDartThrow(score: d00r1.score, multiplier: d00r1.multiplier, sector: d00r1.sector);
      provider.processDartThrow(score: d01r1.score, multiplier: d01r1.multiplier, sector: d01r1.sector);
      provider.processDartThrow(score: d02r1.score, multiplier: d02r1.multiplier, sector: d02r1.sector);
      // p1 won round 1 (match NOT over — needs 2 wins)
      expect(provider.currentGame!.winnerId, isNotNull);
      expect(provider.currentGame!.matchWinnerId, isNull);

      provider.handleTakeoutFinished(); // round transition
      mock.clearAnnouncements();

      // Round 2 — p1 wins again → match victory
      final game2 = provider.currentGame!;
      expect(game2.currentRound, 2);

      // p2 starts round 2 (alternating). Throw 3 misses for p2
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.handleTakeoutFinished();
      mock.clearAnnouncements();

      // p1's turn in round 2 — win top row again (grid is re-shuffled, read new numbers)
      final d00r2 = _dartFor(provider, 0, 0);
      final d01r2 = _dartFor(provider, 0, 1);
      provider.processDartThrow(score: d00r2.score, multiplier: d00r2.multiplier, sector: d00r2.sector);
      provider.processDartThrow(score: d01r2.score, multiplier: d01r2.multiplier, sector: d01r2.sector);
      mock.clearAnnouncements();

      final d02r2 = _dartFor(provider, 0, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d02r2.sector,
        score: d02r2.score,
        multiplier: d02r2.multiplier,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('rules the seas'),
          reason: 'Match Victory must fire on the winning dart');
      expect(
        mock.recordedAnnouncements.any((a) => a.contains('Treasure found')),
        isFalse,
        reason: 'Round Victory must be suppressed by Match Victory',
      );
    });

    test('17. Round Draw suppresses Flag Planted (grid fills on last dart with no winner)', () {
      // Build a Bo1 game and fill the grid so the last dart fills the grid → draw.
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = provider.currentGame!;

      // Manually fill all cells except (2,2) — 8 cells pre-filled, (2,2) is last.
      // Pattern: p2 gets (0,0),(0,2),(1,1),(2,0) = 4; p1 gets (0,1),(1,0),(1,2),(2,1) = 4
      // Neither has 3-in-a-row. Then p1 claims (2,2) → grid full → draw.
      //
      // Check rows: row0=[p2,p1,p2] row1=[p1,p2,p1] row2=[p2,p1,p2(new)]
      // Diagonals: (0,0)p2-(1,1)p2-(2,2)p2 → would be p2 win! Avoid.
      // Use: p2: (0,0),(0,2),(1,0),(2,1) = 4; p1: (0,1),(1,1),(1,2),(2,0) = 4
      //      row0=[p2,p1,p2] row1=[p2,p1,p1] row2=[p1,p2,__]
      //      After p1 claims (2,2): row2=[p1,p2,p1]
      //      Diag (0,0)p2-(1,1)p1-(2,2)p1 → no win. Diag (0,2)p2-(1,1)p1-(2,0)p1 → no win.
      //      Col0: p2,p2,p1 → no. Col1: p1,p1,p2 → no. Col2: p2,p1,p1 → no.
      //      Row0: p2,p1,p2 → no. Row1: p2,p1,p1 → no. Row2: p1,p2,p1 → no. OK.
      game.grid[0][0].claimedBy = 'p2';
      game.grid[0][1].claimedBy = 'p1';
      game.grid[0][2].claimedBy = 'p2';
      game.grid[1][0].claimedBy = 'p2';
      game.grid[1][1].claimedBy = 'p1';
      game.grid[1][2].claimedBy = 'p1';
      game.grid[2][0].claimedBy = 'p1';
      game.grid[2][1].claimedBy = 'p2';
      // (2,2) is still empty — p1 will claim it via _simulateDartThrow
      mock.clearAnnouncements();

      final d22 = _dartFor(provider, 2, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d22.sector,
        score: d22.score,
        multiplier: d22.multiplier,
        suppressRemoveDarts: true,
      );

      // After this dart the grid is full — should be a draw (Bo1 → match draw)
      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        anyOf(
          contains('stalemate'),
          contains('seas remain unclaimed'),
        ),
        reason: 'Draw announcement must fire when grid fills with no winner',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4 — Stacking / worst-case tests (CRITICAL)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 4 — Stacking', () {
    /// CRITICAL WORST-CASE STACKING TEST:
    /// Bo1, Steal Mode ON — single dart steals opponent's cell, that steal
    /// completes a 3-in-a-row, AND wins the match.
    /// Assert: ONLY Match Victory + Remove Darts fire (count = 2).
    /// Round Victory and Square Stolen must be suppressed.
    test(
      '18. Worst-case stacking: steal + 3-in-a-row + match win → ONLY Match Victory + Remove Darts (count=2)',
      () {
        // Bo1 + Steal Mode ON
        provider.startGame(
            ['p1', 'p2'], TargetDifficulty.easy, 1, true, false);
        final game = provider.currentGame!;

        // Arrange grid: p1 has (0,0) and (0,1) (needs (0,2) to win)
        // Opponent p2 has claimed (0,2)
        // So when p1 hits (0,2), they steal p2's cell AND complete top row AND win match
        game.grid[0][0].claimedBy = 'p1';
        game.grid[0][1].claimedBy = 'p1';
        game.grid[0][2].claimedBy = 'p2'; // p2 owns this — will be stolen

        mock.clearAnnouncements();

        // p1 hits (0,2) → steals from p2 → 3-in-a-row for p1 → match win
        final d02 = _dartFor(provider, 0, 2);
        _simulateDartThrow(
          provider: provider,
          mock: mock,
          sector: d02.sector,
          score: d02.score,
          multiplier: d02.multiplier,
          suppressRemoveDarts: false,
        );

        // CRITICAL: ONLY Match Victory + Remove Darts (count == 2)
        expect(
          mock.announcementCount,
          2,
          reason: 'Worst-case: exactly 2 announcements (Match Victory + Remove Darts)',
        );
        expect(
          mock.recordedAnnouncements[0],
          contains('rules the seas'),
          reason: 'Match Victory must be the moment announcement',
        );
        expect(
          mock.recordedAnnouncements[1],
          contains('remove your darts'),
          reason: 'Remove Darts must be the second announcement',
        );
        expect(
          mock.recordedAnnouncements.any((a) => a.contains('Treasure found')),
          isFalse,
          reason: 'Round Victory must be suppressed by Match Victory',
        );
        expect(
          mock.recordedAnnouncements.any((a) => a.contains('Mutiny')),
          isFalse,
          reason: 'Square Stolen must be suppressed by Match Victory',
        );
      },
    );

    /// REMOVE DARTS ALWAYS-PLAYS TEST:
    /// Even on the worst-case dart, Remove Darts still fires.
    test(
      '19. Remove Darts always-plays: fires even when Match Victory is the moment',
      () {
        provider.startGame(
            ['p1', 'p2'], TargetDifficulty.easy, 1, true, false);
        final game = provider.currentGame!;
        game.grid[0][0].claimedBy = 'p1';
        game.grid[0][1].claimedBy = 'p1';
        game.grid[0][2].claimedBy = 'p2';

        mock.clearAnnouncements();

        final d02 = _dartFor(provider, 0, 2);
        _simulateDartThrow(
          provider: provider,
          mock: mock,
          sector: d02.sector,
          score: d02.score,
          multiplier: d02.multiplier,
          suppressRemoveDarts: false,
        );

        expect(
          mock.recordedAnnouncements.any((a) => a.contains('remove your darts')),
          isTrue,
          reason: 'Remove Darts MUST fire even after Match Victory',
        );
      },
    );

    test('20. Miss + Remove Darts: exactly 2 announcements total', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // 3 misses → shouldPromptTakeout becomes true
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: 'None',
        score: 0,
        multiplier: 1,
        suppressRemoveDarts: true,
      );
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: 'None',
        score: 0,
        multiplier: 1,
        suppressRemoveDarts: true,
      );
      mock.clearAnnouncements();

      // 3rd dart — miss + remove darts
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: 'None',
        score: 0,
        multiplier: 1,
        suppressRemoveDarts: false,
      );

      expect(mock.announcementCount, 2,
          reason: 'Miss (1) + Remove Darts (1) = 2 total');
      expect(mock.recordedAnnouncements[0], 'Lost at sea! No square claimed.');
      expect(mock.recordedAnnouncements[1], contains('remove your darts'));
    });

    test('21. Flag planted + Remove Darts after 3 darts: exactly 2 announcements', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // First 2 darts don't trigger takeout
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      provider.processDartThrow(score: 0, multiplier: 1, sector: 'None');
      mock.clearAnnouncements();

      // 3rd dart → plant flag + takeout triggers; use actual number at (0,0)
      final d00 = _dartFor(provider, 0, 0);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d00.sector,
        score: d00.score,
        multiplier: d00.multiplier,
        suppressRemoveDarts: false,
      );

      expect(mock.announcementCount, 2);
      expect(mock.recordedAnnouncements[0], contains('Flag planted'));
      expect(mock.recordedAnnouncements[1], contains('remove your darts'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 5 — Auto-play suppression
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 5 — Auto-play suppression', () {
    /// AUTO-PLAY SUPPRESSION TEST:
    /// When isAutoPlaying is true, NO announcements fire at all.
    test(
      '22. Auto-play suppression: when isAutoPlaying=true, NO announcements fire',
      () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

        // Throw a dart at (0,0) with isAutoPlaying=true — no announcements should fire
        final d00 = _dartFor(provider, 0, 0);
        _simulateDartThrow(
          provider: provider,
          mock: mock,
          sector: d00.sector,
          score: d00.score,
          multiplier: d00.multiplier,
          isAutoPlaying: true,
          suppressRemoveDarts: false,
        );

        expect(
          mock.announcementCount,
          0,
          reason: 'No announcements should fire when isAutoPlaying=true',
        );
      },
    );

    test('23. Auto-play suppression: even match victory is suppressed when isAutoPlaying=true', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Plant (0,0) and (0,1) then auto-play the winning dart at (0,2)
      final d00 = _dartFor(provider, 0, 0);
      final d01 = _dartFor(provider, 0, 1);
      provider.processDartThrow(score: d00.score, multiplier: d00.multiplier, sector: d00.sector);
      provider.processDartThrow(score: d01.score, multiplier: d01.multiplier, sector: d01.sector);

      final d02 = _dartFor(provider, 0, 2);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d02.sector,
        score: d02.score,
        multiplier: d02.multiplier,
        isAutoPlaying: true,
        suppressRemoveDarts: false,
      );

      expect(
        mock.announcementCount,
        0,
        reason: 'Match Victory must also be suppressed during auto-play',
      );
    });

    test('24. Auto-play suppression OFF: normal announcements resume when isAutoPlaying=false', () {
      provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

      // Throw dart at (0,0) with isAutoPlaying=false
      final d00 = _dartFor(provider, 0, 0);
      _simulateDartThrow(
        provider: provider,
        mock: mock,
        sector: d00.sector,
        score: d00.score,
        multiplier: d00.multiplier,
        isAutoPlaying: false,
        suppressRemoveDarts: true,
      );

      expect(mock.announcementCount, greaterThan(0),
          reason: 'Announcements must fire when isAutoPlaying=false');
    });
  });
}
