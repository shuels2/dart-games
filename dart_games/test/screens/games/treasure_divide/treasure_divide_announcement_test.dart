// Treasure Divide Announcement Helper Tests
// ==========================================
// Validates every announcement method: text, priority, and sound.
// Uses MockTreasureDivideAudioQueueService to capture announcements.
// Based on spec Section 9 and the orchestrator precedence design.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/game_announcement_models.dart';
import '../../../mocks/mock_treasure_divide_audio_queue_service.dart';

void main() {
  late MockTreasureDivideAudioQueueService mock;

  setUp(() {
    mock = MockTreasureDivideAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  group('Lifecycle announcements', () {
    test('Game Start — 9 rounds', () {
      mock.announceGameStart(9);
      expect(mock.announcements, ['Set sail! 9 islands to plunder!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-MapUnfurl.mp3'));
    });

    test('Game Start — 7 rounds', () {
      mock.announceGameStart(7);
      expect(mock.announcements, ['Set sail! 7 islands to plunder!']);
    });

    test('Game Start — 12 rounds', () {
      mock.announceGameStart(12);
      expect(mock.announcements, ['Set sail! 12 islands to plunder!']);
    });
  });

  // ─── Turn announcements ────────────────────────────────────────────────────

  group('Turn announcements', () {
    test('Player Turn — correct text and priority', () {
      mock.announcePlayerTurn('Alice');
      expect(mock.announcements, ['Alice, grab your darts!']);
      expect(mock.captured.first.priority, AudioPriority.turnTransition);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Bell.mp3'));
    });

    test('Crew Turn — correct text and priority', () {
      mock.announceCrewTurn('Krakens', 'Alice');
      expect(mock.announcements,
          ['The Krakens are up — Alice, grab yer darts!']);
      expect(mock.captured.first.priority, AudioPriority.turnTransition);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Bell.mp3'));
    });
  });

  // ─── Round transition precedence ──────────────────────────────────────────

  group('Round transition — Last Round wins over sentinel', () {
    test('Last Round fires regardless of target', () {
      mock.announceNewRound(
        roundIndex: 8,
        target: 25, // kTargetBull
        totalRounds: 9,
        isLastRound: true,
        customTargetsEnabled: false,
      );
      expect(mock.announcements, ['Final island! Last chance for treasure!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-MapUnfurl.mp3'));
    });

    test('Bull Round fires when isLastRound == false', () {
      mock.announceNewRound(
        roundIndex: 5,
        target: 25, // kTargetBull
        totalRounds: 9,
        isLastRound: false,
        customTargetsEnabled: false,
      );
      expect(mock.announcements, ['Treasure Island! Hit the bullseye!']);
    });

    test('Triple Round fires for kTargetAnyTriple (-2)', () {
      mock.announceNewRound(
        roundIndex: 7,
        target: -2, // kTargetAnyTriple
        totalRounds: 9,
        isLastRound: false,
        customTargetsEnabled: false,
      );
      expect(mock.announcements, ['Triple Treasure round! Hit any triple!']);
    });

    test('Double Round fires for kTargetAnyDouble (-1)', () {
      mock.announceNewRound(
        roundIndex: 3,
        target: -1, // kTargetAnyDouble
        totalRounds: 9,
        isLastRound: false,
        customTargetsEnabled: false,
      );
      expect(mock.announcements, ['Double Doubloon round! Hit any double!']);
    });

    test('Custom reveal fires when customTargetsEnabled == true', () {
      mock.announceNewRound(
        roundIndex: 1,
        target: 13,
        totalRounds: 9,
        isLastRound: false,
        customTargetsEnabled: true,
      );
      expect(mock.announcements, ['The map reveals... 13!']);
    });

    test('Standard New Round fires as fallback', () {
      mock.announceNewRound(
        roundIndex: 1, // 0-based → "Island 2"
        target: 19,
        totalRounds: 9,
        isLastRound: false,
        customTargetsEnabled: false,
      );
      expect(mock.announcements, ['Island 2: Target is 19!']);
    });

    test('Last Round with triple sentinel still fires Last Round only', () {
      // If the last round happened to be the triple round, Last Round wins.
      mock.announceNewRound(
        roundIndex: 8,
        target: -2, // kTargetAnyTriple
        totalRounds: 9,
        isLastRound: true,
        customTargetsEnabled: false,
      );
      expect(mock.announcements.length, 1);
      expect(mock.announcements.first, 'Final island! Last chance for treasure!');
    });
  });

  // ─── Per-dart precedence ───────────────────────────────────────────────────

  group('pickAndAnnounceMoment — per-dart precedence', () {
    test('Bull Hit (rank 1) — Bull sector, wasMatched', () {
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'bull',
        sector: 'Bull',
        value: 50,
      );
      expect(mock.announcements, ['X marks the spot! 50 gold!']);
      expect(mock.captured.first.priority, AudioPriority.hitConfirm);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-CoinClink.mp3'));
    });

    test('Bull Hit — outer bull (25 sector)', () {
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'single',
        sector: '25',
        value: 25,
      );
      expect(mock.announcements, ['X marks the spot! 25 gold!']);
    });

    test('Big Hit (rank 2) — triple, wasMatched', () {
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'triple',
        sector: 'T20',
        value: 60,
      );
      expect(mock.announcements, ['Triple treasure! 60 gold!']);
      expect(mock.captured.first.priority, AudioPriority.hitConfirm);
    });

    test('Hit Target (rank 3) — single hit, wasMatched', () {
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'single',
        sector: 'S20',
        value: 20,
      );
      expect(mock.announcements, ['Plunder! 20 gold coins!']);
      expect(mock.captured.first.priority, AudioPriority.hitConfirm);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-CoinClink.mp3'));
    });

    test('Hit Target (rank 3) — double hit, wasMatched', () {
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'double',
        sector: 'D20',
        value: 40,
      );
      expect(mock.announcements, ['Plunder! 40 gold coins!']);
    });

    test('Miss (rank 4) — not matched', () {
      mock.pickAndAnnounceMoment(
        wasMatched: false,
        multiplier: 'miss',
        sector: 'Miss',
        value: 0,
      );
      expect(mock.announcements, ["Splash! That one's in the ocean!"]);
      expect(mock.captured.first.priority, AudioPriority.hitConfirm);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-MissSplash.mp3'));
    });

    test('Miss — off-target single does not count as hit', () {
      mock.pickAndAnnounceMoment(
        wasMatched: false,
        multiplier: 'single',
        sector: 'S5',
        value: 0,
      );
      expect(mock.announcements, ["Splash! That one's in the ocean!"]);
    });

    test('Bull NOT counted as Bull Hit when wasMatched == false', () {
      // A "bull" sector that doesn't match the target round still fires Miss.
      mock.pickAndAnnounceMoment(
        wasMatched: false,
        multiplier: 'bull',
        sector: 'Bull',
        value: 0,
      );
      // wasMatched is false, so the bull-sector branch (rank 1) is skipped.
      expect(mock.announcements, ["Splash! That one's in the ocean!"]);
    });

    test('Triple NOT counted as Big Hit when wasMatched == false', () {
      mock.pickAndAnnounceMoment(
        wasMatched: false,
        multiplier: 'triple',
        sector: 'T20',
        value: 0,
      );
      expect(mock.announcements, ["Splash! That one's in the ocean!"]);
    });
  });

  // ─── Turn-end precedence (Solo) ────────────────────────────────────────────

  group('announceTurnEndSolo — precedence', () {
    test('Score Quartered — allMissed + quarterIt + score > 0', () {
      mock.announceTurnEndSolo(
        allMissed: true,
        quarterItEnabled: true,
        scoreBeforeTurn: 100,
      );
      expect(mock.announcements,
          ['A storm hits! Three-quarters of the treasure is lost!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Storm.mp3'));
    });

    test('Score Halved — allMissed + !quarterIt + score > 0', () {
      mock.announceTurnEndSolo(
        allMissed: true,
        quarterItEnabled: false,
        scoreBeforeTurn: 80,
      );
      expect(mock.announcements,
          ['Treasure overboard! Half the loot is gone!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Splash.mp3'));
    });

    test('Safe — at least one hit (allMissed == false)', () {
      mock.announceTurnEndSolo(
        allMissed: false,
        quarterItEnabled: false,
        scoreBeforeTurn: 60,
      );
      expect(mock.announcements, ['The treasure holds! Moving on!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-CoinClink.mp3'));
    });

    test('Safe — allMissed but score was 0 (no penalty to announce)', () {
      // Score was already 0 before the turn — halving 0 is still 0.
      // Firing "Half the loot is gone!" when there's nothing to halve is
      // confusing, so we fire Safe instead.
      mock.announceTurnEndSolo(
        allMissed: true,
        quarterItEnabled: false,
        scoreBeforeTurn: 0,
      );
      expect(mock.announcements, ['The treasure holds! Moving on!']);
    });
  });

  // ─── Turn-end precedence (Team) ───────────────────────────────────────────

  group('announceTurnEndTeam — precedence', () {
    test('Crew Wipeout — crewAllMissed + treasure > 0', () {
      mock.announceTurnEndTeam(
        crewAllMissed: true,
        crewTreasureBefore: 120,
        crewHaulThisRound: 0,
        crewName: 'Krakens',
      );
      expect(mock.announcements,
          ["All hands lost! The Krakens's treasure spills overboard!"]);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Splash.mp3'));
    });

    test('Crew Plunder — at least one hit', () {
      mock.announceTurnEndTeam(
        crewAllMissed: false,
        crewTreasureBefore: 80,
        crewHaulThisRound: 60,
        crewName: 'Anchors',
      );
      expect(mock.announcements, ['The Anchors haul in 60 gold!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
    });

    test('Crew Wipeout NOT fired if treasure was already 0', () {
      // crewAllMissed == true but crewTreasureBefore == 0 → Crew Plunder
      // (nothing to spill overboard; announcing wipeout on an empty chest is
      // misleading — haul in 0 gold is the accurate message).
      mock.announceTurnEndTeam(
        crewAllMissed: true,
        crewTreasureBefore: 0,
        crewHaulThisRound: 0,
        crewName: 'Doubloons',
      );
      expect(mock.announcements, ['The Doubloons haul in 0 gold!']);
    });
  });

  // ─── Leader change ────────────────────────────────────────────────────────

  group('Leader change', () {
    test('Solo leader announcement', () {
      mock.announceLeaderChange('Bob', 240, isTeam: false);
      expect(mock.announcements, ['Bob leads with 240 gold!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
    });

    test('Team leader announcement', () {
      mock.announceLeaderChange('Krakens', 180, isTeam: true);
      expect(mock.announcements, ['The Krakens lead with 180 gold!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
    });
  });

  // ─── Remove Darts ─────────────────────────────────────────────────────────

  group('Remove Darts', () {
    test('Unconditional remove darts — text correct, no sound', () {
      mock.announceRemoveDarts();
      expect(mock.announcements, ['Remove your darts!']);
      expect(mock.captured.first.priority, AudioPriority.statusChange);
      expect(mock.captured.first.soundAssetPath, isNull);
    });

    test('Remove your darts always plays after Bull Hit', () {
      // Simulate a Bull Hit dart event + unconditional Remove Darts.
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'bull',
        sector: 'Bull',
        value: 50,
      );
      mock.announceRemoveDarts();

      expect(mock.announcements.length, 2);
      expect(mock.announcements[0], 'X marks the spot! 50 gold!');
      expect(mock.announcements[1], 'Remove your darts!');
    });

    test('Remove your darts always plays after Quartered', () {
      // Simulate a Quarter It penalty turn-end + unconditional Remove Darts.
      mock.announceTurnEndSolo(
          allMissed: true, quarterItEnabled: true, scoreBeforeTurn: 100);
      mock.announceRemoveDarts();

      expect(mock.announcements.length, 2);
      expect(mock.announcements[0],
          'A storm hits! Three-quarters of the treasure is lost!');
      expect(mock.announcements[1], 'Remove your darts!');
    });
  });

  // ─── Victory ──────────────────────────────────────────────────────────────

  group('Victory', () {
    test('Solo Victory — correct text and priority', () {
      mock.announceVictory('Alice');
      expect(mock.announcements,
          ['Alice is crowned Pirate Captain! Richest on the seas!']);
      expect(mock.captured.first.priority, AudioPriority.victory);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Fanfare.mp3'));
    });

    test('Team Victory — correct text and priority', () {
      mock.announceTeamVictory('Krakens');
      expect(mock.announcements,
          ["The Krakens are crowned Captain's Crew! Richest on the seas!"]);
      expect(mock.captured.first.priority, AudioPriority.victory);
      expect(mock.captured.first.soundAssetPath,
          contains('TreasureDivide-Fanfare.mp3'));
    });
  });

  // ─── Stacking / max-2 constraint ─────────────────────────────────────────

  group('Stacking constraint', () {
    test(
        'max 2 announcements per single dart event (per-dart moment + Remove Darts)',
        () {
      // Simulate the worst-case dart event: a Bull Hit on the last dart of the
      // turn. Only 2 announcements should fire:
      //   1. Per-dart moment (Bull Hit)
      //   2. Remove Darts
      // No turn-end or round-transition fires ON the dart — those are
      // sequenced through the queue AFTER the takeout.
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'bull',
        sector: 'Bull',
        value: 50,
      );
      mock.announceRemoveDarts(); // called unconditionally by takeout trigger

      expect(mock.captured.length, 2,
          reason: 'Exactly 2 announcements per dart event');
      expect(mock.captured[0].text, 'X marks the spot! 50 gold!');
      expect(mock.captured[1].text, 'Remove your darts!');
    });

    test('Remove Darts is NOT suppressed by any moment priority', () {
      // Even the highest-priority per-dart moment (Bull Hit) does not suppress
      // Remove Darts.
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'bull',
        sector: 'Bull',
        value: 50,
      );
      mock.announceRemoveDarts();

      final removeDarts = mock.captured
          .where((a) => a.text == 'Remove your darts!')
          .toList();
      expect(removeDarts.length, 1,
          reason: 'Remove Darts always fires exactly once');
    });

    test('Per-dart + Remove Darts is the full budget on a dart throw', () {
      // A dart throw may produce AT MOST: 1 per-dart moment + 1 Remove Darts.
      // Turn-end, round-transition, leader-change are NOT queued here —
      // they come via handleTakeoutFinished AFTER darts are removed.
      mock.pickAndAnnounceMoment(
        wasMatched: true,
        multiplier: 'triple',
        sector: 'T20',
        value: 60,
      );
      mock.announceRemoveDarts();

      expect(mock.captured.length, 2);
    });
  });

  // ─── Dispose / whenIdle ───────────────────────────────────────────────────

  group('Dispose and whenIdle smoke tests', () {
    test('dispose clears captured announcements', () {
      mock.announceGameStart(9);
      expect(mock.captured.length, 1);
      mock.dispose();
      expect(mock.captured.length, 0);
    });

    test('whenIdle returns a completed Future', () async {
      await expectLater(mock.whenIdle(), completes);
    });
  });
}
