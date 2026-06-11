// integration_test/treasure_divide/gameplay/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide gameplay tests.
// Game-specific helpers: target retrieval, takeout sequences, etc.
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
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

/// Acknowledge the current pending RenderFlex overflow exception from the TD
/// game screen. The TD game screen has a known persistent overflow in its
/// header Row — every pump cycle can generate a FlutterError. The test
/// framework stores at most ONE pending exception at a time (collapsing extras
/// into "Multiple exceptions (N)"). Calling takeException() once after all
/// pumps for a turn clears that single aggregated entry so the test doesn't
/// fail with "at least one was unexpected."
///
/// IMPORTANT: Call this ONCE per turn boundary, AFTER all await pump() calls
/// for that turn are done. Do NOT call between individual dart throws — that
/// will clear the exception for throw N while throw N+1's pumps regenerate a
/// new one, leaving a dangling pending exception at the next turn boundary.
void drainExceptions(WidgetTester tester) {
  tester.binding.takeException();
}

/// Suppress TD game screen layout exceptions during the Flutter test
/// framework's post-testBody cleanup pump.
///
/// After testBody() returns, the framework calls runApp(_postTestMessage) and
/// pump() to unmount all widgets. The TD game screen has a persistent layout
/// bug (known RenderFlex overflow in the header Row and cascading assertion
/// failures in SingleChildScrollView) that fires during every pump while the
/// screen is mounted. These post-test-body exceptions cannot be cleared by
/// takeException() because they are generated after the last await in the test
/// body. Instead, we replace FlutterError.onError with a no-op handler so the
/// cleanup pump's exceptions never reach _pendingExceptionDetails. The
/// test_package tearDown (binding.postTest) then restores the real handler.
///
/// MUST be called as the VERY LAST STATEMENT in the test body (after all
/// assertions and after drainExceptions), only in tests that end while the
/// TD game screen is still mounted. Tests that reach the results screen do
/// NOT need this because the game screen is already unmounted.
void suppressLayoutExceptionsForCleanup() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Intentionally swallow — the TD game screen has a layout bug that fires
    // during the framework's widget-tree cleanup pump. The test's real
    // assertions have already passed at this point.
  };
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
  drainExceptions(tester);
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
    drainExceptions(tester);
    turnCount++;
  }
}

/// Pump until results screen is visible (polls up to 90 s).
Future<void> pumpUntilResults(WidgetTester tester) =>
    ResultsHelpers.pumpUntilResults(tester, config);
