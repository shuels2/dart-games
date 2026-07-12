// integration_test/treasure_divide/gameplay/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide gameplay tests.
// Game-specific helpers: target retrieval, takeout sequences, etc.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(
  WidgetTester tester, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  int? teamCount,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      teamMode: teamMode,
      manualAssignment: manualAssignment,
      teamCount: teamCount,
      playerNames: playerNames,
    );

// ===== TREASURE DIVIDE-SPECIFIC HELPERS =====

/// Get the current round's target number from the provider.
int getCurrentRoundTarget(WidgetTester tester) {
  final roundIndex = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
  return ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
}

/// Throw a dart directly via provider.processDartThrow() — bypasses the mock
/// service event pipeline (which omits score/multiplier/baseScore from the
/// THROW_DETECTED payload). Use this when the test needs a non-zero hit score
/// to verify score-related behavior (halving, quarter-it, crew sums, etc.).
///
/// For sentinel targets: pass the sentinel value as [number] and set
/// [multiplier] appropriately (e.g., multiplier='double' for kTargetAnyDouble,
/// multiplier='triple' for kTargetAnyTriple, number=25 and
/// multiplier='bull' for kTargetBull).
Future<void> throwDartDirect(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  final effectiveScore = number *
      (multiplier == 'double'
          ? 2
          : multiplier == 'triple'
              ? 3
              : multiplier == 'bull'
                  ? 2
                  : 1);
  provider.processDartThrow(
    score: effectiveScore,
    multiplier: multiplier,
    baseScore: number,
    sector: multiplier == 'double'
        ? 'D$number'
        : multiplier == 'triple'
            ? 'T$number'
            : multiplier == 'bull'
                ? 'Bull'
                : 'S$number',
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

/// Throw a miss dart directly via provider.processDartThrow().
Future<void> throwMissDirect(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  provider.processDartThrow(
    score: 0,
    multiplier: 'miss',
    baseScore: 0,
    sector: 'None',
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

/// Throw the current round's target dart.
Future<void> throwTargetDart(WidgetTester tester) async {
  final target = getCurrentRoundTarget(tester);
  await throwDartViaMock(tester, target);
}

/// Throw all 3 darts as misses (wipeout). Does NOT simulate takeout.
Future<void> throwAllMissesToWipeout(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await throwMissViaMock(tester);
  }
}

/// Complete the current player's turn with a wipeout and simulate takeout.
Future<void> wipeoutAndTakeout(WidgetTester tester) async {
  await throwAllMissesToWipeout(tester);
  await clickDartsRemoved(tester);
}

/// Simulate takeout (darts removed). Checks shouldPromptTakeout first.
Future<void> simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

/// Play a complete game to winner, alternating hit/miss turns so P1 always wins.
/// Drains ALL RenderFlex overflow assertions after each turn (known TD game header bug).
Future<void> playGameToCompletion(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  int turnCount = 0;
  while (!provider.hasWinner) {
    final roundIdx = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target = ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);
    if (turnCount % 2 == 0) {
      await throwDartViaMock(tester, target);
      await throwDartViaMock(tester, target);
      await throwDartViaMock(tester, target);
    } else {
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
    }
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    turnCount++;
  }
}

/// Pump until results screen is visible (polls up to 90 s).
Future<void> pumpUntilResults(WidgetTester tester) =>
    ResultsHelpers.pumpUntilResults(tester, config);
